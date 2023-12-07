---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Cherry-pick a Git commit **(FREE ALL)**

In Git, you can *cherry-pick* a commit (a set of changes) from an existing branch,
and apply those changes to another branch. Cherry-picks can help you:

- Backport bug fixes from the default branch to previous release branches.
- Copy changes from a fork
  [to the upstream repository](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-into-a-project).

You can cherry-pick commits from the command line. In the GitLab user interface,
you can also:

- Cherry-pick [all changes from a merge request](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-all-changes-from-a-merge-request).
- Cherry-pick [a single commit](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-a-single-commit).
- Cherry-pick [from a fork to the upstream repository](../../user/project/merge_requests/cherry_pick_changes.md#cherry-pick-into-a-project).

## Cherry-pick from the command line

These instructions explain how to cherry-pick a commit from the default branch (`main`)
into a different branch (`stable`):

1. Check out the default branch, then check out a new `stable` branch based on it:

   ```shell
   git checkout main
   git checkout -b stable
   ```

1. Change back to the default branch:

   ```shell
   git checkout main
   ```

1. Make your changes, then commit them:

   ```shell
   git add changed_file.rb
   git commit -m 'Fix bugs in changed_file.rb'
   ```

1. Display the commit log:

   ```shell
   $ git log

   commit 0000011111222223333344444555556666677777
   Merge: 88888999999 aaaaabbbbbb
   Author: user@example.com
   Date:   Tue Aug 31 21:19:41 2021 +0000
   ```

1. Identify the `commit` line, and copy the string of letters and numbers on that line.
   This information is the SHA (Secure Hash Algorithm) of the commit. The SHA is
   a unique identifier for this commit, and you need it in a future step.

1. Now that you know the SHA, check out the `stable` branch again:

   ```shell
   git checkout stable
   ```

1. Cherry-pick the commit into the `stable` branch, and change `SHA` to your commit
   SHA:

   ```shell
   git cherry-pick <SHA>
   ```

## Related topics

- Cherry-pick commits with [the Commits API](../../api/commits.md#cherry-pick-a-commit)
- Git documentation [for cherry-picks](https://git-scm.com/docs/git-cherry-pick)
