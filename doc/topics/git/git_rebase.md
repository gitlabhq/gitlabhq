---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Introduction to Git rebase and force push, methods to resolve merge conflicts through the command line."
---

# Git rebase and force push **(FREE ALL)**

This guide helps you to get started with rebases, force pushes, and fixing
[merge conflicts](../../user/project/merge_requests/conflicts.md) locally.
Before you attempt a force push or a rebase, make sure you are familiar with
[Git through the command line](../../gitlab-basics/start-using-git.md).

WARNING:
`git rebase` rewrites the commit history. It **can be harmful** to do it in
shared branches. It can cause complex and hard to resolve
[merge conflicts](../../user/project/merge_requests/conflicts.md). In
these cases, instead of rebasing your branch against the default branch,
consider pulling it instead (`git pull origin master`). Pulling has similar
effects with less risk compromising the work of your contributors.

In Git, a rebase updates your feature branch with the contents of another branch.
This step is important for Git-based development strategies. Use a rebase to confirm
that your branch's changes don't conflict with any changes added to your target branch
_after_ you created your feature branch.

When you rebase:

1. Git imports all the commits submitted to your target branch _after_ you initially created
   your feature branch from it.
1. Git stacks the commits you have in your feature branch on top of all
   the commits it imported from that branch:

![Git rebase illustration](img/git_rebase_v13_5.png)

While most rebases are performed against `main`, you can rebase against any other
branch, such as `release-15-3`. You can also specify a different remote repository
(such as `upstream`) instead of `origin`.

## Back up a branch before rebase

To back up a branch before taking any destructive action, like a rebase or force push:

1. Open your feature branch in the terminal: `git checkout my-feature`
1. Create a backup branch: `git branch my-feature-backup`
   Any changes added to `my-feature` after this point are lost
   if you restore from the backup branch.

Your branch is backed up, and you can try a rebase or a force push.
If anything goes wrong, restore your branch from its backup:

1. Make sure you're in the correct branch (`my-feature`): `git checkout my-feature`
1. Reset it against `my-feature-backup`: `git reset --hard my-feature-backup`

## Rebase a branch

[Rebases](https://git-scm.com/docs/git-rebase) are very common operations in
Git, and have these options:

- **Regular rebases.** This type of rebase can be done through the
  [command line](#regular-rebase) and [the GitLab UI](#from-the-gitlab-ui).
- [**Interactive rebases**](#interactive-rebase) give more flexibility by
  enabling you to specify how to handle each commit. Interactive rebases
  must be done on the command line.

Any user who rebases a branch is treated as having added commits to that branch.
If a project is configured to
[**prevent approvals by users who add commits**](../../user/project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits),
a user who rebases a branch cannot also approve its merge request.

### Regular rebase

Standard rebases replay the previous commits on a branch without changes, stopping
only if merge conflicts occur.

Prerequisites:

- You must have permission to force push branches.

To update your branch `my-feature` with recent changes from your
[default branch](../../user/project/repository/branches/default.md) (here, using `main`):

1. Fetch the latest changes from `main`: `git fetch origin main`
1. Check out your feature branch: `git checkout my-feature`
1. Rebase it against `main`: `git rebase origin/main`
1. [Force push](#force-push) to your branch.

If there are merge conflicts, Git prompts you to fix them before continuing the rebase.

### From the GitLab UI

The `/rebase` [quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics)
rebases your feature branch directly from its merge request if all of these
conditions are met:

- No merge conflicts exist for your feature branch.
- You have the **Developer** role for the source project. This role grants you
  permission to push to the source branch for the source project.
- If the merge request is in a fork, the fork must allow commits
  [from members of the upstream project](../../user/project/merge_requests/allow_collaboration.md).

To rebase from the UI:

1. Go to your merge request.
1. Type `/rebase` in a comment.
1. Select **Comment**.

GitLab schedules a rebase of the feature branch against the default branch and
executes it as soon as possible.

### Interactive rebase

Use an interactive rebase (the `--interactive` flag, or `-i`) to simultaneously
update a branch while you modify how its commits are handled.
For example, to edit the last five commits in your branch (`HEAD~5`), run:

```shell
git rebase -i HEAD~5
```

Git opens the last five commits in your terminal text editor, oldest commit first.
Each commit shows the action to take on it, the SHA, and the commit title:

```shell
pick 111111111111 Second round of structural revisions
pick 222222222222 Update inbound link to this changed page
pick 333333333333 Shifts from H4 to H3
pick 444444444444 Adds revisions from editorial
pick 555555555555 Revisions continue to build the concept part out

# Rebase 111111111111..222222222222 onto zzzzzzzzzzzz (5 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
```

After the list of commits, a commented-out section shows some common actions you
can take on a commit:

- **Pick** a commit to use it with no changes. The default option.
- **Reword** a commit message.
- **Edit** a commit to use it, but pause the rebase to amend (add changes to) it.
- **Squash** multiple commits together to simplify the commit history
  of your feature branch.

Replace the keyword `pick` according to
the operation you want to perform in each commit. To do so, edit
the commits in your terminal's text editor.

For example, with [Vim](https://www.vim.org/) as the text editor in
a macOS Zsh shell, you can `squash` or `fixup` (combine) all of the commits together:

NOTE:
The steps for editing through the command line can be slightly
different depending on your operating system and the shell you use.

1. Press <kbd>i</kbd> on your keyboard to switch to Vim's editing mode.
1. Use your keyboard arrows to edit the **second** commit keyword
   from `pick` to `squash` or `fixup` (or `s` or `f`). Do the same to the remaining commits.
   Leave the first commit **unchanged** (`pick`) as we want to squash
   all other commits into it.
1. Press <kbd>Escape</kbd> to leave the editing mode.
1. Type `:wq` to "write" (save) and "quit".
1. When squashing, Git outputs the commit message so you have a chance to edit it:
   - All lines starting with `#` are ignored and not included in the commit
   message. Everything else is included.
   - To leave it as it is, type `:wq`. To edit the commit message: switch to the
   editing mode, edit the commit message, and save it as you just did.
1. If you haven't pushed your commits to the remote branch before rebasing,
   push your changes without a force push. If you had pushed these commits already,
   [force push](#force-push) instead.

#### Configure squash options for a project

Keeping the default branch commit history clean doesn't require you to
manually squash all your commits on each merge request. GitLab provides
[squash and merge](../../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project),
options at a project level.

## Force push

Complex operations in Git require you to force an update to the remote branch.
Operations like squashing commits, resetting a branch, or rebasing a branch rewrite
the history of your branch. Git requires a forced update to help safeguard against
these more destructive changes from happening accidentally.

Force pushing is not recommended on shared branches, as you risk destroying the
changes of others.

If the branch you want to force push is [protected](../../user/project/protected_branches.md),
you can't force push to it unless you either:

- Unprotect it.
- [Allow force pushes](../../user/project/protected_branches.md#allow-force-push-on-a-protected-branch)
  to it.

Then you can force push and protect it again.

### `--force-with-lease` flag

The [`--force-with-lease`](https://git-scm.com/docs/git-push#Documentation/git-push.txt---force-with-leaseltrefnamegt)
flag force pushes. Because it preserves any new commits added to the remote
branch by other people, it is safer than `--force`:

```shell
git push --force-with-lease origin my-feature
```

### `--force` flag

The `--force` flag forces pushes, but does not preserve any new commits added to
the remote branch by other people. To use this method, pass the flag `--force` or `-f`
to the `push` command:

```shell
git push --force origin my-feature
```

## Related topics

- [Numerous undo possibilities in Git](numerous_undo_possibilities_in_git/index.md#undo-staged-local-changes-without-modifying-history)
- [Git documentation for branches and rebases](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
