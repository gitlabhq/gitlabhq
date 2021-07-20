---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/lfs/lfs/index.html'
---

# Git Large File Storage (LFS) **(FREE)**

Managing large files such as audio, video and graphics files has always been one
of the shortcomings of Git. The general recommendation is to not have Git repositories
larger than 1GB to preserve performance.

![Git LFS tracking status](img/lfs-icon.png)

Files tracked by Git LFS display an icon to indicate if the file is stored as a
blob or an LFS pointer.

## How it works

Git LFS client talks with the GitLab server over HTTPS. It uses HTTP Basic Authentication
to authorize client requests. After the request is authorized, Git LFS client receives
instructions from where to fetch or where to push the large file.

## GitLab server configuration

Documentation for GitLab instance administrators is under [LFS administration doc](../../../administration/lfs/index.md).

## Requirements

- Git LFS is supported in GitLab starting with version 8.2
- Git LFS must be enabled under project settings
- [Git LFS client](https://git-lfs.github.com) version 1.0.1 and up

## Known limitations

- Git LFS v1 original API is not supported, because it was deprecated early in LFS
  development.
- When SSH is set as a remote, Git LFS objects still go through HTTPS.
- Any Git LFS request asks for HTTPS credentials to be provided so a good Git
  credentials store is recommended.
- Git LFS always assumes HTTPS so if you have GitLab server on HTTP you must
  [add the URL to Git configuration manually](#troubleshooting).

NOTE:
With 8.12 GitLab added LFS support to SSH. The Git LFS communication
still goes over HTTP, but now the SSH client passes the correct credentials
to the Git LFS client. No action is required by the user.

## Using Git LFS

Lets take a look at the workflow when you need to check large files into your Git
repository with Git LFS. For example, if you want to upload a very large file and
check it into your Git repository:

```shell
git clone git@gitlab.example.com:group/project.git
git lfs install                       # initialize the Git LFS project
git lfs track "*.iso"                 # select the file extensions that you want to treat as large files
```

After you mark a file extension for tracking as a LFS object you can use
Git as usual without redoing the command to track a file with the same extension:

```shell
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git add .                             # add the large file to the project
git commit -am "Added Debian iso"     # commit the file meta data
git push origin master                # sync the git repo and large file to the GitLab server
```

**Make sure** that `.gitattributes` is tracked by Git. Otherwise Git
LFS doesn't work properly for people cloning the project:

```shell
git add .gitattributes
```

Cloning the repository works the same as before. Git automatically detects the
LFS-tracked files and clones them via HTTP. If you performed the `git clone`
command with a SSH URL, you have to enter your GitLab credentials for HTTP
authentication.

```shell
git clone git@gitlab.example.com:group/project.git
```

If you already cloned the repository and you want to get the latest LFS object
that are on the remote repository, such as for a branch from origin:

```shell
git lfs fetch origin master
```

Make sure your files aren't listed in `.gitignore`, otherwise, they are ignored by Git
and are not pushed to the remote repository.

### Migrate an existing repository to Git LFS

Read the documentation on how to [migrate an existing Git repository with Git LFS](migrate_to_git_lfs.md).

### Removing objects from LFS

To remove objects from LFS:

1. Use [`git filter-repo`](../../../user/project/repository/reducing_the_repo_size_using_git.md) to remove the objects from the repository.
1. Delete the relevant LFS lines for the objects you have removed from your `.gitattributes` file and commit those changes.

## File Locking

See the documentation on [File Locking](../../../user/project/file_lock.md).

## LFS objects in project archives

> - Support for including Git LFS blobs inside [project source downloads](../../../user/project/repository/index.md) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15079) in GitLab 13.5.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/268409) in GitLab 13.6.
> - Enabled on GitLab.com.
> - Recommended for production use.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

Prior to GitLab 13.5, [project source
downloads](../../../user/project/repository/index.md) would include Git
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

## Troubleshooting

### Encountered `n` file(s) that should have been pointers, but weren't

This error indicates the file (or files) are expected to be tracked by LFS, but for
some reason the repository is not tracking them as LFS. This issue can be one
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

1. (Optional) Clean up your `.git` folder:

   ```shell
   git reflog expire --expire-unreachable=now --all
   git gc --prune=now
   ```

### error: Repository or object not found

There are a couple of reasons why this error can occur:

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

<!-- vale gitlab.Spelling = NO -->

### getsockopt: connection refused

<!-- vale gitlab.Spelling = YES -->

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
git config --add lfs.url "http://gitlab.example.com/group/project.git/info/lfs"
```

### Credentials are always required when pushing an object

NOTE:
With 8.12 GitLab added LFS support to SSH. The Git LFS communication
still goes over HTTP, but now the SSH client passes the correct credentials
to the Git LFS client. No action is required by the user.

Git LFS authenticates the user with HTTP Basic Authentication on every push for
every object, so user HTTPS credentials are required.

By default, Git has support for remembering the credentials for each repository
you use. This is described in [Git credentials man pages](https://git-scm.com/docs/gitcredentials).

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

You might choose to do this if you are using an appliance like a <!-- vale gitlab.Spelling = NO --> Sonatype Nexus <!-- vale gitlab.Spelling = YES --> to store LFS data. If you choose to use an external LFS store,
GitLab can't verify LFS objects. Pushes then fail if you have GitLab LFS support enabled.

To stop push failure, LFS support can be disabled in the [Project settings](../../../user/project/settings/index.md), which also disables GitLab LFS value-adds (Verifying LFS objects, UI integration for LFS).
