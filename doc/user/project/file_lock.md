---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: File locking
---

File locking prevents multiple people from editing the same file simultaneously, which helps avoid
merge conflicts. File locking is especially valuable for binary files that cannot be merged like
design files, videos, and other non-text content.

GitLab supports two different types of file locking:

- Exclusive file locks: Applied through the command line with Git LFS and
  [`.gitattributes`](repository/files/git_attributes.md). These locks prevent modifications to
  locked files on any branch. Available on Free, Premium, and Ultimate tiers.
  For more information, see [Exclusive file locks](../../topics/git/file_management.md#exclusive-file-locks).
- Default branch file and directory locks: Applied through the GitLab UI. These locks prevent
  modifications to files and directories on the default branch only.

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
- For other users, the locked file or directory is read-only on the default branch.
- Direct changes to locked files or directories on the default branch are blocked.
- Merge requests that modify locked files or directories cannot be merged to the default branch.

{{< alert type="note" >}}

On non-default branches, all users can still modify locked files and directories.
A **Lock** status is visible on these files and directories. This helps team members
to be aware of in-flight work without restricting their workflow on other branches.

File locking is also bypassed during fork synchronization.
When you [update a fork](repository/forking_workflow.md#update-your-fork) from its upstream
project, locked files in the fork can be overwritten with changes from the upstream project.

{{< /alert >}}

### Permissions

You must have at least the Developer role for the project to create, view, or manage
default branch locks. For more information, see [Roles and permissions](../permissions.md).

### Lock a file or directory

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519325) in GitLab 17.10 [with a flag](../../administration/feature_flags/_index.md) named `blob_overflow_menu`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/522993) in GitLab 18.1. Feature flag `blob_overflow_menu` removed.

{{< /history >}}

The method for locking depends on whether you're locking a file or directory:

{{< tabs >}}

{{< tab title="Lock a directory" >}}

1. In the left sidebar, select **Search or go to** and find your project.
1. Go to the directory you want to lock.
1. In the upper-right corner, select **Lock**.
1. In the confirmation dialog, select **OK**.

To view the user who locked the directory, hover over the **Lock** icon.

{{< /tab >}}

{{< tab title="Lock a file" >}}

1. In the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to lock.
1. In the upper-right corner, next to the filename, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Lock**.
1. In the confirmation dialog, select **OK**.

{{< /tab >}}

{{< /tabs >}}

If the lock option is not available or is disabled, you don't have the required permissions to lock the file or directory.

### View locked files

To view locked files:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Locked files**.

The **Locked files** page displays all files locked with either Git LFS exclusive locks or the GitLab UI.

### Remove file locks

Prerequisites:

- You must either:
  - Be the user who created the lock.
  - Have at least the Maintainer role for the project.

To remove a lock:

{{< tabs >}}

{{< tab title="From a file" >}}

1. In the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to unlock.
1. Select **Unlock**.
1. On the confirmation dialog, select **Unlock**.

{{< /tab >}}

{{< tab title="From the Locked file page" >}}

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Locked files**.
1. To the right of the file you want to unlock, select **Unlock**.
1. On the confirmation dialog, select **OK**.

{{< /tab >}}

{{< /tabs >}}

To remove an exclusive file lock, see
[Lock and unlock files](../../topics/git/file_management.md#lock-and-unlock-files).

## Related topics

- [Exclusive file locks](../../topics/git/file_management.md#exclusive-file-locks)
