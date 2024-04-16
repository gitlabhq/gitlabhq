---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Troubleshooting Git LFS

When working with Git LFS, you might encounter the following issues.

## Encountered `n` files that should have been pointers, but weren't

This error indicates the files are expected to be tracked by LFS, but
the repository is not tracking them as LFS. This issue can be one
potential reason for this error:
[Files not tracked with LFS when uploaded through the web interface](https://gitlab.com/gitlab-org/gitlab/-/issues/326342#note_586820485)

To resolve the problem, migrate the affected file (or files) and push back to the repository:

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

## error: Repository or object not found

This error can occur for a few reasons, including:

- You don't have permissions to access certain LFS object

Check if you have permissions to push to the project or fetch from the project.

- Project is not allowed to access the LFS object

LFS object you are trying to push to the project or fetch from the project is not
available to the project anymore. Probably the object was removed from the server.

- Local Git repository is using deprecated LFS API

## Invalid status for `<url>` : 501

Git LFS logs the failures into a log file.
To view this log file, while in project directory:

```shell
git lfs logs last
```

If the status `error 501` is shown, it is because:

- Git LFS is not enabled in project settings. Check your project settings and
  enable Git LFS.

- Git LFS support is not enabled on the GitLab server. Check with your GitLab
  administrator why Git LFS is not enabled on the server. See
  [LFS administration documentation](../../../administration/lfs/index.md) for instructions
  on how to enable LFS support.

- Git LFS client version is not supported by GitLab server. Check your Git LFS
  version with `git lfs version`. Check the Git configuration of the project for traces
  of deprecated API with `git lfs -l`. If `batch = false` is set in the configuration,
  remove the line and try to update your Git LFS client. Only version 1.0.1 and
  newer are supported.

## `getsockopt: connection refused`

If you push an LFS object to a project and receive an error like this,
the LFS client is trying to reach GitLab through HTTPS. However, your GitLab
instance is being served on HTTP:

```plaintext
Post <URL>/info/lfs/objects/batch: dial tcp IP: getsockopt: connection refused
```

This behavior is caused by Git LFS using HTTPS connections by default when a
`lfsurl` is not set in the Git configuration.

To prevent this from happening, set the LFS URL in project Git configuration:

```shell
git config --add lfs.url "http://gitlab.example.com/group/my-sample-project.git/info/lfs"
```

## Credentials are always required when pushing an object

NOTE:
With 8.12 GitLab added LFS support to SSH. The Git LFS communication
still goes over HTTP, but now the SSH client passes the correct credentials
to the Git LFS client. No action is required by the user.

Git LFS authenticates the user with HTTP Basic Authentication on every push for
every object, so user HTTPS credentials are required.

By default, Git has support for remembering the credentials for each repository
you use. For more information, see the [official Git documentation](https://git-scm.com/docs/gitcredentials).

For example, you can tell Git to remember the password for a period of time in
which you expect to push the objects:

```shell
git config --global credential.helper 'cache --timeout=3600'
```

This remembers the credentials for an hour, after which Git operations
require re-authentication.

If you are using OS X you can use `osxkeychain` to store and encrypt your credentials.
For Windows, you can use `wincred` or Microsoft's [Git Credential Manager for Windows](https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases).

More details about various methods of storing the user credentials can be found
on [Git Credential Storage documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## LFS objects are missing on push

GitLab checks files to detect LFS pointers on push. If LFS pointers are detected, GitLab tries to verify that those files already exist in LFS on GitLab.

Verify that LFS is installed locally and consider a manual push with `git lfs push --all`.

If you are storing LFS files outside of GitLab you can disable LFS on the project by setting `lfs_enabled: false` with the [projects API](../../../api/projects.md#edit-project).

## Hosting LFS objects externally

It is possible to host LFS objects externally by setting a custom LFS URL with `git config -f .lfsconfig lfs.url https://example.com/<project>.git/info/lfs`.

You might choose to do this if you are using an appliance like a Nexus Repository to store LFS data. If you choose to use an external LFS store,
GitLab can't verify LFS objects. Pushes then fail if you have GitLab LFS support enabled.

To stop push failure, LFS support can be disabled in the [Project settings](index.md#enable-git-lfs-for-a-project), which also disables GitLab LFS value-adds (Verifying LFS objects, UI integration for LFS).

## I/O timeout when pushing LFS objects

You might get an error that states:

```shell
LFS: Put "http://your-instance.com/root/project.git/gitlab-lfs/objects/cc29e205d04a4062d0fb131700e8bfc8e54c44d0176a8dca22f40b24ef26d325/15": read tcp your-instance-ip:54544->your-instance-ip:443: i/o timeout
error: failed to push some refs to 'ssh://your-instance.com:2222/root/project.git'
```

When network conditions are unstable, the Git LFS client might time out when trying to upload files
if network conditions are unstable.

The workaround is to set the client activity timeout a higher value.

For example, to set the timeout to 60 seconds:

```shell
git config lfs.activitytimeout 60
```
