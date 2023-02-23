<!--
Merging into stable branches is reserved for GitLab patch releases
https://docs.gitlab.com/ee/policy/maintenance.html#patch-releases
-->

## What does this MR do and why?

_Describe in detail what merge request is being backported and why_

## MR acceptance checklist

This checklist encourages us to confirm any changes have been analyzed to reduce risks in quality, performance, reliability, security, and maintainability.

* [ ] This MR is backporting a bug fix, documentation update, or spec fix, previously merged in the default branch.
* [ ] The original MR has been deployed to GitLab.com (not applicable for documentation or spec changes).
* [ ] Ensure the `e2e:package-and-test` job has either succeeded or been approved by a Software Engineer in Test.

/assign me
