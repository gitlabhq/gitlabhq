---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference, howto
---

# Git Large File Storage (LFS) **(FREE ALL)**

Managing large files such as audio, video and graphics files has always been one
of the shortcomings of Git. The general recommendation is to not have Git repositories
larger than 1 GB to preserve performance.

Your Git LFS client communicates with the GitLab server over HTTPS. It uses HTTP Basic authentication
to authorize client requests. After the request is authorized, Git LFS client receives
instructions on where to fetch or where to push the large file.

In the repository view, files tracked by Git LFS display an **LFS** badge next to the filename:

![Git LFS tracking status](img/lfs_badge_v16_0.png)

## Configure your GitLab server for Git LFS **(FREE SELF)**

To install Git LFS on your self-managed GitLab server, see
[GitLab Git Large File Storage (LFS) Administration](../../../administration/lfs/index.md).

## Enable Git LFS for a project

Prerequisites:

- You must have at least the Developer role in the project.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section.
1. Turn on the **Git Large File Storage (LFS)** toggle.
1. Select **Save changes**.

## Install the Git LFS client locally

Install the [Git LFS client](https://github.com/git-lfs/git-lfs) appropriate for
your operating system. GitLab requires version 1.0.1 or later of the Git LFS client.

## Known limitations

- Git LFS v1 original API is not supported, because it was deprecated early in LFS
  development.
- When SSH is set as a remote, Git LFS objects still go through HTTPS.
- Any Git LFS request asks for HTTPS credentials, so we recommend a good Git
  credentials store.
- Git LFS always assumes HTTPS so if you have GitLab server on HTTP you must
  [add the URL to Git configuration manually](troubleshooting.md#getsockopt-connection-refused).
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
- [Troubleshooting Git LFS](troubleshooting.md)
