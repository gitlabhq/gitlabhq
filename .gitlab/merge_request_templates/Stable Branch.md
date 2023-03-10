<!--
Merging into stable branches in canonical projects is reserved for
GitLab patch releases https://docs.gitlab.com/ee/policy/maintenance.html#patch-releases

If you're backporting a security fix, please refer to the security merge request
template https://gitlab.com/gitlab-org/security/gitlab/blob/master/.gitlab/merge_request_templates/Security%20Release.md.
Security backport merge requests should not be opened on this project.
-->

## What does this MR do and why?

_Describe in detail what merge request is being backported and why_

## MR acceptance checklist

This checklist encourages us to confirm any changes have been analyzed to reduce risks in quality, performance, reliability, security, and maintainability.

* [ ] This MR is backporting a bug fix, documentation update, or spec fix, previously merged in the default branch.
* [ ] The original MR has been deployed to GitLab.com (not applicable for documentation or spec changes).
* [ ] Ensure the `e2e:package-and-test` job has either succeeded or been approved by a Software Engineer in Test.

/assign me
