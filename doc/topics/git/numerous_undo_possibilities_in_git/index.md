---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Undo possibilities in Git **(FREE)**

[Nothing in Git is deleted](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery),
so when you work in Git, you can undo your work.

All version control systems have options for undoing work. However,
because of the de-centralized nature of Git, these options are multiplied.
The actions you take are based on the
[stage of development](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository)
you are in.

For more information about working with Git and GitLab:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Learn why [North Western Mutual chose GitLab](https://youtu.be/kPNMyxKRRoM) for their enterprise source code management.
- Learn how to [get started with Git](https://about.gitlab.com/resources/whitepaper-moving-to-git/).
- For more advanced examples, refer to the [Git book](https://git-scm.com/book/en/v2).

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
on your feature branch and then realize that `C` and `D` are wrong.

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
you can [cherry-pick](../../../user/project/merge_requests/cherry_pick_changes.md#cherry-picking-a-commit)
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

To squash commits on a feature branch to a single commit on a target branch
at merge, use `git merge --squash`.

NOTE:
Never modify the commit history of your [default branch](../../../user/project/repository/branches/default.md) or shared branch.

### How to change history

A feature branch of a merge request is a public branch and might be used by
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
An alternative is the open source community-maintained tool [BFG](https://rtyley.github.io/bfg-repo-cleaner/).
These tools are faster because they do not provide the same
feature set as `git filter-branch` does, but focus on specific use cases.

Refer to [Reduce repository size](../../../user/project/repository/reducing_the_repo_size_using_git.md) to
learn more about purging files from repository history and GitLab storage.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

<!-- Identifiers, in alphabetical order -->
