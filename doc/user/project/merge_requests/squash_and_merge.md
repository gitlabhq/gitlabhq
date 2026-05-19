---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand and configure the commit squashing options available in GitLab.
title: Squash and merge
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Squash and merge combines multiple small commits into a single meaningful commit.
This strategy keeps your repository history clean and makes it easier to track or revert changes.
When you work on multiple features at once, squashing separates each feature's changes into distinct, logical units.

- Small commits are joined together, making it simpler to [revert all parts of a change](revert_changes.md).
- When the single commit merges into the target branch, it retains the full commit history.
- Your base branch remains clean, and contains meaningful commit messages.

## Squash and merge workflow

Each time a branch merges into your base branch, up to two commits are added:

- The single commit created by squashing the commits from the branch.
- A merge commit, unless you have enabled
  [fast-forward merges](methods/_index.md#fast-forward-merge) in your project.
  Fast-forward merges prevent the creation of additional merge commits, but
  you can still squash the commits from your branch into a single commit.

By default, squashed commits contain the following metadata:

- Message: Description of the squash commit, or a customized message
- Author: User that created the merge request
- Committer: User who initiated the squash

Project owners can [create new default messages](commit_templates.md) for all
squash commits and merge commits.

## Set default squash options for a merge request

Users with permission to create or edit a merge request can set the default squash options
for a merge request.

Prerequisites:

- Your project must be [configured](#configure-squash-options-for-a-project) to allow or
  encourage squashing.

To do this:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Select **Edit**.
1. Select or clear the **Squash commits when merge request is accepted** checkbox.
1. Select **Save changes**.

## Squash commits in a merge request

If your project allows you to select squashing options for merge requests, to
squash the commits as part of the merge process:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. In the merge request widget, ensure the **Squash commits** checkbox is selected. This checkbox doesn't display
   if the project's squashing option is set to either **Do not allow** or **Require**.
1. Optional. To modify either the squash commit message or the merge commit message
   (depending on your project configuration), select **Modify commit messages**.
1. When the merge request is ready to merge, select **Merge**.

## Configure squash options for a project

Prerequisites:

- You must have the Maintainer or Owner role for this project.

To configure the default squashing behavior for all merge requests in your project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Merge requests**.
1. In the **Squash commits when merging** section, select your desired behavior:
   - **Do not allow**: Squashing is never performed, and the option is not displayed.
   - **Allow**: Squashing is allowed, but cleared by default.
   - **Encourage**: Squashing is allowed and selected by default, but can be disabled.
   - **Require**: Squashing is always performed. While merge requests display the option
     to squash, users cannot change it.
1. Select **Save changes**.

## Long-running branch behavior

You should not squash and merge long-running branches. Instead, use a
[merge method](methods/_index.md) that preserves the original commit history,
such as merge commits or fast-forward merges.

When you squash and merge a branch that continues to receive new commits, the branch history
diverges from the target branch. Squashing creates a single new commit on the target branch
with a different SHA. If you continue working on the source branch without rebasing or merging
the target branch back in, Git treats the histories as diverged.

When you open a new merge request from that source branch, you see the following:

- Commits that were already merged in the previous merge request.
- A warning that the source branch is behind the target branch.

The diff correctly shows only the new changes not yet in the target branch.

To keep a long-running branch in sync with its target after a squash merge:

- Rebase the source branch off the target branch after each merge.
- Merge the target branch back into the source branch after each merge.

## Related topics

- [Commit message templates](commit_templates.md)
- [Merge methods](methods/_index.md)
