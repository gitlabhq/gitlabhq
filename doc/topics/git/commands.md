---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Common Git commands
---

Learn more about the most commonly used Git commands.

## `git add`

Use `git add` to files to the staging area.

```shell
git add <file_path>
```

You can recursively stage changes from the current working directory with `git add .`, or stage all changes in the Git
repository with `git add --all`.

For more information, see [Add files to your branch](add_files.md).

## `git blame`

Use `git blame` to report which users changed which parts of a file.

```shell
git blame <file_name>
```

You can use `git blame -L <line_start>, <line_end>` to check a specific range of lines.

For more information, see [Git file blame](../../user/project/repository/files/git_blame.md).

### Example

To check which user most recently modified line five of `example.txt`:

```shell
$ git blame -L 5, 5 example.txt
123abc (Zhang Wei 2021-07-04 12:23:04 +0000 5)
```

## `git bisect`

Use `git bisect`to use binary search to find the commit that introduced a bug.

Start by identifying a commit that is "bad" (contains the bug) and a commit that is "good" (doesn't contain the bug).

```shell
git bisect start
git bisect bad                 # Current version is bad
git bisect good v2.6.13-rc2    # v2.6.13-rc2 is known to be good
```

`git bisect` then picks a commit in between the two points and asks you identify if the commit is "good" or "bad" with
`git bisect good`or `git bisect bad`. Repeat the process until the commit is found.

## `git checkout`

Use `git checkout` to switch to a specific branch.

```shell
git checkout <branch_name>
```

To create a new branch and switch to it, use `git checkout -b <branch_name>`.

For more information, see [Create a Git branch for your changes](branch.md).

## `git clone`

Use `git clone` to copy an existing Git repository.

```shell
git clone <repository>
```

For more information, see [Clone a Git repository to your local computer](clone.md).

## `git commit`

Use `git commit` to commits staged changes to the repository.

```shell
git commit -m "<commit_message>"
```

If the commit message contains a blank line, the first line becomes the commit subject while the remainder becomes the
commit body. Use the subject to briefly summarize a change, and the commit body to provide additional details.

For more information, see [Stage, commit, and push changes](commit.md).

## `git commit --amend`

Use `git commit --amend` to modify the most recent commit.

```shell
git commit --amend
```

## `git diff`

Use `git diff` to view the differences between your local unstaged changes and the latest version that you cloned or
pulled.

```shell
git diff
```

You can display the difference (or diff) between your local changes and the most recent version of a branch. View a
diff to understand your local changes before you commit them to the branch.

To compare your changes against a specific branch, run:

```shell
git diff <branch>
```

In the output:

- Lines with additions begin with a plus (`+`) and are displayed in green.
- Lines with removals or changes begin with a minus (`-`) and are displayed in red.

## `git init`

Use `git init` to initialize a directory so Git tracks it as a repository.

```shell
git init
```

A `.git` file with configuration and log files is added to the directory. You shouldn't edit the `.git` file directly.

The default branch is set to `main`. You can change the name of the default branch with `git branch -m <branch_name>`,
or initialize with `git init -b <branch_name>`.

## `git pull`

Use `git pull` to get all the changes made by users after the last time you cloned or pulled the project.

```shell
git pull <optional_remote> <branch_name>
```

## `git push`

Use `git push` to update remote refs.

```shell
git push
```

For more information, see [Stage, commit, and push changes](commit.md).

## `git reflog`

Use `git reflog` to display a list of changes to the Git reference logs.

```shell
git reflog
```

By default, `git reflog` shows a list of changes to `HEAD`.

For more information, see [Undo changes](undo.md).

## `git remote add`

Use `git remote add` to tell Git which remote repository in GitLab is linked to a local directory.

```shell
git remote add <remote_name> <repository_url>
```

When you clone a repository, by default the source repository is associated with the remote name `origin`.

For more information on configuring additional remotes, see [Forks](../../user/project/repository/forking_workflow.md).

## `git log`

Use `git log` to display a list of commits in chronological order.

```shell
git log
```

## `git show`

Use `git show` to show information about an object in Git.

### Example

To see what commit `HEAD` points to:

```shell
$ git show HEAD
commit ab123c (HEAD -> main, origin/main, origin/HEAD)
```

## `git merge`

Use `git merge` to combine the changes from one branch with another.

For more information on an alternative to `git merge`, see [Rebase to address merge conflicts](git_rebase.md).

### Example

To apply the changes in `feature_branch` to the `target_branch`:

```shell
git checkout target_branch
git merge feature_branch
```

## `git rebase`

Use `git rebase` to rewrite the commit history of a branch.

```shell
git rebase <branch_name>
```

You can use `git rebase` to [resolve merge conflicts](git_rebase.md).

In most cases, you want to rebase against the default branch.

## `git reset`

Use `git reset` to undo a commit and rewind the commit history and continue on from an earlier commit.

```shell
git reset
```

For more information, see [Undo changes](undo.md).

## `git status`

Use `git status` to show the status of the working directory and staged files.

```shell
git status
```

When you add, change, or delete files, Git can show you the changes.
