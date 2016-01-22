# Git annex

The biggest limitation of git compared to some older centralized version control systems has been the maximum size of the repositories.
The general recommendation is to not have git repositories larger than 1GB to preserve performance.
Although GitLab has no limit (some repositories in GitLab are over 50GB!) we subscribe to the advise to keep repositories as small as you can.

Not being able to version control large binaries is a big problem for many larger organizations.
Video, photo's, audio, compiled binaries and many other types of files are too large.
As a workaround, people keep artwork-in-progress in a Dropbox folder and only check in the final result.
This results in using outdated files, not having a complete history and the risk of losing work.

This problem is solved by integrating the awesome [git-annex](https://git-annex.branchable.com/).
Git-annex allows managing large binaries with git, without checking the contents into git.
You check in only a symlink that contains the SHA-1 of the large binary.
If you need the large binary you can sync it from the GitLab server over rsync, a very fast file copying tool.

<!-- more -->

## Using GitLab git-annex

For example, if you want to upload a very large file and check it into your Git repository:

```bash
git clone git@gitlab.example.com:group/project.git
git annex init 'My Laptop'            # initialize the annex project
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git annex add .                       # add the large file to git annex
git commit -am"Added Debian iso"      # commit the file meta data
git annex sync --content              # sync the git repo and large file to the GitLab server
```

Downloading a single large file is also very simple:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync                        # sync git branches but not the large file
git annex get debian.iso              # download the large file
```

To download all files:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync --content              # sync git branches and download all the large files
```

You don't have to setup git-annex on a separate server or add annex remotes to the repository.
Git-annex without GitLab gives everyone that can access the server access to the files of all projects.
GitLab annex ensures you can only acces files of projects you work on (developer, master or owner role).

## GitLab git-annex Configuration

### Requirements

Git-annex needs to be installed both on the server and the client side.

For Debian-like systems (eg., Debian, Ubuntu) this can be achieved by running: `sudo apt-get update && sudo apt-get install git-annex`.

For RedHat-like systems (eg., CentOS, RHEL) this can be achieved by running `sudo yum install epel-release && sudo yum install git-annex`

### Configuration

By default, git-annex is disabled in GitLab.

There are two configuration options required to enable git-annex.

### Omnibus packages

For omnibus-gitlab packages only one configuration setting is needed.
Package will internally set the correct options in all locations.

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_shell['git_annex_enabled'] = true
```

save the file and [reconfigure GitLab](administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
for the changes to take effect.

### Installations from source

There are 2 settings to enable git-annex on your GitLab server.
One is located in `config/gitlab.yml` of GitLab repository and the other one
is located in `config.yml` of gitlab-shell.

In `config/gitlab.yml`:

```yaml
gitlab_shell:
  git_annex_enabled: true
```

and in `config.yml` in gitlab-shell:

```yaml
git_annex_enabled: true
```

save the files and [restart GitLab](administration/restart_gitlab.md#installations-from-source)
for the changes to take effect.

## How it works

Internally GitLab uses [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) to handle ssh access and this was a great integration point for git-annex.
We've added a setting to GitLab Shell so you can disable GitLab Annex support if you don't want it.

You'll have to use ssh style links for to git remote to your GitLab server instead of https style links.

## Troubleshooting tips

Differences in version of `git-annex` on `GitLab` server and on local machine can cause `git-annex` to raise unpredicted warnings and errors.
Although there is no general guide for `git-annex` errors, there are a few tips on how to go arround the warnings.

### git-annex-shell: Not a git-annex or gcrypt repository.

This warning can appear on inital `git annex sync --content`. This is caused by differences in `git-annex-shell`, read more about it in [this git-annex issue](https://git-annex.branchable.com/forum/Error_from_git-annex-shell_on_creation_of_gcrypt_special_remote/).

Important thing to note is that the `sync` succeeds and the files are pushed to the GitLab repository. After this warning it is required to do:

```
git config remote.origin.annex-ignore false
```

in the repository that was pushed.

Consecutive `git annex sync --content` **should not** produce this warning and the output should look like this:

```
commit  ok
pull origin
ok
pull origin
ok
push origin
```
