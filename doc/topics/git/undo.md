---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Revert and undo changes
---

Git provides options for undoing changes at any point in the
[Git workflow](get_started.md#understand-the-git-workflow).

The method to use depends on whether the changes are:

- Only on your local computer.
- Stored remotely on a Git server such as GitLab.com.

## Undo local changes

Until you push your changes to a remote repository, changes
you make in Git are only in your local development environment.

When you _stage_ a file in Git, you instruct Git to track changes to the file in
preparation for a commit. To disregard changes to a file, and not
include it in your next commit, _unstage_ the file.

### Revert unstaged local changes

To undo local changes that are not yet staged:

1. Confirm that the file is unstaged (that you did not use `git add <file>`) by running `git status`:

   ```shell
   git status
   ```

   Example output:

   ```shell
   On branch main
   Your branch is up-to-date with 'origin/main'.
   Changes not staged for commit:
     (use "git add <file>..." to update what will be committed)
     (use "git checkout -- <file>..." to discard changes in working directory)

       modified:   <file>
   no changes added to commit (use "git add" and/or "git commit -a")
   ```

1. Choose an option and undo your changes:

   - To overwrite local changes:

     ```shell
     git checkout -- <file>
     ```

   - To discard local changes to all files, permanently:

     ```shell
     git reset --hard
     ```

### Revert staged local changes

You can undo local changes that are already staged. In the following example,
a file was added to the staging, but not committed:

1. Confirm that the file is staged with `git status`:

   ```shell
   git status
   ```

   Example output:

   ```shell
   On branch main
   Your branch is up-to-date with 'origin/main'.
   Changes to be committed:
     (use "git restore --staged <file>..." to unstage)

     new file:   <file>
   ```

1. Choose an option and undo your changes:

   - To unstage the file but keep your changes:

     ```shell
     git restore --staged <file>
     ```

   - To unstage everything but keep your changes:

     ```shell
     git reset
     ```

   - To unstage the file to current commit (HEAD):

     ```shell
     git reset HEAD <file>
     ```

   - To discard everything permanently:

     ```shell
     git reset --hard
     ```

## Undo local commits

When you commit to your local repository with `git commit`, Git records
your changes. Because you did not push to a remote repository yet, your changes are
not public or shared with others. At this point, you can undo your changes.

### Revert commits without altering history

You can revert a commit while retaining the commit history.

This example uses five commits `A`,`B`,`C`,`D`,`E`, which were committed in order: `A-B-C-D-E`.
The commit you want to undo is `B`.

1. Find the commit SHA of the commit you want to revert to. To look
   through a log of commits, use the command `git log`.
1. Choose an option and undo your changes:

   - To revert changes introduced by commit `B`:

     ```shell
     git revert <commit-B-SHA>
     ```

   - To undo changes on a single file or directory from commit `B`, but retain them in the staged state:

     ```shell
     git checkout <commit-B-SHA> <file>
     ```

   - To undo changes on a single file or directory from commit `B`, but retain them in the unstaged state:

     ```shell
     git reset <commit-B-SHA> <file>
     ```

### Revert commits and modify history

The following sections document tasks that rewrite Git history. For more information, see
[Rebase and resolve conflicts](git_rebase.md).

#### Delete a specific commit

You can delete a specific commit. For example, if you have
commits `A-B-C-D` and you want to delete commit `B`.

1. Rebase the range from current commit `D` to `B`:

   ```shell
   git rebase -i A
   ```

   A list of commits is displayed in your editor.

1. In front of commit `B`, replace `pick` with `drop`.
1. Leave the default, `pick`, for all other commits.
1. Save and exit the editor.

#### Edit a specific commit

You can modify a specific commit. For example, if you have
commits `A-B-C-D` and you want to modify something introduced in commit `B`.

1. Rebase the range from current commit `D` to `B`:

   ```shell
   git rebase -i A
   ```

   A list of commits is displayed in your editor.

1. In front of commit `B`, replace `pick` with `edit`.
1. Leave the default, `pick`, for all other commits.
1. Save and exit the editor.
1. Open the file in your editor, make your edits, and commit the changes:

   ```shell
   git commit -a
   ```

### Undo multiple commits

If you create multiple commits (`A-B-C-D`) on your branch, then realize commits `C` and `D`
are wrong, undo both incorrect commits:

1. Check out the last correct commit. In this example, `B`.

   ```shell
   git checkout <commit-B-SHA>
   ```

1. Create a new branch.

   ```shell
   git checkout -b new-path-of-feature
   ```

1. Add, push, and commit your changes.

   ```shell
   git add .
   git commit -m "Undo commits C and D"
   git push --set-upstream origin new-path-of-feature
   ```

The commits are now `A-B-C-D-E`.

Alternatively, [cherry-pick](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-a-single-commit)
that commit into a new merge request.

NOTE:
Another solution is to reset to `B` and commit `E`. However, this solution results in `A-B-E`,
which clashes with what others have locally. Don't use this solution if your branch is shared.

### Recover undone commits

You can recall previous local commits. However, not all previous commits are available, because
Git regularly [cleans the commits that are unreachable by branches or tags](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery).

To view repository history and track prior commits, run `git reflog show`. For example:

```shell
$ git reflog show

# Example output:
b673187 HEAD@{4}: merge 6e43d5987921bde189640cc1e37661f7f75c9c0b: Merge made by the 'recursive' strategy.
eb37e74 HEAD@{5}: rebase -i (finish): returning to refs/heads/master
eb37e74 HEAD@{6}: rebase -i (pick): Commit C
97436c6 HEAD@{7}: rebase -i (start): checkout 97436c6eec6396c63856c19b6a96372705b08b1b
...
88f1867 HEAD@{12}: commit: Commit D
97436c6 HEAD@{13}: checkout: moving from 97436c6eec6396c63856c19b6a96372705b08b1b to test
97436c6 HEAD@{14}: checkout: moving from master to 97436c6
05cc326 HEAD@{15}: commit: Commit C
6e43d59 HEAD@{16}: commit: Commit B
```

This output shows the repository history, including:

- The commit SHA.
- How many `HEAD`-changing actions ago the commit was made (`HEAD@{12}` was 12 `HEAD`-changing actions ago).
- The action that was taken, for example: commit, rebase, merge.
- A description of the action that changed `HEAD`.

## Undo remote changes

You can undo remote changes on your branch. However, you cannot undo changes on a branch that
was merged into your branch. In that case, you must revert the changes on the remote branch.

### Revert remote changes without altering history

To undo changes in the remote repository, you can create a new commit with the changes you
want to undo. This process preserves the history and provides a clear timeline and development structure.

![Use revert to keep branch flowing](img/revert_v14_0.png)

To revert changes introduced in a specific commit `B`:

```shell
git revert B
```

### Revert remote changes and modify history

You can undo remote changes and change history.

Even with an updated history, old commits can still be
accessed by commit SHA, at least until all the automated cleanup
of detached commits is performed, or a cleanup is run manually. Even the cleanup might not remove old commits if there are still refs pointing to them.

![Modifying history causes problems on remote branch](img/rebase_reset_v10_0.png)

You should not change the history when you're working in a public branch
or a branch that might be used by others.

NOTE:
Never modify the commit history of your [default branch](../../user/project/repository/branches/default.md) or shared branch.

### Modify history with `git rebase`

A branch of a merge request is a public branch and might be used by
other developers. However, the project rules might require
you to use `git rebase` to reduce the number of
displayed commits on target branch after reviews are done.

You can modify history by using `git rebase -i`. Use this command to modify, squash,
and delete commits.

```shell
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Empty commits are commented out
```

NOTE:
If you decide to stop a rebase, do not close your editor.
Instead, remove all uncommented lines and save.

Use `git rebase` carefully on shared and remote branches.
Experiment locally before you push to the remote repository.

```shell
# Modify history from commit-id to HEAD (current commit)
git rebase -i commit-id
```

### Modify history with `git merge --squash`

When contributing to large open source repositories, consider squashing your commits
into a single commit. This practice:

- Helps maintain a clean and linear project history.
- Simplifies the process of reverting changes, as all changes are condensed into one commit.

To squash commits on your branch to a single commit on a target branch
at merge, use `git merge --squash`. For example:

1. Check out the base branch. In this example, the base branch is `main`:

   ```shell
   git checkout main
   ```

1. Merge your target branch with `--squash`:

   ```shell
   git merge --squash <target-branch>
   ```

1. Commit the changes:

   ```shell
   git commit -m "Squash commit from feature-branch"
   ```

For information on how to squash commits from the GitLab UI, see [Squash and merge](../../user/project/merge_requests/squash_and_merge.md).

### Revert a merge commit to a different parent

When you revert a merge commit, the branch you merged to is always the
first parent. For example, the [default branch](../../user/project/repository/branches/default.md) or `main`.
To revert a merge commit to a different parent, you must revert the commit from the command line:

1. Identify the SHA of the parent commit you want to revert to.
1. Identify the parent number of the commit you want to revert to. (Defaults to `1`, for the first parent.)
1. Run this command, replacing `2` with the parent number, and `7a39eb0` with the commit SHA:

   ```shell
   git revert -m 2 7a39eb0
   ```

For information on reverting changes from the GitLab UI, see [Revert changes](../../user/project/merge_requests/revert_changes.md).

## Handle sensitive information

Sensitive information, such as passwords and API keys, can be
accidentally committed to a Git repository. This section covers
ways to handle this situation.

### Redact information

Permanently delete sensitive or confidential information that was accidentally committed, and ensure
it's no longer accessible in your repository's history. This process replaces a list of strings with `***REMOVED***`.

Alternatively, to completely delete specific files from a repository, see
[Remove blobs](../../user/project/repository/repository_size.md#remove-blobs).

To redact text from your repository, see [Redact text from repository](../../user/project/merge_requests/revert_changes.md#redact-text-from-repository).

### Remove information from commits

You can use Git to delete sensitive information from your past commits. However,
history is modified in the process.

To rewrite history with
[certain filters](https://git-scm.com/docs/git-filter-branch#_options),
run `git filter-branch`.

To remove a file from the history altogether use:

```shell
git filter-branch --tree-filter 'rm filename' HEAD
```

The `git filter-branch` command might be slow on large repositories.
Tools are available to execute Git commands more quickly.
These tools are faster because they do not provide the same
feature set as `git filter-branch` does, but focus on specific use cases.

For more information about purging files from the repository history and GitLab storage,
see [Reduce repository size](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Undo and remove commits

- Undo your last commit and put everything back in the staging area:

  ```shell
  git reset --soft HEAD^
  ```

- Add files and change the commit message:

  ```shell
  git commit --amend -m "New Message"
  ```

- Undo the last change and remove all other changes,
  if you did not push yet:

  ```shell
  git reset --hard HEAD^
  ```

- Undo the last change and remove the last two commits,
  if you did not push yet:

  ```shell
  git reset --hard HEAD^^
  ```

### Example `git reset` workflow

The following is a common Git reset workflow:

1. Edit a file.
1. Check the status of the branch:

   ```shell
   git status
   ```

1. Commit the changes to the branch with a wrong commit message:

   ```shell
   git commit -am "kjkfjkg"
   ```

1. Check the Git log:

   ```shell
   git log
   ```

1. Amend the commit with the correct commit message:

   ```shell
   git commit --amend -m "New comment added"
   ```

1. Check the Git log again:

   ```shell
   git log
   ```

1. Soft reset the branch:

   ```shell
   git reset --soft HEAD^
   ```

1. Check the Git log again:

   ```shell
   git log
   ```

1. Pull updates for the branch from the remote:

   ```shell
   git pull origin <branch>
   ```

1. Push changes for the branch to the remote:

   ```shell
   git push origin <branch>
   ```

## Undo commits with a new commit

If a file was changed in a commit, and you want to change it back to how it was in the previous commit,
but keep the commit history, you can use `git revert`. The command creates a new commit that reverses
all actions taken in the original commit.

For example, to remove a file's changes in commit `B`, and restore its contents from commit `A`, run:

```shell
git revert <commit-sha>
```

## Remove a file from a repository

- To remove a file from disk and repository, use `git rm`. To remove a directory, use the `-r` flag:

  ```shell
  git rm '*.txt'
  git rm -r <dirname>
  ```

- To keep a file on disk but remove it from the repository (such as a file you want
  to add to `.gitignore`), use the `rm` command with the `--cache` flag:

  ```shell
  git rm <filename> --cache
  ```

These commands remove the file from current branches, but do not expunge it from your repository's history.
To completely remove all traces of the file, past and present, from your repository, see
[Remove blobs](../../user/project/repository/repository_size.md#remove-blobs).

## Compare `git revert` and `git reset`

- The `git reset` command removes the commit entirely.
- The `git revert` command removes the changes, but leaves the commit intact.
  It's safer, because you can revert a revert.

```shell
# Changed file
git commit -am "bug introduced"
git revert HEAD
# New commit created reverting changes
# Now we want to re apply the reverted commit
git log # take hash from the revert commit
git revert <rev commit hash>
# reverted commit is back (new commit created again)
```

## Related topics

- [`git blame`](../../user/project/repository/files/git_blame.md)
- [Cherry-pick](../../user/project/merge_requests/cherry_pick_changes.md)
- [Git history](../../user/project/repository/files/git_history.md)
- [Revert an existing commit](../../user/project/merge_requests/revert_changes.md#revert-a-commit)
- [Squash and merge](../../user/project/merge_requests/squash_and_merge.md)
