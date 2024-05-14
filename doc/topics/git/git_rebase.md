---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Introduction to Git rebase and force push, methods to resolve merge conflicts through the command line."
---

# Git rebase and force push

In Git, a rebase updates your branch with the contents of another branch.
A rebase confirms that changes in your branch don't conflict with
changes in the target branch.

If you have a [merge conflict](../../user/project/merge_requests/conflicts.md),
you can rebase to fix it.

## What happens during rebase

When you rebase:

1. Git imports all the commits submitted to your target branch after you initially created
   your branch from it.
1. Git stacks the commits you have in your branch on top of all
   the commits it imported from that branch:

   ![Git rebase illustration](img/git_rebase_v13_5.png)

While most rebases are performed against `main`, you can rebase against any other
branch, such as `release-15-3`. You can also specify a different remote repository
(such as `upstream`) instead of `origin`.

WARNING:
`git rebase` rewrites the commit history. It **can be harmful** to do it in
shared branches. It can cause complex and hard to resolve
merge conflicts. Instead of rebasing your branch against the default branch,
consider pulling it instead (`git pull origin master`). Pulling has similar
effects with less risk of compromising others' work.

## Rebase by using Git

When you use Git to rebase, each commit is applied to your branch.
When merge conflicts occur, you are prompted to address them.

If you want more advanced options for your commits,
do [an interactive rebase](#rebase-interactively-by-using-git).

Prerequisites:

- You must have permission to force push to branches.

To use Git to rebase your branch against the target branch:

1. Open a terminal and change to your project.
1. Ensure you have the latest contents of the target branch.
   In this example, the target branch is `main`:

   ```shell
   git fetch origin main
   ```

1. Check out your branch:

   ```shell
   git checkout my-branch
   ```

1. Optional. Create a backup of your branch:

   ```shell
   git branch my-branch-backup
   ```

   Changes added to `my-branch` after this point are lost
   if you restore from the backup branch.

1. Rebase against the main branch:

   ```shell
   git rebase origin/main
   ```

1. If merge conflicts exist:
   1. Fix the conflicts in your editor.

   1. Add the files:

      ```shell
      git add .
      ```

   1. Continue the rebase:

      ```shell
      git rebase --continue
      ```

1. Force push your changes to the target branch, while protecting others' commits:

   ```shell
   git push origin my-branch --force-with-lease
   ```

## Rebase from the UI

You can rebase a merge request from the GitLab UI.

Prerequisites:

- No merge conflicts must exist.
- You must have at least the **Developer** role for the source project. This role grants you
  permission to push to the source branch for the source project.
- If the merge request is in a fork, the fork must allow commits
  [from members of the upstream project](../../user/project/merge_requests/allow_collaboration.md).

To rebase from the UI:

1. Go to your merge request.
1. Type `/rebase` in a comment.
1. Select **Comment**.

GitLab schedules a rebase of the branch against the default branch and
executes it as soon as possible.

## Rebase interactively by using Git

Use an interactive rebase when you want to specify how to handle each commit.
You must do an interactive rebase from the command line.

Prerequisites:

- [Vim](https://www.vim.org/) must be your text editor to follow these instructions.

To rebase interactively:

1. Open a terminal and change to your project.
1. Ensure you have the latest contents of the target branch.
   In this example, the target branch is `main`:

   ```shell
   git fetch origin main
   ```

1. Check out your branch:

   ```shell
   git checkout my-branch
   ```

1. Optional. Create a backup of your branch:

   ```shell
   git branch my-branch-backup
   ```

   Changes added to `my-branch` after this point are lost
   if you restore from the backup branch.

1. In the GitLab UI, in your merge request, confirm how many commits
   you want to rebase by viewing the **Commits** tab.

1. Open these commits. For example, to edit the last five commits in your branch (`HEAD~5`), type:

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

1. Switch to Vim's edit mode by pressing <kbd>i</kbd>.
1. Move to the second commit in the list by using your keyboard arrows.
1. Change the word `pick` to `squash` or `fixup` (or `s` or `f`).
1. Do the same for the remaining commits. Leave the first commit as `pick`.
1. End edit mode, save, and quit:

   - Press <kbd>ESC</kbd>.
   - Type `:wq`.

1. When squashing, Git outputs the commit message so you have a chance to edit it:

   - All lines starting with `#` are ignored and not included in the commit
     message. Everything else is included.
   - To leave it as-is, type `:wq`. To edit the commit message, switch to
     edit mode, edit the commit message, and save.

1. Commit to the target branch.

   - If you didn't push your commits to the target branch before rebasing,
     push your changes without a force push:

     ```shell
     git push origin my-branch
     ```

   - If you pushed these commits already, use a force push:

     ```shell
     git push origin my-branch --force-with-lease
     ```

## Force pushing

Complex operations in Git require you to force an update to the remote branch.
Operations like squashing commits, resetting a branch, or rebasing a branch rewrite
the history of your branch. Git requires a forced update to help safeguard against
these more destructive changes from happening accidentally.

Force pushing is not recommended on shared branches, because you risk destroying
others' changes.

If the branch you want to force push is [protected](../../user/project/protected_branches.md),
you can't force push to it unless you either:

- Unprotect it.
- [Allow force pushes](../../user/project/protected_branches.md#allow-force-push-on-a-protected-branch)
  to it.

Then you can force push and protect it again.

## Restore your backed up branch

Your branch is backed up, and you can try a rebase or a force push.
If anything goes wrong, restore your branch from its backup:

1. Make sure you're in the correct branch:

   ```shell
   git checkout my-branch
   ```

1. Reset your branch against the backup:

   ```shell
   git reset --hard my-branch-backup
   ```

## Approving after rebase

If you rebase a branch, you've added commits.
If your project is configured to
[prevent approvals by users who add commits](../../user/project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits),
you can't approve a merge request if you have rebased it.

## Related topics

- [Numerous undo possibilities in Git](undo.md#undo-staged-local-changes-without-modifying-history)
- [Git documentation for branches and rebases](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
- [Project squash and merge settings](../../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)

## Troubleshooting

### `Unmergeable state` after `/rebase` quick action

The `/rebase` command schedules a background task. The task attempts to rebase
the changes in the source branch on the latest commit of the target branch.
If, after using the `/rebase`
[quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics),
you see this error, a rebase cannot be scheduled:

```plaintext
This merge request is currently in an unmergeable state, and cannot be rebased.
```

This error occurs if any of these conditions are true:

- Conflicts exist between the source and target branches.
- The source branch contains no commits.
- Either the source or target branch does not exist.
- An error has occurred, resulting in no diff being generated.

To resolve the `unmergeable state` error:

1. Resolve any merge conflicts.
1. Confirm the source branch exists, and has commits.
1. Confirm the target branch exists.
1. Confirm the diff has been generated.

### `/merge` quick action ignored after `/rebase`

If `/rebase` is used, `/merge` is ignored to avoid a race condition where the source branch is merged or deleted before it is rebased.
