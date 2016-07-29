# Git annex

The biggest limitation of Git, compared to some older centralized version
control systems, has been the maximum size of the repositories.

The general recommendation is to not have Git repositories larger than 1GB to
preserve performance. Although GitLab has no limit (some repositories in GitLab
are over 50GB!), we subscribe to the advice to keep repositories as small as
you can.

Not being able to version control large binaries is a big problem for many
larger organizations.
Videos, photos, audio, compiled binaries and many other types of files are too
large. As a workaround, people keep artwork-in-progress in a Dropbox folder and
only check in the final result. This results in using outdated files, not
having a complete history and increases the risk of losing work.

This problem is solved in GitLab Enterprise Edition by integrating the
[git-annex] application.

`git-annex` allows managing large binaries with Git without checking the
contents into Git.
You check-in only a symlink that contains the SHA-1 of the large binary. If you
need the large binary, you can sync it from the GitLab server over `rsync`, a
very fast file copying tool.

## GitLab git-annex Configuration

`git-annex` is disabled by default in GitLab. Below you will find the
configuration options required to enable it.

### Requirements

`git-annex` needs to be installed both on the server and the client side.

For Debian-like systems (e.g., Debian, Ubuntu) this can be achieved by running:

```
sudo apt-get update && sudo apt-get install git-annex
```

For RedHat-like systems (e.g., CentOS, RHEL) this can be achieved by running:

```
sudo yum install epel-release && sudo yum install git-annex
```

### Configuration for Omnibus packages

For omnibus-gitlab packages, only one configuration setting is needed.
The Omnibus package will internally set the correct options in all locations.

1.  In `/etc/gitlab/gitlab.rb` add the following line:

    ```ruby
    gitlab_shell['git_annex_enabled'] = true
    ```

1.  Save the file and
    [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
    for the changes to take effect.

### Configuration for installations from source

There are 2 settings to enable git-annex on your GitLab server.

One is located in `config/gitlab.yml` of the GitLab repository and the other
one is located in `config.yml` of gitlab-shell.

1.  In `config/gitlab.yml` add or edit the following lines:

    ```yaml
    gitlab_shell:
      git_annex_enabled: true
    ```

1.  In `config.yml` of gitlab-shell add or edit the following lines:

    ```yaml
    git_annex_enabled: true
    ```

1.  Save the files and
    [restart GitLab](administration/restart_gitlab.md#installations-from-source)
    for the changes to take effect.

## Using GitLab git-annex

_**Important note:** Your Git remotes must be using the SSH protocol, not HTTP(S)._

Here is an example workflow of uploading a very large file and then checking it
into your Git repository:

```bash
git clone git@gitlab.example.com:group/project.git
git annex init 'My Laptop'       # initialize the annex project
cp ~/tmp/debian.iso ./           # copy a large file into the current directory
git annex add .                  # add the large file to git annex
git commit -am "Add Debian iso"  # commit the file metadata
git annex sync --content         # sync the git repo and large file to the GitLab server
```

Downloading a single large file is also very simple:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync             # sync git branches but not the large file
git annex get debian.iso   # download the large file
```

To download all files:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync --content  # sync git branches and download all the large files
```

You don't have to setup `git-annex` on a separate server or add annex remotes
to the repository.

By using `git-annex` without GitLab, anyone that can access the server can also
access the files of all projects.

GitLab annex ensures that you can only access files of projects you have access
to (developer, master, or owner role).

## How it works

Internally GitLab uses [GitLab Shell] to handle SSH access and this was a great
integration point for `git-annex`.
There is a setting in gitlab-shell so you can disable GitLab Annex support
if you want to.

_**Important note:** Your Git remotes must be using the SSH protocol, not HTTP(S)._

## Troubleshooting tips

Differences in version of `git-annex` on the GitLab server and on local machines
can cause `git-annex` to raise unpredicted warnings and errors.

Although there is no general guide for `git-annex` errors, there are a few tips
on how to go around the warnings.

### git-annex-shell: Not a git-annex or gcrypt repository.

This warning can appear on the initial `git annex sync --content` and is caused
by differences in `git-annex-shell`. You can read more about it
[in this git-annex issue][issue].

One important thing to note is that despite the warning, the `sync` succeeds
and the files are pushed to the GitLab repository.

If you get hit by this, you can run the following command inside the repository
that the warning was raised:

```
git config remote.origin.annex-ignore false
```

Consecutive runs of `git annex sync --content` **should not** produce this
warning and the output should look like this:

```
commit  ok
pull origin
ok
pull origin
ok
push origin
```

[gitlab shell]: https://gitlab.com/gitlab-org/gitlab-shell "GitLab Shell repository"
[issue]: https://git-annex.branchable.com/forum/Error_from_git-annex-shell_on_creation_of_gcrypt_special_remote/ "git-annex issue"
[git-annex]: https://git-annex.branchable.com/ "git-annex website"
