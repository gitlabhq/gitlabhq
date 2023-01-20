---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: concepts, howto
description: "Introduction to Git rebase and force-push, methods to resolve merge conflicts through the command line."
---

# Introduction to Git rebase and force-push **(FREE)**

This guide helps you to get started with rebasing, force-pushing, and fixing
[merge conflicts](../../user/project/merge_requests/conflicts.md) locally.

Before diving into this document, make sure you are familiar with using
[Git through the command line](../../gitlab-basics/start-using-git.md).

## Git rebase

[Rebasing](https://git-scm.com/docs/git-rebase) is a very common operation in
Git, and has these options:

- [Regular rebase](#regular-rebase).
- [Interactive rebase](#interactive-rebase).

### Before rebasing

WARNING:
`git rebase` rewrites the commit history. It **can be harmful** to do it in
shared branches. It can cause complex and hard to resolve
[merge conflicts](../../user/project/merge_requests/conflicts.md). In
these cases, instead of rebasing your branch against the default branch,
consider pulling it instead (`git pull origin master`). It has a similar
effect without compromising the work of your contributors.

It's safer to back up your branch before rebasing to make sure you don't lose
any changes. For example, consider a [feature branch](../../gitlab-basics/start-using-git.md#branches)
called `my-feature-branch`:

1. Open your feature branch in the terminal:

   ```shell
   git checkout my-feature-branch
   ```

1. Checkout a new branch from it:

   ```shell
   git checkout -b my-feature-branch-backup
   ```

1. Go back to your original branch:

   ```shell
   git checkout my-feature-branch
   ```

Now you can safely rebase it. If anything goes wrong, you can recover your
changes by resetting `my-feature-branch` against `my-feature-branch-backup`:

1. Make sure you're in the correct branch (`my-feature-branch`):

   ```shell
   git checkout my-feature-branch
   ```

1. Reset it against `my-feature-branch-backup`:

   ```shell
   git reset --hard my-feature-branch-backup
   ```

If you added changes to `my-feature-branch` after creating the backup branch,
you lose them when resetting.

### Regular rebase

With a regular rebase you can update your feature branch with the default
branch (or any other branch).
This step is important for Git-based development strategies. You can
ensure your new changes don't break any
existing changes added to the target branch _after_ you created your feature
branch.

For example, to update your branch `my-feature-branch` with your
[default branch](../../user/project/repository/branches/default.md) (here, using `main`):

1. Fetch the latest changes from `main`:

   ```shell
   git fetch origin main
   ```

1. Checkout your feature branch:

   ```shell
   git checkout my-feature-branch
   ```

1. Rebase it against `main`:

   ```shell
   git rebase origin/main
   ```

1. [Force-push](#force-push) to your branch.

When you rebase:

1. Git imports all the commits submitted to `main` _after_ the
   moment you created your feature branch until the present moment.
1. Git puts the commits you have in your feature branch on top of all
   the commits imported from `main`:

![Git rebase illustration](img/git_rebase_v13_5.png)

You can replace `main` with any other branch you want to rebase against, for
example, `release-10-3`. You can also replace `origin` with other remote
repositories, for example, `upstream`. To check what remotes you have linked to your local
repository, you can run `git remote -v`.

If there are merge conflicts, Git prompts you to fix
them before continuing the rebase.

For more information about rebasing, see the [Git documentation](https://git-scm.com/book/en/v2/Git-Branching-Rebasing).
and [rebasing strategies](https://git-scm.com/book/en/v2/Git-Branching-Rebasing).

#### Rebase from the GitLab UI

You can rebase your feature branch directly from the merge request through a
[quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics),
if all of these conditions are met:

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

The user performing the rebase action is considered
a user that added commits to the merge request. When the merge request approvals setting
[**Prevent approvals by users who add commits**](../../user/project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)
is enabled, the user can't also approve the merge request.

### Interactive rebase

You can use interactive rebase to modify commits. For example, amend a commit
message, squash (join multiple commits into one), edit, or delete
commits. Use a rebase for changing past commit messages,
and organizing the commit history of your branch to keep it clean.

NOTE:
Keeping the default branch commit history clean doesn't require you to
manually squash all your commits before merging every merge request.
With [Squash and Merge](../../user/project/merge_requests/squash_and_merge.md),
GitLab does it automatically.

When you want to change anything in recent commits, use interactive
rebase by passing the flag `--interactive` (or `-i`) to the rebase command.

For example, if you want to edit the last three commits in your branch
(`HEAD~3`), run:

```shell
git rebase -i HEAD~3
```

Git opens the last three commits in your terminal text editor and describes
all the interactive rebase options you can use. The default option is `pick`,
which maintains the commit unchanged. Replace the keyword `pick` according to
the operation you want to perform in each commit. To do so, edit
the commits in your terminal's text editor.

For example, with [Vim](https://www.vim.org/) as the text editor in
a macOS Zsh shell, you can `squash` or `fixup` (combine) all three commits:

1. Press <kbd>i</kbd>
   on your keyboard to switch to Vim's editing mode.
1. Use your keyboard arrows to edit the **second** commit keyword
   from `pick` to `squash` or `fixup` (or `s` or `f`). Do the same to the **third** commit.
   The first commit should be left **unchanged** (`pick`) as we want to squash
   the second and third into the first.
1. Press <kbd>Escape</kbd> to leave the editing mode.
1. Type `:wq` to "write" (save) and "quit".
1. When squashing, Git outputs the commit message so you have a chance to edit it:
   - All lines starting with `#` are ignored and not included in the commit
   message. Everything else is included.
   - To leave it as it is, type `:wq`. To edit the commit message: switch to the
   editing mode, edit the commit message, and save it as you just did.
1. If you haven't pushed your commits to the remote branch before rebasing,
   push your changes without force-pushing. If you had pushed these commits already,
   [force-push](#force-push) instead.

The steps for editing through the command line can be slightly
different depending on your operating system and the shell you're using.

See [Numerous undo possibilities in Git](numerous_undo_possibilities_in_git/index.md#undo-staged-local-changes-without-modifying-history)
for a deeper look into interactive rebase.

## Force-push

Complex operations in Git require you to force an update to the remote branch.
Operations like squashing commits, resetting a branch, or rebasing a branch rewrite
the history of your branch. Git requires a forced update to help safeguard against
these more destructive changes from happening accidentally.

Force-pushing is not recommended on shared branches, as you risk destroying the
changes of others.

If the branch you want to force-push is [protected](../../user/project/protected_branches.md),
you can't force push to it unless you either:

- Unprotect it.
- [Allow force-push](../../user/project/protected_branches.md#allow-force-push-on-a-protected-branch)
  to it.

Then you can force-push and protect it again.

### `--force-with-lease` flag

The [`--force-with-lease`](https://git-scm.com/docs/git-push#Documentation/git-push.txt---force-with-leaseltrefnamegt)
flag force-pushes. Because it preserves any new commits added to the remote
branch by other people, it is safer than `--force`:

```shell
git push --force-with-lease origin my-feature-branch
```

### `--force` flag

The `--force` flag force-pushes, but does not preserve any new commits added to
the remote branch by other people. To use this method, pass the flag `--force` or `-f`
to the `push` command:

```shell
git push --force origin my-feature-branch
```
