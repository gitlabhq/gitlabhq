---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Troubleshooting Git LFS
---

When working with Git LFS, you might encounter the following issues.

- The Git LFS original v1 API is unsupported.
- Git LFS requests use HTTPS credentials, which means you should use a Git
  [credentials store](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
- [Group wikis](../../../user/project/wiki/group.md) do not support Git LFS.

## Error: repository or object not found

This error can occur for a few reasons, including:

- **You don't have permissions to access certain LFS object.** Confirm you have
  permission to push to the project, or fetch from the project.
- **The project isn't allowed to access the LFS object.** The LFS object you want
  to push (or fetch) is no longer available to the project. In most cases, the object
  has been removed from the server.
- **The local Git repository is using deprecated version of the Git LFS API.** Update
  your local copy of Git LFS and try again.

## Invalid status for `<url>` : 501

Git LFS logs the failures into a log file. To view this log file:

1. In your terminal window, go to your project's directory.
1. Run this command to see recent log files:

   ```shell
   git lfs logs last
   ```

These problems can cause `501` errors:

- Git LFS is not enabled in your project's settings. Check your project settings and
  enable Git LFS.

- Git LFS support is not enabled on the GitLab server. Check with your GitLab
  administrator why Git LFS is not enabled on the server. See
  [LFS administration documentation](../../../administration/lfs/_index.md) for instructions
  on how to enable Git LFS support.

- The Git LFS client version is not supported by GitLab server. You should:
  1. Check your Git LFS version with `git lfs version`.
  1. Check the Git configuration of your project for traces of the deprecated API
     with `git lfs -l`. If your configuration sets `batch = false`,
     remove the line, then update your Git LFS client. GitLab supports only
     versions 1.0.1 and newer.

## Credentials are always required when pushing an object

Git LFS authenticates the user with HTTP Basic Authentication on every push for
every object, so it requires user HTTPS credentials. By default, Git supports
remembering the credentials for each repository you use. For more information, see
the [official Git documentation](https://git-scm.com/docs/gitcredentials).

For example, you can tell Git to remember your password for a period of time in
which you expect to push objects. This example remembers your credentials for an hour
(3600 seconds), and you must authenticate again in an hour:

```shell
git config --global credential.helper 'cache --timeout=3600'
```

To store and encrypt credentials, see:

- MacOS: use `osxkeychain`.
- Windows: use `wincred` or the Microsoft
  [Git Credential Manager for Windows](https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases).

To learn more about storing your user credentials, see the
[Git Credential Storage documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## LFS objects are missing on push

GitLab checks files on push to detect LFS pointers. If it detects LFS pointers,
GitLab tries to verify that those files already exist in LFS. If you use a separate
server for Git LFS, and you encounter this problem:

1. Verify you have installed Git LFS locally.
1. Consider a manual push with `git lfs push --all`.

If you store Git LFS files outside of GitLab, you can
[disable Git LFS](_index.md#enable-or-disable-git-lfs-for-a-project) on your project.

## Hosting LFS objects externally

You can host LFS objects externally by setting a custom LFS URL:

```shell
git config -f .lfsconfig lfs.url https://example.com/<project>.git/info/lfs
```

You might do this if you store LFS data on an appliance, like a Nexus Repository.
If you use an external LFS store, GitLab can't verify the LFS objects. Pushes then
fail if you have GitLab LFS support enabled.

To stop push failures, you can disable Git LFS support in your
[Project settings](_index.md#enable-or-disable-git-lfs-for-a-project). However, this approach
might not be desirable, because it also disables GitLab LFS features like:

- Verifying LFS objects.
- GitLab UI integration for LFS.

## I/O timeout when pushing LFS objects

If your network conditions are unstable, the Git LFS client might time out when trying to upload files.
You might see errors like:

```shell
LFS: Put "http://example.com/root/project.git/gitlab-lfs/objects/<OBJECT-ID>/15":
read tcp your-instance-ip:54544->your-instance-ip:443: i/o timeout
error: failed to push some refs to 'ssh://example.com:2222/root/project.git'
```

To fix this problem, set the client activity timeout a higher value. For example,
to set the timeout to 60 seconds:

```shell
git config lfs.activitytimeout 60
```

## Encountered `n` files that should have been pointers, but weren't

This error indicates the repository should be tracking a file with Git LFS, but
isn't. [Issue 326342](https://gitlab.com/gitlab-org/gitlab/-/issues/326342#note_586820485),
fixed in GitLab 16.10, was one cause of this problem.

To fix the problem, migrate the affected files, and push them up to the repository:

1. Migrate the file to LFS:

   ```shell
   git lfs migrate import --yes --no-rewrite "<your-file>"
   ```

1. Push back to your repository:

   ```shell
   git push
   ```

1. Optional. Clean up your `.git` folder:

   ```shell
   git reflog expire --expire-unreachable=now --all
   git gc --prune=now
   ```
