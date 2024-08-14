---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Undo changes

Git provides options for undoing changes. The method for undoing a change depends on whether the change is unstaged, staged, committed, or pushed.

## When you can undo changes

In the standard Git workflow:

1. You create or edit a file. It starts in the unstaged state. If it's new, it is not yet tracked by Git.
1. You add the file to your local repository (`git add`), which puts the file into the staged state.
1. You commit the file to your local repository (`git commit`).
1. You can then share the file with other developers, by committing to a remote repository (`git push`).

You can undo changes at any point in this workflow:

- [When you're working locally](#undo-local-changes) and haven't yet pushed to a remote repository.
- When you have already pushed to a remote repository and you want to:
  - [Keep the history intact](#undo-remote-changes-without-changing-history) (preferred).
  - [Change the history](#undo-remote-changes-while-changing-history) (requires
    coordination with team and force pushes).

## Undo local changes

Until you push your changes to a remote repository, changes
you make in Git are only in your local development environment.

### Undo unstaged local changes

When you make a change, but have not yet staged it, you can undo your work.

1. Confirm that the file is unstaged (that you did not use `git add <file>`) by running `git status`:

   ```shell
   $ git status
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

   - To save local changes so you can [re-use them later](#quickly-save-local-changes):

     ```shell
     git stash
     ```

   - To discard local changes to all files, permanently:

     ```shell
     git reset --hard
     ```

### Undo staged local changes

If you added a file to staging, you can undo it.

1. Confirm that the file is staged (that you used `git add <file>`) by running `git status`:

   ```shell
   $ git status
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

   - To discard all local changes, but save them for [later](#quickly-save-local-changes):

     ```shell
     git stash
     ```

   - To discard everything permanently:

     ```shell
     git reset --hard
     ```

### Quickly save local changes

If you want to change to another branch, you can use [`git stash`](https://www.git-scm.com/docs/git-stash).

1. From the branch where you want to save your work, type `git stash`.
1. Swap to another branch (`git checkout <branchname>`).
1. Commit, push, and test.
1. Return to the branch where you want to resume your changes.
1. Use `git stash list` to list all previously stashed commits.

   ```shell
   stash@{0}: WIP on submit: 6ebd0e2... Update git-stash documentation
   stash@{1}: On master: 9cc0589... Add git-stash
   ```

1. Run a version of `git stash`:

   - Use `git stash pop` to redo previously stashed changes and remove them from stashed list.
   - Use `git stash apply` to redo previously stashed changes, but keep them on stashed list.

## Undo committed local changes

When you commit to your local repository (`git commit`), Git records
your changes. Because you did not push to a remote repository yet, your changes are
not public (or shared with other developers). At this point, you can undo your changes.

### Undo staged local changes without modifying history

You can revert a commit while retaining the commit history.

This example uses five commits `A`,`B`,`C`,`D`,`E`, which were committed in order: `A-B-C-D-E`.
The commit you want to undo is `B`.

1. Find the commit SHA of the commit you want to revert to. To look
   through a log of commits, type `git log`.
1. Choose an option and undo your changes:

   - To swap additions and deletions changes introduced by commit `B`:

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

#### Undo multiple committed changes

You can recover from multiple commits. For example, if you have done commits `A-B-C-D`
on your branch and then realize that `C` and `D` are wrong.

To recover from multiple incorrect commits:

1. Check out the last correct commit. In this example, `B`.

   ```shell
   git checkout <commit-B-SHA>
   ```

1. Create a new branch.

   ```shell
   git checkout -b new-path-of-feature
   ```

1. Add, push, and commit your changes.

The commits are now `A-B-C-D-E`.

Alternatively, with GitLab,
you can [cherry-pick](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-a-single-commit)
that commit into a new merge request.

NOTE:
Another solution is to reset to `B` and commit `E`. However, this solution results in `A-B-E`,
which clashes with what other developers have locally.

### Undo staged local changes with history modification

The following tasks rewrite Git history.

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

#### Modify a specific commit

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

### Redoing the undo

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

## Undo remote changes without changing history

To undo changes in the remote repository, you can create a new commit with the changes you
want to undo. You should follow this process, which preserves the history and
provides a clear timeline and development structure. However, you
only need this procedure if your work was merged into a branch that
other developers use as the base for their work.

![Use revert to keep branch flowing](img/revert.png)

To revert changes introduced in a specific commit `B`:

```shell
git revert B
```

## Undo remote changes while changing history

You can undo remote changes and change history.

Even with an updated history, old commits can still be
accessed by commit SHA. This is the case at least until all the automated cleanup
of detached commits is performed, or a cleanup is run manually. Even the cleanup might not remove old commits if there are still refs pointing to them.

![Modifying history causes problems on remote branch](img/rebase_reset.png)

### When changing history is acceptable

You should not change the history when you're working in a public branch
or a branch that might be used by other developers.

When you contribute to large open source repositories, like [GitLab](https://gitlab.com/gitlab-org/gitlab),
you can squash your commits into a single one.

To squash commits on your branch to a single commit on a target branch
at merge, use `git merge --squash`.

NOTE:
Never modify the commit history of your [default branch](../../user/project/repository/branches/default.md) or shared branch.

### How to change history

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

### Redact text

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/450701) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `rewrite_history_ui`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.2.
> - [Enabled on self-managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.3.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Permanently delete sensitive or confidential information that was accidentally committed, ensuring
it's no longer accessible in your repository's history.
Replaces a list of strings with `***REMOVED***`.

Alternatively, to completely delete specific files from a repository, see
[Remove blobs](../../user/project/repository/reducing_the_repo_size_using_git.md#remove-blobs).

Prerequisites:

- You must have the Owner role for the instance.

To redact text from your repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. Select **Redact text**.
1. On the drawer, enter the text to redact.
   You can use regex and glob patterns.
1. Select **Redact matching strings**.
1. On the confirmation dialog, enter your project path.
1. Select **Yes, redact matching strings**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Select **Run housekeeping**.

### Delete sensitive information from commits

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
see [Reduce repository size](../../user/project/repository/reducing_the_repo_size_using_git.md).

## Undo commits by removing them

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

### Git reset sample workflow

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

## Undo commits with a new replacement commit

```shell
git revert <commit-sha>
```

## The difference between `git revert` and `git reset`

- The `git reset` command removes the commit. The `git revert` command removes the changes but leaves the commit.
- The `git revert` command is safer, because you can revert a revert.

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

## Unstage changes

When you _stage_ a file in Git, you instruct Git to track changes to the file in
preparation for a commit. To disregard changes to a file, and not
include it in your next commit, _unstage_ the file.

### Unstage a file

- To remove files from staging, but keep your changes:

  ```shell
  git reset HEAD <file>
  ```

- To unstage the last three commits:

  ```shell
  git reset HEAD^3
  ```

- To unstage changes to a certain file from HEAD:

  ```shell
  git reset <filename>
  ```

After you unstage the file, to revert the file back to the state it was in before the changes:

```shell
git checkout -- <file>
```

### Remove a file

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
[Remove blobs](../../user/project/repository/reducing_the_repo_size_using_git.md#remove-blobs).

## Related topics

- [`git blame`](../../user/project/repository/files/git_blame.md)
- [Cherry-pick](../../user/project/merge_requests/cherry_pick_changes.md)
- [Git history](../../user/project/repository/files/git_history.md)
- [Revert an existing commit](../../user/project/merge_requests/revert_changes.md#revert-a-commit)
- [Squash and merge](../../user/project/merge_requests/squash_and_merge.md)
