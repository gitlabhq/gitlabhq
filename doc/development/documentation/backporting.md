---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Backport documentation changes

There are two types of backports:

- **Current stable release:** Any maintainer can backport
  changes, usually bug fixes but also important documentation changes, into the
  current stable release.
- **Older stable releases:** To guarantee the
  [maintenance policy](../../policy/maintenance.md) is respected, merging to
  older stable releases is restricted to release managers.

## Backport documentation changes to older releases

Backporting documentation to older stable releases is something that should be used rarely.
The criteria includes legal issues, emergency security fixes, and fixes to content that
might prevent users from upgrading or cause data loss.

To backport changes to an older stable release
[open an issue in the Technical Writing project](https://gitlab.com/gitlab-org/technical-writing/-/issues/new)
using the [backport changes template](https://gitlab.com/gitlab-org/technical-writing/-/blob/main/.gitlab/issue_templates/backport_changes.md),
and follow the steps.
