---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: File locking
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

File locking prevents multiple people from editing the same file simultaneously, which helps avoid
merge conflicts. File locking is especially valuable for binary files that cannot be merged like
design files, videos, and other non-text content.

GitLab supports two different types of file locking:

- [Exclusive file locks](../../topics/git/file_management.md#file-locks): Applied through the
  command line with Git LFS and `.gitattributes`.
  These locks prevent modifications to locked files on any branch.
- [Default branch file and directory locks](#default-branch-file-and-directory-locks): Applied
  through the GitLab UI. These locks prevent modifications to files and directories on the
  default branch only.

## Permissions

You can create file locks if you have at least the Developer role for the project.
For more information, see [Roles and permissions](../../user/permissions.md).

## Default branch file and directory locks

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Default branch locks apply only to the [default branch](repository/branches/default.md) set in your
project's settings. These locks help maintain stability in your default branch without blocking
collaborator workflows in other branches.

When a file or directory is locked by a user:

- Only the user who created the lock can modify the file or directory on the default branch.
- For other users, the locked file or directory is **read-only** on the default branch.
- Direct changes to locked files or directories on the default branch are blocked.
- Merge requests that modify locked files or directories cannot be merged to the default branch.

{{< alert type="note" >}}

On non-default branches, all users can still modify locked files and directories.
A **Lock** status is visible on these files and directories. This helps team members
to be aware of in-flight work without restricting their workflow on other branches.

{{< /alert >}}

## Lock a file or directory

To lock a file or directory:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file or directory you want to lock.
1. In the upper-right corner, select **Lock**.
1. On the confirmation dialog, select **OK**.

If **Lock** is not enabled, you don't have the required permissions to lock the file.

To see who locked a directory, if it wasn't you, hover over the **Lock**. For a similar function
for locked files, see [issue 4623](https://gitlab.com/gitlab-org/gitlab/-/issues/4623).

## View and remove locks

Locks can be removed by:

- The user who created the lock.
- Any user with at least the Maintainer role for the project.

To view and manage file locks:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Locked files**.

This list displays all files locked either through Git LFS exclusive locks or the GitLab UI.

## Related topics

- [File management with Git](../../topics/git/file_management.md)
- [File locks](../../topics/git/file_management.md#file-locks)
