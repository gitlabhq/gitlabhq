---
type: howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrate from Subversion to GitLab **(FREE)**

GitLab uses Git as its version control system. If you're using Subversion (SVN) as your version control system,
you can migrate to using a Git repository in GitLab in two ways:

- Using SubGit to set up a temporary mirror of the SVN repository for GitLab. You can use the SVN repository and the Git
  repository at the same time, and check everything functions properly before removing access to the SVN repository and
  shutting down the mirror.
- Using `svn2git` to migrate immediately from SVN to Git. You stop using SVN, migrate the SVN repository, then
  start using the Git repository in GitLab.

## Migrate using SubGit

[SubGit](https://subgit.com) creates a writable Git mirror of a local or remote SVN repository. SubGit requires access
to your GitLab server because it accesses the Git repositories directly at the file-system level.

### SubGit prerequisites

1. Install Oracle JRE 1.8 or newer. On Debian-based Linux distributions you can
   follow [this article](http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html).
1. Download SubGit from <https://subgit.com/download>.
1. Unpack the downloaded SubGit zip archive to the `/opt` directory. The `subgit`
   command is available at `/opt/subgit-VERSION/bin/subgit`.

### SubGit configuration

The first step to mirror you SVN repository in GitLab is to create a new empty
project that is used as a mirror. For Omnibus installations the path to
the repository is
`/var/opt/gitlab/git-data/repositories/USER/REPO.git` by default. For
installations from source, the default repository directory is
`/home/git/repositories/USER/REPO.git`. For convenience, assign this path to a
variable:

```shell
GIT_REPO_PATH=/var/opt/gitlab/git-data/repositories/USER/REPOS.git
```

SubGit keeps this repository in sync with a remote SVN project. For
convenience, assign your remote SVN project URL to a variable:

```shell
SVN_PROJECT_URL=http://svn.company.com/repos/project
```

Next you need to run SubGit to set up a Git/SVN mirror. Make sure the following
`subgit` command is ran on behalf of the same user that keeps ownership of
GitLab Git repositories (by default `git`):

```shell
subgit configure --layout auto $SVN_PROJECT_URL $GIT_REPO_PATH
```

Adjust authors and branches mappings, if necessary. Open with your favorite
text editor:

```shell
edit $GIT_REPO_PATH/subgit/authors.txt
edit $GIT_REPO_PATH/subgit/config
```

For more information regarding the SubGit configuration options, refer to
[SubGit's documentation](https://subgit.com/documentation/) website.

### Initial translation

Now that SubGit has configured the Git/SVN repositories, run `subgit` to perform the
initial translation of existing SVN revisions into the Git repository:

```shell
subgit install $GIT_REPO_PATH
```

After the initial translation is completed, `subgit` keeps the Git repository and the SVN
project sync - new Git commits are translated to
SVN revisions and new SVN revisions are translated to Git commits. Mirror
works transparently and does not require any special commands.

If you would prefer to perform one-time cut over migration with `subgit`, use
the `import` command instead of `install`:

```shell
subgit import $GIT_REPO_PATH
```

### SubGit licensing

Running SubGit in a mirror mode requires a
[registration](https://subgit.com/pricing). Registration is free for open
source, academic and startup projects.

### SubGit support

For any questions related to SVN to GitLab migration with SubGit, you can
contact the SubGit team directly at [support@subgit.com](mailto:support@subgit.com).

## Migrate using `svn2git`

NOTE:
Any issues with svn2git should be directed to the [relevant project and maintainer](https://github.com/nirvdrum/svn2git).
Check for existing issues and history for update frequency.

If you are currently using an SVN repository, you can migrate the repository
to Git and GitLab. We recommend a hard cut over - run the migration command once
and then have all developers start using the new GitLab repository immediately.
Otherwise, it's hard to keep changing in sync in both directions. The conversion
process should be run on a local workstation.

Install `svn2git`. On all systems you can install as a Ruby gem if you already
have Ruby and Git installed.

```shell
sudo gem install svn2git
```

On Debian-based Linux distributions you can install the native packages:

```shell
sudo apt-get install git-core git-svn ruby
```

Optionally, prepare an authors file so `svn2git` can map SVN authors to Git authors.
If you choose not to create the authors file then commits are not attributed
to the correct GitLab user. Some users may not consider this a big issue while
others want to ensure they complete this step. If you choose to map authors,
you must map every author present on changes in the SVN
repository. If you don't, the conversion fails and you have to update
the author file accordingly. The following command searches through the
repository and output a list of authors.

```shell
svn log --quiet | grep -E "r[0-9]+ \| .+ \|" | cut -d'|' -f2 | sed 's/ //g' | sort | uniq
```

Use the output from the last command to construct the authors file.
Create a file called `authors.txt` and add one mapping per line.

```plaintext
janedoe = Jane Doe <janedoe@example.com>
johndoe = John Doe <johndoe@example.com>
```

If your SVN repository is in the standard format (trunk, branches, tags,
not nested) the conversion is simple. For a non-standard repository see
[svn2git documentation](https://github.com/nirvdrum/svn2git). The following
command will checkout the repository and do the conversion in the current
working directory. Be sure to create a new directory for each repository before
running the `svn2git` command. The conversion process takes some time.

```shell
svn2git https://svn.example.com/path/to/repo --authors /path/to/authors.txt
```

If your SVN repository requires a username and password add the
`--username <username>` and `--password <password>` flags to the above command.
`svn2git` also supports excluding certain file paths, branches, tags, and so on. See
[svn2git documentation](https://github.com/nirvdrum/svn2git) or run
`svn2git --help` for full documentation on all of the available options.

Create a new GitLab project, into which you push your converted code.
Copy the SSH or HTTP(S) repository URL from the project page. Add the GitLab
repository as a Git remote and push all the changes. This pushes all commits,
branches and tags.

```shell
git remote add origin git@gitlab.com:<group>/<project>.git
git push --all origin
git push --tags origin
```
