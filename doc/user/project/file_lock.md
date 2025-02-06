---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: File Locking
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Preventing wasted work caused by unresolvable merge conflicts requires
a different way of working. This means explicitly requesting write permissions,
and verifying no one else is editing the same file before you start.

Although branching strategies typically work well enough for source code and
plain text because different versions can be merged together, they do not work
for binary files.

When file locking is setup, lockable files are **read-only** by default.

When a file is locked, only the user who locked the file may modify it. This
user is said to "hold the lock" or have "taken the lock", because only one user
can lock a file at a time. When a file or directory is unlocked, the user is
said to have "released the lock".

GitLab supports two different modes of file locking:

- [Exclusive file locks](../../topics/git/file_management.md#file-locks) for binary files: done
  **through the command line** with Git LFS and `.gitattributes`, it prevents locked
  files from being modified on any branch.
- [Default branch locks](#default-branch-file-and-directory-locks): done
  **through the GitLab UI**, it prevents locked files and directories being
  modified on the default branch.

## Permissions

Locks can be created by any person who has at least
Developer role for the repository.

Only the user who locked the file or directory can edit locked files. Other
users are prevented from modifying locked files by pushing, merging,
or any other means, and are shown an error like:
`'.gitignore' is locked by @Administrator`.

## Default branch file and directory locks

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This process allows you to lock one file at a time through the GitLab UI and
requires access to the [GitLab Premium or Ultimate tier](https://about.gitlab.com/pricing/).

Default branch file and directory locks only apply to the
[default branch](repository/branches/default.md) set in the project's settings.

Changes to locked files on the default branch are blocked, including merge
requests that modify locked files. Unlock the file to allow changes.

### Lock a file or a directory

To lock a file:

1. Open the file or directory in GitLab.
1. In the upper-right corner, above the file, select **Lock**.
1. On the confirmation dialog, select **OK**.

If you do not have permission to lock the file, the button is not enabled.

To view the user who locked a directory (if it was not you), hover over the button. Reinstatement of
similar functionality for locked files is discussed in
[issue 376222](https://gitlab.com/gitlab-org/gitlab/-/issues/376222).

### View and remove existing locks

To view and remove file locks:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Locked files**.

This list shows all the files locked either through LFS or GitLab UI.

Locks can be removed by their author, or any user
with at least the Maintainer role.

## Related topics

- [File management with Git](../../topics/git/file_management.md)
- [File locks](../../topics/git/file_management.md#file-locks)
