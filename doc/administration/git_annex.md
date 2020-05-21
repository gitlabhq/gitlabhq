---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/git_annex.html'
---

# Git annex

> **Warning:** GitLab has [completely
removed](https://gitlab.com/gitlab-org/gitlab/-/issues/1648) in GitLab 9.0 (2017/03/22).
Read through the [migration guide from git-annex to Git LFS](../topics/git/lfs/migrate_from_git_annex_to_git_lfs.md).

The biggest limitation of Git, compared to some older centralized version
control systems has been the maximum size of the repositories.

The general recommendation is to not have Git repositories larger than 1GB to
preserve performance. Although GitLab has no limit (some repositories in GitLab
are over 50GB!), we subscribe to the advice to keep repositories as small as
you can.

Not being able to version control large binaries is a big problem for many
larger organizations.
Videos, photos, audio, compiled binaries, and many other types of files are too
large. As a workaround, people keep artwork-in-progress in a Dropbox folder and
only check in the final result. This results in using outdated files, not
having a complete history, and increases the risk of losing work.

This problem is solved in GitLab Enterprise Edition by integrating the
[git-annex](https://git-annex.branchable.com/) application.

`git-annex` allows managing large binaries with Git without checking the
contents into Git.
You check-in only a symlink that contains the SHA-1 of the large binary. If you
need the large binary, you can sync it from the GitLab server over `rsync`, a
very fast file copying tool.

## GitLab git-annex Configuration

`git-annex` is disabled by default in GitLab. Below you will find the
configuration options required to enable it.

### Requirements

`git-annex` needs to be installed both on the server and the client-side.

For Debian-like systems (for example, Debian and Ubuntu) this can be achieved by running:

```shell
sudo apt-get update && sudo apt-get install git-annex
```

For RedHat-like systems (for example, CentOS and RHEL) this can be achieved by running:

```shell
sudo yum install epel-release && sudo yum install git-annex
```

### Configuration for Omnibus packages

For Omnibus GitLab packages, only one configuration setting is needed.
The Omnibus package will internally set the correct options in all locations.

1. In `/etc/gitlab/gitlab.rb` add the following line:

   ```ruby
   gitlab_shell['git_annex_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### Configuration for installations from source

There are 2 settings to enable git-annex on your GitLab server.

One is located in `config/gitlab.yml` of the GitLab repository and the other
one is located in `config.yml` of GitLab Shell.

1. In `config/gitlab.yml` add or edit the following lines:

   ```yaml
   gitlab_shell:
     git_annex_enabled: true
   ```

1. In `config.yml` of GitLab Shell add or edit the following lines:

   ```yaml
   git_annex_enabled: true
   ```

1. Save the files and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Using GitLab git-annex

> **Note:**
> Your Git remotes must be using the SSH protocol, not HTTP(S).

Here is an example workflow of uploading a very large file and then checking it
into your Git repository:

```shell
git clone git@example.com:group/project.git

git annex init 'My Laptop'       # initialize the annex project and give an optional description
cp ~/tmp/debian.iso ./           # copy a large file into the current directory
git annex add debian.iso         # add the large file to git annex
git commit -am "Add Debian iso"  # commit the file metadata
git annex sync --content         # sync the Git repo and large file to the GitLab server
```

The output should look like this:

```plaintext
commit
On branch master
Your branch is ahead of 'origin/master' by 1 commit.
  (use "git push" to publish your local commits)
nothing to commit, working tree clean
ok
pull origin
remote: Counting objects: 5, done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 5 (delta 2), reused 0 (delta 0)
Unpacking objects: 100% (5/5), done.
From example.com:group/project
   497842b..5162f80  git-annex  -> origin/git-annex
ok
(merging origin/git-annex into git-annex...)
(recording state in git...)
copy debian.iso (checking origin...) (to origin...)
SHA256E-s26214400--8092b3d482fb1b7a5cf28c43bc1425c8f2d380e86869c0686c49aa7b0f086ab2.iso
     26,214,400 100%  638.88kB/s    0:00:40 (xfr#1, to-chk=0/1)
ok
pull origin
ok
(recording state in git...)
push origin
Counting objects: 15, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (13/13), done.
Writing objects: 100% (15/15), 1.64 KiB | 0 bytes/s, done.
Total 15 (delta 1), reused 0 (delta 0)
To example.com:group/project.git
 * [new branch]      git-annex -> synced/git-annex
 * [new branch]      master -> synced/master
ok
```

Your files can be found in the `master` branch, but you'll notice that there
are more branches created by the `annex sync` command.

Git Annex will also create a new directory at `.git/annex/` and will record the
tracked files in the `.git/config` file. The files you assign to be tracked
with `git-annex` will not affect the existing `.git/config` records. The files
are turned into symbolic links that point to data in `.git/annex/objects/`.

The `debian.iso` file in the example will contain the symbolic link:

```plaintext
.git/annex/objects/ZW/1k/SHA256E-s82701--6384039733b5035b559efd5a2e25a493ab6e09aabfd5162cc03f6f0ec238429d.png/SHA256E-s82701--6384039733b5035b559efd5a2e25a493ab6e09aabfd5162cc03f6f0ec238429d.iso
```

Use `git annex info` to retrieve the information about the local copy of your
repository.

---

Downloading a single large file is also very simple:

```shell
git clone git@gitlab.example.com:group/project.git

git annex sync             # sync Git branches but not the large file
git annex get debian.iso   # download the large file
```

To download all files:

```shell
git clone git@gitlab.example.com:group/project.git

git annex sync --content  # sync Git branches and download all the large files
```

By using `git-annex` without GitLab, anyone that can access the server can also
access the files of all projects, but GitLab Annex ensures that you can only
access files of projects you have access to (developer, maintainer, or owner role).

## How it works

Internally GitLab uses [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) to handle SSH access and this was a great
integration point for `git-annex`.
There is a setting in GitLab Shell so you can disable GitLab Annex support
if you want to.

## Troubleshooting tips

Differences in the version of `git-annex` on the GitLab server and on local machines
can cause `git-annex` to raise unpredicted warnings and errors.

Consult the [Annex upgrade page](https://git-annex.branchable.com/upgrades/) for more information about
the differences between versions. You can find out which version is installed
on your server by navigating to <https://pkgs.org/download/git-annex> and
searching for your distribution.

Although there is no general guide for `git-annex` errors, there are a few tips
on how to go around the warnings.

### `git-annex-shell: Not a git-annex or gcrypt repository`

This warning can appear on the initial `git annex sync --content` and is caused
by differences in `git-annex-shell`. You can read more about it
[in this git-annex issue](https://git-annex.branchable.com/forum/Error_from_git-annex-shell_on_creation_of_gcrypt_special_remote/).

One important thing to note is that despite the warning, the `sync` succeeds
and the files are pushed to the GitLab repository.

If you get hit by this, you can run the following command inside the repository
that the warning was raised:

```shell
git config remote.origin.annex-ignore false
```

Consecutive runs of `git annex sync --content` **should not** produce this
warning and the output should look like this:

```plaintext
commit  ok
pull origin
ok
pull origin
ok
push origin
```
