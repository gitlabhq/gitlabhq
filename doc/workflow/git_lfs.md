# Git LFS

Managing large files such as audio, video and graphics files has always been one of the shortcomings of Git.
The general recommendation is to not have Git repositories larger than 1GB to preserve performance.

GitLab already supports [managing large files with git annex](http://doc.gitlab.com/ee/workflow/git_annex.html) (EE only), however in certain
environments it is not always convenient to use different commands to differentiate between the large files and regular ones.

Git LFS makes this simpler for the end user by removing the requirement to learn new commands
<!-- more -->

## How it works

Git LFS client talks with the GitLab server over HTTPS. It uses HTTP Basic Authentication to authorize client requests.
Once the request is authorized, Git LFS client receives instructions from where to fetch/where to push the large file.

## Requirements

* Git LFS is supported in GitLab starting with version 8.2
* Git LFS client version 0.6.0 and up

## GitLab and Git LFS

### Configuration

Git LFS objects can be large in size and they are stored on GitLab server storage.

There are two configuration options to help GitLab server administrators:

* Enabling/disabling Git LFS support
* Changing the location of LFS object storage

#### Omnibus packages

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['lfs_enabled'] = false
gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
```

#### Installations from source

In `config/gitlab.yml`:

```yaml
  lfs:
    enabled: false
    storage_path: /mnt/storage/lfs-objects
```

### Known limitations

* Git LFS v1 original API is not supported since it was deprecated early in LFS development, starting with Git LFS version 0.6.0
* When SSH is set as a remote, Git LFS objects still go through HTTPS
* Any Git LFS request will ask for HTTPS credentials to be provided so good Git credentials store is recommended
* Currently, storing GitLab Git LFS objects on a non-local storage (like S3 buckets) is not supported
* Git LFS always assumes HTTPS so if you have GitLab server on HTTP you will have to add the url to Git config manually (see #troubleshooting-tips)

## Using Git LFS

Lets take a look at the workflow when you need to check large files into your Git repository with Git LFS:
For example, if you want to upload a very large file and check it into your Git repository:

```bash
git clone git@gitlab.example.com:group/project.git
git lfs init                          # initialize the Git LFS project project
git lfs track "*.iso"                 # select the file extensions that you want to treat as large files
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git add .                             # add the large file to git annex
git commit -am "Added Debian iso"     # commit the file meta data
git push origin master                # sync the git repo and large file to the GitLab server
```

Downloading a single large file is also very simple:

```bash
git clone git@gitlab.example.com:group/project.git
git lfs fetch debian.iso              # download the large file
```


## Troubleshooting tips

### error: Repository or object not found

Few reasons why this error can occur:

1. Check the version of Git LFS on the client machine, `git lfs version`. Only version 0.6.0 and up are supported.
1. Check the Git config for traces of deprecated API, `git lfs -l`. If `batch = false` remove the line and try using Git LFS client > 0.6.0

### Invalid status for <url> : 501

When attempting to push a LFS object to a GitLab server that doesn't have Git LFS support enabled, server will return status `error 501`. Check with your GitLab administrator why Git LFS is not enabled on the server

### getsockopt: connection refused

When pushing a LFS object and you receive an error similar to: `Post <URL>/info/lfs/objects/batch: dial tcp IP: getsockopt: connection refused`,
LFS client is trying to reach GitLab through HTTPS but your GitLab is being served on HTTP.
This behaviour is caused by Git LFS using HTTPS connections by default when it doesn't have a `lfsurl` set in the Git config.

To go around this issue set the lfs url in git config:

```bash

git config --add lfs.url "http://gitlab.example.com/group/project.git/info/lfs/objects/batch"
```

### Credentials are always required when pushing an object

Given that Git LFS uses HTTP Basic Authentication to authenticate the user pushing the LFS object on every push for every object, user HTTPS credentials are required.

By default, Git has support for remembering the credentials for each repository you use. This is described in [Git credentials man pages](https://git-scm.com/docs/gitcredentials).

For example, you can tell Git to remember the password for a period of time in which you expect to push the objects:

```bash
git config --global credential.helper 'cache --timeout=3600'
```

This will remember the credentials for an hour after which Git operations will require re-authentication.

If you are using OS X you can use `osxkeychain` to store and encrypt your credentials. For Windows, `wincred` is available.

More details about various methods of storing the user credentials can be found on [Git Credential Storage documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)


