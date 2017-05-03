# Migrating from SVN to GitLab

Subversion (SVN) is a central version control system (VCS) while
Git is a distributed version control system. There are some major differences
between the two, for more information consult your favorite search engine.

## Overview

There are two approaches to SVN to Git migration:

1. [Git/SVN Mirror](#smooth-migration-with-a-gitsvn-mirror-using-subgit) which:
    - Makes the GitLab repository to mirror the SVN project.
    - Git and SVN repositories are kept in sync; you can use either one.
    - Smoothens the migration process and allows to manage migration risks.

1. [Cut over migration](#cut-over-migration-with-svn2git) which:
     - Translates and imports the existing data and history from SVN to Git.
     - Is a fire and forget approach, good for smaller teams.

## Smooth migration with a Git/SVN mirror using SubGit

[SubGit](https://subgit.com) is a tool for a smooth, stress-free SVN to Git
migration. It creates a writable Git mirror of a local or remote Subversion
repository and that way you can use both Subversion and Git as long as you like.
It requires access to your GitLab server as it talks with the Git repositories
directly in a filesystem level.

### SubGit prerequisites

1. Install Oracle JRE 1.8 or newer. On Debian-based Linux distributions you can
   follow [this article](http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html).
1. Download SubGit from https://subgit.com/download/.
1. Unpack the downloaded SubGit zip archive to the `/opt` directory. The `subgit`
   command will be available at `/opt/subgit-VERSION/bin/subgit`.

### SubGit configuration

The first step to mirror you SVN repository in GitLab is to create a new empty
project which will be used as a mirror. For Omnibus installations the path to
the repository will be located at
`/var/opt/gitlab/git-data/repositories/USER/REPO.git` by default. For
installations from source, the default repository directory will be
`/home/git/repositories/USER/REPO.git`. For convenience, assign this path to a
variable:

```
GIT_REPO_PATH=/var/opt/gitlab/git-data/repositories/USER/REPOS.git
```

SubGit will keep this repository in sync with a remote SVN project. For
convenience, assign your remote SVN project URL to a variable:

```
SVN_PROJECT_URL=http://svn.company.com/repos/project
```

Next you need to run SubGit to set up a Git/SVN mirror. Make sure the following
`subgit` command is ran on behalf of the same user that keeps ownership of
GitLab Git repositories (by default `git`):

```
subgit configure --layout auto $SVN_PROJECT_URL $GIT_REPO_PATH
```

Adjust authors and branches mappings, if necessary. Open with your favorite
text editor:

```
edit $GIT_REPO_PATH/subgit/authors.txt
edit $GIT_REPO_PATH/subgit/config
```

For more information regarding the SubGit configuration options, refer to
[SubGit's documentation](https://subgit.com/documentation.html) website.

### Initial translation

Now that SubGit has configured the Git/SVN repos, run `subgit` to perform the
initial translation of existing SVN revisions into the Git repository:

```
subgit install $GIT_REPO_PATH
```

After the initial translation is completed, the Git repository and the SVN
project will be kept in sync by `subgit` - new Git commits will be translated to
SVN revisions and new SVN revisions will be translated to Git commits. Mirror
works transparently and does not require any special commands.

If you would prefer to perform one-time cut over migration with `subgit`, use
the `import` command instead of `install`:

```
subgit import $GIT_REPO_PATH
```

### SubGit licensing

Running SubGit in a mirror mode requires a
[registration](https://subgit.com/pricing.html). Registration is free for open
source, academic and startup projects.

We're currently working on deeper GitLab/SubGit integration. You may track our
progress at [this issue](https://gitlab.com/gitlab-org/gitlab-ee/issues/990).

### SubGit support

For any questions related to SVN to GitLab migration with SubGit, you can
contact the SubGit team directly at [support@subgit.com](mailto:support@subgit.com).

## Cut over migration with svn2git

If you are currently using an SVN repository, you can migrate the repository
to Git and GitLab. We recommend a hard cut over - run the migration command once
and then have all developers start using the new GitLab repository immediately.
Otherwise, it's hard to keep changing in sync in both directions. The conversion
process should be run on a local workstation.

Install `svn2git`. On all systems you can install as a Ruby gem if you already
have Ruby and Git installed.

```bash
sudo gem install svn2git
```

On Debian-based Linux distributions you can install the native packages:

```bash
sudo apt-get install git-core git-svn ruby
```

Optionally, prepare an authors file so `svn2git` can map SVN authors to Git authors.
If you choose not to create the authors file then commits will not be attributed
to the correct GitLab user. Some users may not consider this a big issue while
others will want to ensure they complete this step. If you choose to map authors
you will be required to map every author that is present on changes in the SVN
repository. If you don't, the conversion will fail and you will have to update
the author file accordingly. The following command will search through the
repository and output a list of authors.

```bash
svn log --quiet | grep -E "r[0-9]+ \| .+ \|" | cut -d'|' -f2 | sed 's/ //g' | sort | uniq
```

Use the output from the last command to construct the authors file.
Create a file called `authors.txt` and add one mapping per line.

```
janedoe = Jane Doe <janedoe@example.com>
johndoe = John Doe <johndoe@example.com>
```

If your SVN repository is in the standard format (trunk, branches, tags,
not nested) the conversion is simple. For a non-standard repository see
[svn2git documentation](https://github.com/nirvdrum/svn2git). The following
command will checkout the repository and do the conversion in the current
working directory. Be sure to create a new directory for each repository before
running the `svn2git` command. The conversion process will take some time.

```bash
svn2git https://svn.example.com/path/to/repo --authors /path/to/authors.txt
```

If your SVN repository requires a username and password add the
`--username <username>` and `--password <password` flags to the above command.
`svn2git` also supports excluding certain file paths, branches, tags, etc. See
[svn2git documentation](https://github.com/nirvdrum/svn2git) or run
`svn2git --help` for full documentation on all of the available options.

Create a new GitLab project, where you will eventually push your converted code.
Copy the SSH or HTTP(S) repository URL from the project page. Add the GitLab
repository as a Git remote and push all the changes. This will push all commits,
branches and tags.

```bash
git remote add origin git@gitlab.com:<group>/<project>.git
git push --all origin
git push --tags origin
```

## Contribute to this guide
We welcome all contributions that would expand this guide with instructions on
how to migrate from SVN and other version control systems.
