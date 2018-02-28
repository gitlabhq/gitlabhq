---
comments: false
---

# Getting Started

----------

## Instantiating Repositories

* Create a new repository by instantiating it through
```bash
git init
```
* Copy an existing project by cloning the repository through
```bash
git clone <url>
```

----------

## Central Repos

* To instantiate a central repository a `--bare` flag is required.
* Bare repositories don't allow file editing or committing changes.
* Create a bare repo with
```bash
git init --bare project-name.git
```

----------

## Instantiate workflow with clone

1. Create a project in your user namespace
  - Choose to import from 'Any Repo by URL' and use
    https://gitlab.com/gitlab-org/training-examples.git
2. Create a '`Workspace`' directory in your home directory.
3. Clone the '`training-examples`' project

----------

## Commands

```
mkdir ~/workspace
cd ~/workspace

git clone git@gitlab.example.com:<username>/training-examples.git
cd training-examples
```
----------

## Git concepts

**Untracked files**

New files that Git has not been told to track previously.

**Working area**

Files that have been modified but are not committed.

**Staging area**

Modified files that have been marked to go in the next commit.

----------

## Committing Workflow

1. Edit '`edit_this_file.rb`' in '`training-examples`'
1. See it listed as a changed file (working area)
1. View the differences
1. Stage the file
1. Commit
1. Push the commit to the remote
1. View the git log

----------

## Commands

```
# Edit `edit_this_file.rb`
git status
git diff
git add <file>
git commit -m 'My change'
git push origin master
git log
```

----------

## Note

* git fetch vs pull
* Pull is git fetch + git merge
