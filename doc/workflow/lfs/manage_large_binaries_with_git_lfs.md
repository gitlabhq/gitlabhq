# Git LFS

Managing large files such as audio, video and graphics files has always been one
of the shortcomings of Git. The general recommendation is to not have Git repositories
larger than 1GB to preserve performance.

GitLab already supports [managing large files with git annex](http://docs.gitlab.com/ee/workflow/git_annex.html)
(EE only), however in certain environments it is not always convenient to use
different commands to differentiate between the large files and regular ones.

Git LFS makes this simpler for the end user by removing the requirement to
learn new commands.

## How it works

Git LFS client talks with the GitLab server over HTTPS. It uses HTTP Basic Authentication
to authorize client requests. Once the request is authorized, Git LFS client receives
instructions from where to fetch or where to push the large file.

## GitLab server configuration

Documentation for GitLab instance administrators is under [LFS administration doc](lfs_administration.md).

## Requirements

* Git LFS is supported in GitLab starting with version 8.2
* [Git LFS client](https://git-lfs.github.com) version 1.0.1 and up

## Known limitations

* Git LFS v1 original API is not supported since it was deprecated early in LFS
  development
* When SSH is set as a remote, Git LFS objects still go through HTTPS
* Any Git LFS request will ask for HTTPS credentials to be provided so good Git
  credentials store is recommended
* Git LFS always assumes HTTPS so if you have GitLab server on HTTP you will have
  to add the URL to Git config manually (see #troubleshooting)
  
>**Note**: With 8.12 GitLab added LFS support to SSH. The Git LFS communication
 still goes over HTTP, but now the SSH client passes the correct credentials
 to the Git LFS client, so no action is required by the user.

## Using Git LFS

Lets take a look at the workflow when you need to check large files into your Git
repository with Git LFS. For example, if you want to upload a very large file and
check it into your Git repository:

```bash
git clone git@gitlab.example.com:group/project.git
git lfs install                       # initialize the Git LFS project project
git lfs track "*.iso"                 # select the file extensions that you want to treat as large files
```

Once a certain file extension is marked for tracking as a LFS object you can use
Git as usual without having to redo the command to track a file with the same extension:

```bash
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git add .                             # add the large file to the project
git commit -am "Added Debian iso"     # commit the file meta data
git push origin master                # sync the git repo and large file to the GitLab server
```

Cloning the repository works the same as before. Git automatically detects the
LFS-tracked files and clones them via HTTP. If you performed the git clone
command with a SSH URL, you have to enter your GitLab credentials for HTTP
authentication.

```bash
git clone git@gitlab.example.com:group/project.git
```

If you already cloned the repository and you want to get the latest LFS object
that are on the remote repository, eg. from branch `master`:

```bash
git lfs fetch master
```

## Troubleshooting

### error: Repository or object not found

There are a couple of reasons why this error can occur:

* You don't have permissions to access certain LFS object

Check if you have permissions to push to the project or fetch from the project.

* Project is not allowed to access the LFS object

LFS object you are trying to push to the project or fetch from the project is not
available to the project anymore. Probably the object was removed from the server.

* Local git repository is using deprecated LFS API

### Invalid status for <url> : 501

Git LFS will log the failures into a log file.
To view this log file, while in project directory:

```bash
git lfs logs last
```

If the status `error 501` is shown, it is because:

* Git LFS support is not enabled on the GitLab server. Check with your GitLab
  administrator why Git LFS is not enabled on the server. See
  [LFS administration documentation](lfs_administration.md) for instructions
  on how to enable LFS support.

* Git LFS client version is not supported by GitLab server. Check your Git LFS
  version with `git lfs version`. Check the Git config of the project for traces
  of deprecated API with `git lfs -l`. If `batch = false` is set in the config,
  remove the line and try to update your Git LFS client. Only version 1.0.1 and
  newer are supported.

### getsockopt: connection refused

If you push a LFS object to a project and you receive an error similar to:
`Post <URL>/info/lfs/objects/batch: dial tcp IP: getsockopt: connection refused`,
the LFS client is trying to reach GitLab through HTTPS. However, your GitLab
instance is being served on HTTP.

This behaviour is caused by Git LFS using HTTPS connections by default when a
`lfsurl` is not set in the Git config.

To prevent this from happening, set the lfs url in project Git config:

```bash

git config --add lfs.url "http://gitlab.example.com/group/project.git/info/lfs"
```

### Credentials are always required when pushing an object

>**Note**: With 8.12 GitLab added LFS support to SSH. The Git LFS communication
 still goes over HTTP, but now the SSH client passes the correct credentials
 to the Git LFS client, so no action is required by the user.

Given that Git LFS uses HTTP Basic Authentication to authenticate the user pushing
the LFS object on every push for every object, user HTTPS credentials are required.

By default, Git has support for remembering the credentials for each repository
you use. This is described in [Git credentials man pages](https://git-scm.com/docs/gitcredentials).

For example, you can tell Git to remember the password for a period of time in
which you expect to push the objects:

```bash
git config --global credential.helper 'cache --timeout=3600'
```

This will remember the credentials for an hour after which Git operations will
require re-authentication.

If you are using OS X you can use `osxkeychain` to store and encrypt your credentials.
For Windows, you can use `wincred` or Microsoft's [Git Credential Manager for Windows](https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases).

More details about various methods of storing the user credentials can be found
on [Git Credential Storage documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
