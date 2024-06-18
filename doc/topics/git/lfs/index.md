---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use Git LFS to manage binary assets, like images and video, without bloating your Git repository's size."
---

# Git Large File Storage (LFS)

Git Large File Storage (LFS) is an open source Git extension that helps Git repositories
manage large binary files efficiently. Git can't track changes to binary files
(like audio, video, or image files) the same way it tracks changes to text files.
While text-based files can generate plaintext diffs, any change to a binary file requires
Git to completely replace the file in the repository. Repeated changes to large files
increase your repository's size. Over time, this increase in size can slow down regular Git
operations like `clone`, `fetch`, or `pull`.

Use Git LFS to store large binary files outside of your Git repository, leaving only
a small, text-based pointer for Git to manage. When you add a file to your repository
using Git LFS, GitLab:

1. Adds the file to your project's configured object storage, instead of the Git repository.
1. Adds a pointer to your Git repository, instead of the large file. The pointer
   contains information about your file, like this:

   ```plaintext
   version https://git-lfs.github.com/spec/v1
   oid sha256:lpca0iva5kpz9wva5rgsqsicxrxrkbjr0bh4sy6rz08g2c4tyc441rto5j5bctit
   size 804
   ```

   - **Version** - the version of the Git LFS specification in use
   - **OID** - The hashing method used, and a unique object ID, in the form `{hash-method}:{hash}`.
   - **Size** - The file size, in bytes.

1. Queues a job to recalculate your project's statistics, including storage size and
   LFS object storage. Your LFS object storage is the sum of the size of all LFS
   objects associated with your repository.

Files managed with Git LFS show a **LFS** badge next to the filename:

![Git LFS tracking status](img/lfs_badge_v16_0.png)

Git LFS clients use HTTP Basic authentication, and communicate with your server
over HTTPS. After you authenticate the request, the Git LFS client receives instructions
on where to fetch (or push) the large file.

Your Git repository remains smaller, which helps you adhere to repository size limits.
For more information, see repository size limits
[for self-managed](../../../administration/settings/account_and_limit_settings.md#repository-size-limit) and
[for GitLab.com](../../../user/gitlab_com/index.md#account-and-limit-settings).

## Understand how Git LFS works with forks

When you fork a repository, your fork includes the upstream repository's existing LFS objects
that existed at the time of your fork. If you add new LFS objects to your fork,
they belong to only your fork, and not the upstream repository. The total object storage
increases only for your fork.

When you create a merge request from your fork back to the upstream project, and
your merge request contains a new Git LFS object, GitLab associates the new LFS object
with the _upstream_ project after merge.

## Known limitations

- The Git LFS original v1 API is unsupported.
- Git LFS requests use HTTPS credentials, which means you should use a good Git
  [credentials store](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
- [Group wikis](../../../user/project/wiki/group.md) do not support Git LFS.

## Configure Git LFS for a project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

GitLab enables Git LFS by default for both self-managed instances and GitLab.com.
It offers both server settings and project-specific settings.

- To configure Git LFS on your instance, such as setting up remote object storage, see
  [GitLab Git Large File Storage (LFS) Administration](../../../administration/lfs/index.md).
- To configure Git LFS for a specific project:

  1. In the root directory of your local copy of the repository, run `git lfs install`. This command
     adds:
     - A pre-push Git hook to your repository.
     - A [`.gitattributes` file](../../../user/project/git_attributes.md) to track
       handling for individual files and file types.
  1. Add the files and file types you want to track with Git LFS.

## Add a file with Git LFS

Prerequisites:

- You have downloaded and installed the appropriate version of the
  [CLI extension for Git LFS](https://git-lfs.com) for your operating system.
- Your project is [configured to use Git LFS](#configure-git-lfs-for-a-project).

To add a large file into your Git repository and immediately track it with Git LFS:

1. To track all files of a certain type with Git LFS, rather than a single file,
   run this command, replacing `iso` with your desired file type:

   ```shell
   git lfs track "*.iso"
   ```

   This command creates a `.gitattributes` file with instructions to handle all
   ISO files with Git LFS. The line in your `.gitattributes` file looks like this:

   ```plaintext
   *.iso filter=lfs -text
   ```

1. Add a file of that type (`.iso`) to your repository.
1. Tell Git to track the changes to both the `.gitattributes` file and the `.iso` file:

   ```shell
   git add .
   ```

1. To ensure you've added both files, run `git status`. If the `.gitattributes` file
   isn't included in your commit, users who clone your repository don't get the
   files they need.
1. Commit both files to your local copy of your repository:

   ```shell
   git commit -am "Add an ISO file and .gitattributes"
   ```

1. Push your changes back upstream, replacing `main` with the name of your branch:

   ```shell
   git push origin main
   ```

   Make sure the files you are changing aren't listed in a `.gitignore` file.
   If this file (or file type) is in your `.gitignore` file, Git commits
   the change locally, but does not push it to your upstream repository.

1. Create your merge request.

### Add a file type to Git LFS

When you add a new file type into Git LFS tracking, existing files of this type
are _not_ converted to Git LFS. Files of this type added _after_ you begin
tracking are added to Git LFS. To convert existing files of that type to
use Git LFS, use `git lfs migrate`.

Prerequisites:

- You have downloaded and installed the appropriate version of the
  [CLI extension for Git LFS](https://git-lfs.com) for your operating system.
- Your project is [configured to use Git LFS](#configure-git-lfs-for-a-project).

To start tracking a file type in Git LFS:

1. Make sure this file type isn't listed in your project's `.gitignore` file.
   If this file type is in your `.gitignore` file, Git commits your changes
   locally, but does not push it to your upstream repository.
1. Decide what file types to track with Git LFS. For each file type, run this
   command, replacing `iso` with your desired file type:

   ```shell
   git lfs track "*.iso"
   ```

1. Tell Git to track the changes to the `.gitattributes` file. Commit the
   file to your local copy of your repository, replacing `iso` with your desired file type:

   ```shell
   git add .
   git commit -am "Use Git LFS for files of type .iso"
   ```

1. Push your changes back upstream, replacing `filetype` with the name of your branch:

   ```shell
   git push origin filetype
   ```

## Stop tracking a file with Git LFS

Prerequisites:

- You have downloaded and installed the appropriate version of the
  [CLI extension for Git LFS](https://git-lfs.com) for your operating system.
- You have installed the Git LFS pre-push hook by running `git lfs install`
  in the root directory of your repository.

To stop tracking a single file in Git LFS:

1. Run the [`git lfs untrack`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-untrack.adoc)
   command and provide the path to the file:

   ```shell
   git lfs untrack doc/example.iso
   ```

1. Push your changes, create a merge request, and merge the merge request.

If you delete an object (`example.iso`) tracked by Git LFS, but don't use
the `git lfs untrack` command, `example.iso` shows as `modified` in `git status`.

### Stop tracking all files of a single type

Prerequisites:

- You have downloaded and installed the appropriate version of the
  [CLI extension for Git LFS](https://git-lfs.com) for your operating system.
- You have installed the Git LFS pre-push hook by running `git lfs install`
  in the root directory of your repository.

To stop tracking all files of a particular type in Git LFS:

1. Run the [`git lfs untrack`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-untrack.adoc)
   command and provide the file type to stop tracking:

   ```shell
   git lfs untrack "*.iso"
   ```

1. Push your changes, create a merge request, and merge the merge request.

## Enable or disable Git LFS for a project

Git LFS is enabled by default for both self-managed instances and GitLab.com.

Prerequisites:

- You must have at least the Developer role in the project.

To enable or disable Git LFS at the project level:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section.
1. Select the **Git Large File Storage (LFS)** toggle.
1. Select **Save changes**.

## Clone a repository that uses Git LFS

When you clone a repository that uses Git LFS, Git detects the LFS-tracked files
and clones them over HTTPS. If you run `git clone` with a SSH URL, like
`user@hostname.com:group/project.git`, you must enter your GitLab credentials again for HTTPS
authentication.

Even when Git communicates with your repository over SSH, Git LFS objects still use HTTPS.
Support for a wholly SSH-based protocol is proposed in [epic 11872](https://gitlab.com/groups/gitlab-org/-/epics/11872).

To fetch new LFS objects for a repository you have already cloned, run this command:

```shell
git lfs fetch origin main
```

## Migrate an existing repository to Git LFS

Read the [`git-lfs-migrate` documentation](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-migrate.adoc)
on how to migrate an existing Git repository with Git LFS.

## Related topics

- Use Git LFS to set up [exclusive file locks](../../../user/project/file_lock.md#exclusive-file-locks).
- Blog post: [Getting started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Git LFS developer information](../../../development/lfs.md)
- [GitLab Git Large File Storage (LFS) Administration](../../../administration/lfs/index.md) for self-managed instances
- [Troubleshooting Git LFS](troubleshooting.md)
- [The `.gitattributes` file](../../../user/project/git_attributes.md)

## Troubleshooting

### Reduce repository size after removing large files

If you need to remove large files from your repository's history, to reduce
the total size of your repository, see
[Reduce repository size](../../../user/project/repository/reducing_the_repo_size_using_git.md).
