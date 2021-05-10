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
  - [Change the history](#undo-remote-changes-with-modifying-history) (requires
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
1. Run a version of `git stash`:

   - Use `git stash pop` to redo previously stashed changes and remove them from stashed list.
   - Use `git stash apply` to redo previously stashed changes, but keep them on stashed list.

## Undo committed local changes

When you commit to your local repository (`git commit`), the version control system records
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

You can rewrite history in Git, but you should avoid it, because it can cause problems
when multiple developers are contributing to the same codebase.

There is one command for history modification and that is `git rebase`. Command
provides interactive mode (`-i` flag) which enables you to:

- **reword** commit messages (there is also `git commit --amend` for editing
  last commit message).
- **edit** the commit content (changes introduced by commit) and message.
- **squash** multiple commits into a single one, and have a custom or aggregated
  commit message.
- **drop** commits - delete them.
- and few more options.

Let us check few examples. Again there are commits `A-B-C-D` where you want to
delete commit `B`.

- Rebase the range from current commit D to A:

  ```shell
  git rebase -i A
  ```

- Command opens your favorite editor where you write `drop` in front of commit
 `B`, but you leave default `pick` with all other commits. Save and exit the
 editor to perform a rebase. Remember: if you want to cancel delete whole
 file content before saving and exiting the editor

In case you want to modify something introduced in commit `B`.

- Rebase the range from current commit D to A:

  ```shell
  git rebase -i A
  ```

- Command opens your favorite text editor where you write `edit` in front of commit
 `B`, but leave default `pick` with all other commits. Save and exit the editor to
 perform a rebase.

- Now do your edits and commit changes:

  ```shell
  git commit -a
  ```

You can find some more examples in the section explaining
[how to modify history](#how-modifying-history-is-done).

### Redoing the undo

Sometimes you realize that the changes you undid were useful and you want them
back. Well because of first paragraph you are in luck. Command `git reflog`
enables you to *recall* detached local commits by referencing or applying them
via commit ID. Although, do not expect to see really old commits in reflog, because
Git regularly [cleans the commits which are *unreachable* by branches or tags](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery).

To view repository history and to track older commits you can use below command:

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

Output of command shows repository history. In first column there is commit ID,
in following column, number next to `HEAD` indicates how many commits ago something
was made, after that indicator of action that was made (commit, rebase, merge, ...)
and then on end description of that action.

## Undo remote changes without changing history

This topic is roughly same as modifying committed local changes without modifying
history. **It should be the preferred way of undoing changes on any remote repository
or public branch.** Keep in mind that branching is the best solution when you want
to retain the history of faulty development, yet start anew from certain point.

Branching
enables you to include the existing changes in new development (by merging) and
it also provides a clear timeline and development structure.

![Use revert to keep branch flowing](img/revert.png)

If you want to revert changes introduced in certain `commit-id`, you can
revert that `commit-id` (swap additions and deletions) in newly created commit:
You can do this with

```shell
git revert commit-id
```

or creating a new branch:

```shell
git checkout commit-id
git checkout -b new-path-of-feature
```

## Undo remote changes with modifying history

This is useful when you want to *hide* certain things - like secret keys,
passwords, and SSH keys. It is and should not be used to hide mistakes, as
it makes it harder to debug in case there are some other bugs. The main
reason for this is that you loose the real development progress. Keep in
mind that, even with modified history, commits are just detached and can still be
accessed through commit ID - at least until all repositories perform
the automated cleanup of detached commits.

![Modifying history causes problems on remote branch](img/rebase_reset.png)

### Where modifying history is generally acceptable

Modified history breaks the development chain of other developers, as changed
history does not have matching commit IDs. For that reason it should not be
used on any public branch or on branch that might be used by other developers.
When contributing to big open source repositories (for example, [GitLab](https://gitlab.com/gitlab-org/gitlab/blob/master/CONTRIBUTING.md#contribution-acceptance-criteria)
itself), it is acceptable to squash commits into a single one, to present a
nicer history of your contribution.

Keep in mind that this also removes the comments attached to certain commits
in merge requests, so if you need to retain traceability in GitLab, then
modifying history is not acceptable.

A feature branch of a merge request is a public branch and might be used by
other developers, but project process and rules might allow or require
you to use `git rebase` (command that changes history) to reduce number of
displayed commits on target branch after reviews are done (for example
GitLab). There is a `git merge --squash` command which does exactly that
(squashes commits on feature-branch to a single commit on target branch
at merge).

NOTE:
Never modify the commit history of `master` or shared branch.

### How modifying history is done

After you know what you want to modify (how far in history or how which range of
old commits), use `git rebase -i commit-id`. This command displays all the commits from
current version to chosen commit ID and allow modification, squashing, deletion
of that commits.

```shell
$ git rebase -i commit1-id..commit3-id
pick <commit1-id> <commit1-commit-message>
pick <commit2-id> <commit2-commit-message>
pick <commit3-id> <commit3-commit-message>

# Rebase commit1-id..commit3-id onto <commit4-id> (3 command(s))
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
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```

NOTE:
The comment from the output clearly states that, if
you decide to abort, don't just close your editor (as that
modifies history), but remove all uncommented lines and save.

Use `git rebase` carefully on
shared and remote branches, but rest assured: nothing is broken until
you push back to the remote repository (so you can freely explore the
different outcomes locally).

```shell
# Modify history from commit-id to HEAD (current commit)
git rebase -i commit-id
```

### Deleting sensitive information from commits

Git also enables you to delete sensitive information from your past commits and
it does modify history in the progress. That is why we have included it in this
section and not as a standalone topic. To do so, you should run the
`git filter-branch`, which enables you to rewrite history with
[certain filters](https://git-scm.com/docs/git-filter-branch#_options).
This command uses rebase to modify history and if you want to remove certain
file from history altogether use:

```shell
git filter-branch --tree-filter 'rm filename' HEAD
```

Because `git filter-branch` command might be slow on big repositories, there are
tools that can use some of Git specifics to enable faster execution of common
tasks (which is exactly what removing sensitive information file is about).
An alternative is the open source community-maintained tool [BFG](https://rtyley.github.io/bfg-repo-cleaner/).
Keep in mind that these tools are faster because they do not provide the same
feature set as `git filter-branch` does, but focus on specific use cases.

Refer [Reduce repository size](../../../user/project/repository/reducing_the_repo_size_using_git.md) page to know more about purging files from repository history & GitLab storage.

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
