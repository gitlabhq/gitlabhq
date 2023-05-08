---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference, howto
---

# Git Large File Storage (LFS) **(FREE)**

Managing large files such as audio, video and graphics files has always been one
of the shortcomings of Git. The general recommendation is to not have Git repositories
larger than 1 GB to preserve performance.

![Git LFS tracking status](img/lfs-icon.png)

Files tracked by Git LFS display an icon to indicate if the file is stored as a
blob or an LFS pointer.

## How it works

Git LFS client communicates with the GitLab server over HTTPS. It uses HTTP Basic Authentication
to authorize client requests. After the request is authorized, Git LFS client receives
instructions from where to fetch or where to push the large file.

## GitLab server configuration

Documentation for GitLab instance administrators is under [LFS administration doc](../../../administration/lfs/index.md).

## Prerequisites

- Git LFS must be [enabled in project settings](../../../user/project/settings/index.md#configure-project-visibility-features-and-permissions).
- [Git LFS client](https://git-lfs.com/) version 1.0.1 or higher must be installed.

## Known limitations

- Git LFS v1 original API is not supported, because it was deprecated early in LFS
  development.
- When SSH is set as a remote, Git LFS objects still go through HTTPS.
- Any Git LFS request asks for HTTPS credentials, so we recommend a good Git
  credentials store.
- Git LFS always assumes HTTPS so if you have GitLab server on HTTP you must
  [add the URL to Git configuration manually](#troubleshooting).
- [Group wikis](../../../user/project/wiki/group.md) do not support Git LFS.

## How LFS objects affect repository size

When you add an LFS object to a repository, GitLab:

1. Creates an LFS object.
1. Associates the LFS object with the repository.
1. Queues a job to recalculate your project's statistics, including storage size and
   LFS object storage. Your LFS object storage is the sum of the size of all LFS objects
   associated with the repository.

When your repository is forked, LFS objects from the upstream project are associated
with the fork. When the fork is created, the LFS object storage for the fork is equal
to the storage used by the upstream project. If new LFS objects are added to the fork,
the total object storage changes for the fork, but not the upstream project.

If you create a merge request from the fork back to the upstream project,
any new LFS objects in the fork become associated with the upstream project.

## Using Git LFS

Let's take a look at the workflow for checking large files into your Git
repository with Git LFS. For example, if you want to upload a very large file and
check it into your Git repository:

```shell
git clone git@gitlab.example.com:group/my-sample-project.git
cd my-sample-project
git lfs install                       # initialize the Git LFS project
git lfs track "*.iso"                 # select the file extensions that you want to treat as large files
```

After you mark a file extension for tracking as a LFS object you can use
Git as usual without redoing the command to track a file with the same extension:

```shell
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git add .                             # add the large file to the project
git commit -am "Added Debian iso"     # commit the file meta data
git push origin main                # sync the git repo and large file to the GitLab server
```

**Make sure** that `.gitattributes` is tracked by Git. Otherwise Git
LFS doesn't work properly for people cloning the project:

```shell
git add .gitattributes
git commit -am "Added .gitattributes to capture LFS tracking"
git push origin main
```

Cloning the repository works the same as before. Git automatically detects the
LFS-tracked files and clones them via HTTP. If you performed the `git clone`
command with a SSH URL, you have to enter your GitLab credentials for HTTP
authentication.

```shell
git clone git@gitlab.example.com:group/my-sample-project.git
```

If you already cloned the repository and you want to get the latest LFS object
that are on the remote repository, such as for a branch from origin:

```shell
git lfs fetch origin main
```

Make sure your files aren't listed in `.gitignore`, otherwise, they are ignored by Git
and are not pushed to the remote repository.

### Migrate an existing repository to Git LFS

Read the documentation on how to [migrate an existing Git repository with Git LFS](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-migrate.adoc).

### Removing objects from LFS

To remove objects from LFS:

1. Use [`git filter-repo`](../../../user/project/repository/reducing_the_repo_size_using_git.md) to remove the objects from the repository.
1. Delete the relevant LFS lines for the objects you have removed from your `.gitattributes` file and commit those changes.

## File Locking

See the documentation on [File Locking](../../../user/project/file_lock.md).

## LFS objects in project archives

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15079) support for including Git LFS blobs inside [project source downloads](../../../user/project/repository/index.md) in GitLab 13.5 [with a flag](../../../administration/feature_flags.md) named `include_lfs_blobs_in_archive`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46572) in GitLab 13.6.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62539) in GitLab 14.0. Feature flag `include_lfs_blobs_in_archive` removed.

Prior to GitLab 13.5, [project source downloads](../../../user/project/repository/index.md) would include Git
LFS pointers instead of the actual objects. For example, LFS pointers
look like the following:

```markdown
version https://git-lfs.github.com/spec/v1
oid sha256:3ea5dd307f195f449f0e08234183b82e92c3d5f4cff11c2a6bb014f9e0de12aa
size 177735
```

In GitLab version 13.5 and later, these pointers are converted to the uploaded
LFS object.

Technical details about how this works can be found in the [development documentation for LFS](../../../development/lfs.md#including-lfs-blobs-in-project-archives).

## Related topics

- Blog post: [Getting started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Git LFS developer information](../../../development/lfs.md)
- [GitLab Git Large File Storage (LFS) Administration](../../../administration/lfs/index.md) for self-managed instances

## Troubleshooting

### Encountered `n` files that should have been pointers, but weren't

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

### error: Repository or object not found

This error can occur for a few reasons, including:

- You don't have permissions to access certain LFS object

Check if you have permissions to push to the project or fetch from the project.

- Project is not allowed to access the LFS object

LFS object you are trying to push to the project or fetch from the project is not
available to the project anymore. Probably the object was removed from the server.

- Local Git repository is using deprecated LFS API

### Invalid status for `<url>` : 501

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

### `getsockopt: connection refused`

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

### Credentials are always required when pushing an object

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

### LFS objects are missing on push

GitLab checks files to detect LFS pointers on push. If LFS pointers are detected, GitLab tries to verify that those files already exist in LFS on GitLab.

Verify that LFS is installed locally and consider a manual push with `git lfs push --all`.

If you are storing LFS files outside of GitLab you can disable LFS on the project by setting `lfs_enabled: false` with the [projects API](../../../api/projects.md#edit-project).

### Hosting LFS objects externally

It is possible to host LFS objects externally by setting a custom LFS URL with `git config -f .lfsconfig lfs.url https://example.com/<project>.git/info/lfs`.

You might choose to do this if you are using an appliance like a Nexus Repository to store LFS data. If you choose to use an external LFS store,
GitLab can't verify LFS objects. Pushes then fail if you have GitLab LFS support enabled.

To stop push failure, LFS support can be disabled in the [Project settings](../../../user/project/settings/index.md), which also disables GitLab LFS value-adds (Verifying LFS objects, UI integration for LFS).
