---
type: howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrate from Subversion to GitLab **(FREE)**

GitLab uses Git as its version control system. If you're using Subversion (SVN) as your version control system,
you can migrate to using a Git repository in GitLab using `svn2git`.

You can follow the steps on this page to migrate to Git if your SVN repository:

- Has a standard format (trunk, branches, and tags).
- Is not nested.

For a non-standard repository see the [`svn2git` documentation](https://github.com/nirvdrum/svn2git).

We recommend a hard cut over from SVN to Git and GitLab. Run the migration command once and then have all users use the
new GitLab repository immediately.

## Install `svn2git`

Install `svn2git` on a local workstation rather than the GitLab server:

- On all systems you can install as a Ruby gem if you already have Ruby and Git installed:

  ```shell
  sudo gem install svn2git
  ```

- On Debian-based Linux distributions you can install the native packages:

  ```shell
  sudo apt-get install git-core git-svn ruby
  ```

## Prepare an authors file (recommended)

Prepare an authors file so `svn2git` can map SVN authors to Git authors. If you choose not to create the authors file,
commits are not attributed to the correct GitLab user.

To map authors, you must map every author present on changes in the SVN repository. If you don't, the
migration fails and you have to update the author file accordingly.

1. Search through the SVN repository and output a list of authors:

   ```shell
   svn log --quiet | grep -E "r[0-9]+ \| .+ \|" | cut -d'|' -f2 | sed 's/ //g' | sort | uniq
   ```

1. Use the output from the last command to construct the authors file. Create a file called `authors.txt` and add one
   mapping per line. For example:

   ```plaintext
   sidneyjones = Sidney Jones <sidneyjones@example.com>
   ```

## Migrate SVN repository to Git repository

`svn2git` supports excluding certain file paths, branches, tags, and more. See
the [`svn2git` documentation](https://github.com/nirvdrum/svn2git) or run `svn2git --help` for full documentation on all of
the available options.

For each repository to migrate:

1. Create a new directory and change into it.
1. For repositories that:

   - Don't require a username and password, run:

     ```shell
     svn2git https://svn.example.com/path/to/repo --authors /path/to/authors.txt
     ```

   - Do require a username and password, run:

     ```shell
     svn2git https://svn.example.com/path/to/repo --authors /path/to/authors.txt --username <username> --password <password>
     ```

1. Create a new GitLab project for your migrated code.
1. Copy the SSH or HTTP(S) repository URL from the GitLab project page.
1. Add the GitLab repository as a Git remote and push all the changes. This pushes all commits, branches, and tags.

   ```shell
   git remote add origin git@gitlab.example.com:<group>/<project>.git
   git push --all origin
   git push --tags origin
   ```
