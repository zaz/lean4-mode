;;; lean4-exec.el --- Lean4-Mode Executable Location  -*- lexical-binding: t; -*-

;; Copyright (c) 2024 Mekeor Melire

;; This file is not part of GNU Emacs.

;; Licensed under the Apache License, Version 2.0 (the "License"); you
;; may not use this file except in compliance with the License.  You
;; may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
;; implied.  See the License for the specific language governing
;; permissions and limitations under the License.

;;; Commentary:

;; TODO

;;; Code:

;;;; Elan

(defcustom lean4-exec-elan-base "elan"
  "Basename of Elan executable (without suffixes, if any)."
  :group 'lean4-exec
  :type 'string)

(defvar-local lean4-exec-elan-full nil
  "Full name of Elan executable.

It may be nil in which case Elan won't be used.  Otherwise it should be
a list of strings, for example:

    (\"docker\" \"compose\" \"debian\" \"exec\" \"elan\")

Member strings should not be quoted.  Consumers of this variable are
expected to quote as needed, e.g. by using `combine-and-quote-strings'
if necessary.")

(defun lean4-exec-elan-executable-find ()
  "Attempt to find Elan executable with `executable-find'."
  (declare (side-effect-free t))
  (ensure-list (executable-find lean4-exec-elan-base)))

(defcustom lean4-exec-elan-hook
  (list #'lean4-exec-elan-executable-find)
  "Hook of functions to determine `lean4-exec-elan-full'.

This hook is called from `lean4-exec-elan-init'.  Each member function
represents a certain method of determining a value suitable for
`lean4-exec-elan-full', which see.  If it does not find such a value, it
should return nil.  It should probably use `lean4-exec-elan-base' (and
maybe `executable-binary-suffixes') instead of a hard-coded basename for
the Elan executable."
  :group 'lean4-exec
  :options '(lean4-exec-elan-executable-find)
  :type 'hook)

(defun lean4-exec-elan-init ()
  "Buffer-locally set up `lean4-exec-elan-full'.

Call functions from `lean4-exec-elan-hook' until one succeeds,
i.e. returns non-nil.  `lean4-exec-elan-full' is then buffer-locally set
to this value."
  (setq-local lean4-exec-elan-full
              (run-hook-with-args-until-success
               'lean4-exec-elan-hook)))

;;;; Lake

(defcustom lean4-exec-lake-base "lake"
  "Basename of Lake executable (without suffixes, if any)."
  :group 'lean4-exec
  :type 'string)

(defvar-local lean4-exec-lake-full nil
  "Full name of Lake executable.

It may be nil in which case Lake won't be used.  Otherwise it should be
a list of strings, for example:

    (\"docker\" \"compose\" \"debian\" \"exec\" \"lake\")

Member strings should not be quoted.  Consumers of this variable are
expected to quote as needed, e.g. by using `combine-and-quote-strings'
if necessary.")

(defun lean4-exec-lake-elan-which ()
  "When `lean4-exec-elan-full', then attemp to find Lake with Elan."
  (declare (side-effect-free t))
  (when lean4-exec-elan-full
    (ignore-errors
      ;; This assumes that "elan which lake" outputs only a single
      ;; line and a final newline.  In particular it assumes that the
      ;; path to the Lake executable does not contain newlines.
      (apply #'process-lines
             (append lean4-exec-elan-full '("which" "lake"))))))

(defun lean4-exec-lake-executable-find ()
  "Attempt to find Lake executable with `executable-find'."
  (declare (side-effect-free t))
  (ensure-list (executable-find lean4-exec-lake-base)))

(defcustom lean4-exec-lake-hook
  (list
   #'lean4-exec-lake-elan-which
   #'lean4-exec-lake-executable-find)
  "Hook of functions to determine `lean4-exec-lake-full'.

This hook is called from `lean4-exec-lake-init'.  Each member function
represents a certain method of determining a value suitable for
`lean4-exec-lake-full', which see.  If it does not find such a value, it
should return nil.  It should probably use `lean4-exec-lake-base' (and
maybe `executable-binary-suffixes') instead of a hard-coded basename for
the Lake executable."
  :group 'lean4-exec
  :options '(lean4-exec-lake-executable-find)
  :type 'hook)

(defun lean4-exec-lake-init ()
  "Buffer-locally set up `lean4-exec-lake-full'.

Call functions from `lean4-exec-lake-hook' until one succeeds,
i.e. returns non-nil.  `lean4-exec-lake-full' is then buffer-locally set
to this value."
  (setq-local lean4-exec-lake-full
              (run-hook-with-args-until-success
               'lean4-exec-lake-hook)))

;;;; Lean

(defcustom lean4-exec-lean-base "lean"
  "Basename of Lean4 executable (without suffixes, if any)."
  :group 'lean4-exec
  :type 'string)

(defvar-local lean4-exec-lean-full nil
  "Full name of Lean4 executable.

It should be a list of strings, for example:

    (\"docker\" \"compose\" \"debian\" \"exec\" \"lake\" \"lean\")

Member strings should not be quoted.  Consumers of this variable are
expected to quote as needed, e.g. by using `combine-and-quote-strings'
if necessary.")

(defun lean4-exec-lean-getenv ()
  "Attempt to find Lean4 executable per `LEAN' environment variable."
  (declare (side-effect-free t))
  (ensure-list (getenv "LEAN")))

(defun lean4-exec-lean-elan-which ()
  "When `lean4-exec-elan-full', then attemp to find Lean with Elan."
  (declare (side-effect-free t))
  (when lean4-exec-elan-full
    (ignore-errors
      ;; This assumes that "elan which lean" outputs only a single
      ;; line and a final newline.  In particular it assumes that the
      ;; path to the Lean executable does not contain newlines.
      (apply #'process-lines
             (append lean4-exec-elan-full '("which" "lean"))))))

(defun lean4-exec-lean-lake ()
  "When `lean4-exec-lake-full', return `lean' as its subcommand."
  (declare (side-effect-free error-free))
  (when lean4-exec-lake-full
    (append lean4-exec-lake-full
            ;; We do not use `lean4-exec-lean-base' here because a
            ;; user could have set it to "lean4" but Lake only accepts
            ;; "lean" as subcommand.
            '("lake"))))

(defcustom lean4-exec-lean-hook
  (list
   #'lean4-exec-lean-getenv
   #'lean4-exec-lean-elan-which
   #'lean4-exec-lean-lake)
  "Hook of functions to determine `lean4-exec-lean-full'.

This hook is called from `lean4-exec-lean-init'.  Each member function
represents a certain method of determining a value suitable for
`lean4-exec-lean-full', which see.  If it does not find such a value, it
should return nil.  It should probably use `lean4-exec-lean-base' (and
maybe `executable-binary-suffixes') instead of a hard-coded basename for
the Lean4 executable."
  :group 'lean4-exec
  :options '(lean4-exec-lean-getenv
             lean4-exec-lean-elan-which
             lean4-exec-lean-lake)
  :type 'hook)

(defun lean4-exec-lean-init ()
  "Buffer-locally set up `lean4-exec-lean-full'.

Call functions from `lean4-exec-lean-hook' until one succeeds,
i.e. returns non-nil.  `lean4-exec-lean-full' is then buffer-locally set
to this value."
  (setq-local lean4-exec-lean-full
              (run-hook-with-args-until-success
               'lean4-exec-lean-hook)))

(provide 'lean4-exec)
;;; lean4-exec.el ends here
