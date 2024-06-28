---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Common Git commands

Learn more about the most commonly used Git commands.

## `git blame`

Use `git blame` to report which users changed which parts of a file.

```shell
git blame <file_name>
```

You can use `git blame -L <line_start>, <line_end>` to check a only
specific range of lines.

For example, to check which user most recently modified line five of
`example.txt`:

```shell
$ git blame -L 5, 5 example.txt
123abc (Zhang Wei 2021-07-04 12:23:04 +0000 5)
```

## `git checkout`

Use `git checkout` to switch to a specific branch.

```shell
git checkout <branch_name>
```

To create a new branch and switch to it, use `git checkout -b <branch_name>`.

## `git init`

Use `git init` to initialize a directory so Git tracks it as a repository.

```shell
git init
```

A `.git` file with configuration and log files is added to the
directory. You shouldn't edit the `.git` file directly.

The default branch is set to `master`. You can change the name of the
default branch with `git branch -m <branch_name>`, or initialize with
`git init -b <branch_name>`.

## `git pull`

Use `git pull` to get all the changes made by users since the last
time you cloned or pulled the project.

```shell
git pull <optional_remote> <branch_name>
```

## `git remote add`

Use `git remote add` to tell Git which remote repository in GitLab is
linked to a local directory.

```shell
git remote add <remote_name> <repository_url>
```

When you clone a repository, by default the source repository is
associated with the remote name `origin`.

## `git reflog`

To display a list of changes to the Git reference logs, use `git reflog`.

```shell
git reflog
```

By default, `git reflog` shows a list of changes to `HEAD`.

## `git log`

To display a list of commits in chronological order, use `git log`.

```shell
git log
```

## `git show`

To show information about an object in Git, use `git show`.

For example, to see what commit `HEAD` points to:

```shell
$ git show HEAD
commit ab123c (HEAD -> main, origin/main, origin/HEAD)
```

## `git merge`

To combine the changes from one branch with another, use `git merge`.

For example, to apply the changes in `feature_branch` to the `target_branch`:

```shell
git checkout target_branch
git merge feature_branch
```

## `git rebase`

To rewrite the commit history of a branch, use `git rebase`.

You can use `git rebase` to resolve merge conflicts.

```shell
git rebase <branch_name>
```

In most cases, you want to rebase against the default branch.

## `git reset`

To undo a commit, use `git reset` to rewind the commit history and continue on from an earlier commit.

```shell
git reset
```
