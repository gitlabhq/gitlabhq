---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Use additional Git commands

You can do many Git operations directly in GitLab. However, the command line is required for advanced tasks.

## Convert a local directory into a repository

You can initialize a local folder so Git tracks it as a repository.

1. Open the terminal in the directory you'd like to convert.
1. Run this command:

   ```shell
   git init
   ```

   A `.git` folder is created in your directory. This folder contains Git
   records and configuration files. You should not edit these files
   directly.

1. Add the [path to your remote repository](#add-a-remote)
   so Git can upload your files into the correct project.

### Add a remote

You add a "remote" to tell Git which remote repository in GitLab is tied
to the specific local folder on your computer.
The remote tells Git where to push or pull from.

To add a remote to your local copy:

1. In GitLab, [create a project](../user/project/index.md) to hold your files.
1. Visit this project's homepage, scroll down to **Push an existing folder**, and copy the command that starts with `git remote add`.
1. On your computer, open the terminal in the directory you've initialized, paste the command you copied, and press <kbd>enter</kbd>:

   ```shell
   git remote add origin git@gitlab.com:username/projectpath.git
   ```

### View your remote repositories

To view your remote repositories, type:

```shell
git remote -v
```

The `-v` flag stands for verbose.

## Download the latest changes in the project

To work on an up-to-date copy of the project, you `pull` to get all the changes made by users
since the last time you cloned or pulled the project. Replace `<name-of-branch>`
with either:

- The name of your [default branch](../user/project/repository/branches/default.md) to get the main branch code.
- The name of the branch you are working in.

```shell
git pull <REMOTE> <name-of-branch>
```

When you clone a repository, `REMOTE` is typically `origin`. The remote is where the
repository was cloned from, and it indicates the SSH or HTTPS URL of the repository
on the remote server. `<name-of-branch>` is usually the name of your
[default branch](../user/project/repository/branches/default.md), but it may be any
existing branch. You can create additional named remotes and branches as necessary.

You can learn more on how Git manages remote repositories in the
[Git Remote documentation](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes).

## Add another URL to a remote

Add another URL to a remote, so both remotes get updated on each push:

```shell
git remote set-url --add <remote_name> <remote_url>
```

## Display changes to Git references

A Git **reference** is a name that points to a specific commit, or to another reference.
The reference `HEAD` is special. It usually points to a reference which points to the tip
of the current working branch:

```shell
$ git show HEAD
commit ab123c (HEAD -> main, origin/main, origin/HEAD)
```

When a reference is changed in the local repository, Git records the change
in its **reference logs**. You can display the contents of the reference logs
if you need to find the old values of a reference. For example, you might want
to display the changes to `HEAD` to undo a change.

To display the list of changes to `HEAD`:

```shell
git reflog
```

## Check the Git history of a file

The basic command to check the Git history of a file:

```shell
git log <file>
```

If you get this error message:

```plaintext
fatal: ambiguous argument <file_name>: unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
```

Use this to check the Git history of the file:

```shell
git log -- <file>
```

## Check the content of each change to a file

```shell
gitk <file>
```

## Delete changes

If want to undo your changes, you can use Git commands to go back to an earlier version of a repository.

Deleting changes is often an irreversible, destructive action. If
possible, you should add additional commits instead of reverting old
ones.

### Overwrite uncommitted changes

You can use `git checkout` as a shortcut to discard tracked,
uncommitted changes.

To discard all changes to tracked files:

```shell
git checkout .
```

Your changes are overwritten by the most recent commit in the branch.
Untracked files are not affected.

### Reset changes and commits

WARNING:
Do not reset a commit if you already pushed it to the remote
repository.

If you stage a change with `git add` and then decide not to commit it,
you might want to unstage the changes. To unstage a change:

- From your repository, run `git reset`.

If your changes have been committed (but not pushed to the remote
repository), you can reset your commits:

```shell
git reset HEAD~<number>
```

Here, `<number>` is the number of commits to undo.
For example, if you want to undo only the latest commit:

```shell
git rest HEAD~1
```

The commit is reset and any changes remain in the local repository.

To learn more about the different ways to undo changes, see the
[Git Undoing Things documentation](https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things).

## Merge a branch with default branch

When you are ready to add your changes to
the default branch, you merge the feature branch into it:

```shell
git checkout <default-branch>
git merge <feature-branch>
```

In GitLab, you typically use a [merge request](../user/project/merge_requests/index.md) to merge your changes, instead of using the command line.

To create a merge request from a fork to an upstream repository, see the
[forking workflow](../user/project/repository/forking_workflow.md).

## Synchronize changes in a forked repository with the upstream

To create a copy of a repository in your namespace, you [fork it](../user/project/repository/forking_workflow.md).
Changes made to your copy of the repository are not automatically synchronized with the original.
To keep the project in sync with the original project, you need to `pull` from the original repository.

You must [create a link to the remote repository](#add-a-remote) to pull
changes from the original repository. It is common to call this remote repository the `upstream`.

You can now use the `upstream` as a [`<remote>` to `pull` new updates](#download-the-latest-changes-in-the-project)
from the original repository, and use the `origin`
to [push local changes](add-file.md#send-changes-to-gitlab) and create merge requests.

## Related topics

- [Git rebase and force push](../topics/git/git_rebase.md)
