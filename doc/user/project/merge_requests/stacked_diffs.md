---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use stacked diffs to create small merge changes that build upon each other to ultimately deliver a feature.
title: Stacked diffs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- Released in [v1.42.0 of the GitLab CLI](https://gitlab.com/gitlab-org/cli/-/releases/v1.42.0) as an [experiment](../../../policy/development_stages_support.md#experiment).

{{< /history >}}

Use stacked diffs in the [GitLab CLI](https://docs.gitlab.com/cli/) to create small changes that
build upon each other to ultimately deliver a feature. Each stack is separate, so you can:

- Continue building new features while earlier changes are reviewed.
- Respond to review feedback on specific diffs without affecting other work.
- Merge diffs independently as they're approved.

The workflow for stacked diffs is:

1. Create changes: When you run `glab stack save`, the GitLab CLI:

   - Stages all your changes.
   - Creates a new commit with your message.
   - Creates a new branch for this commit.
   - Moves you to the new branch automatically.

1. Sync to GitLab: When you run `glab stack sync`, the GitLab CLI:

   - Pushes all branches in your stack to GitLab.
   - Creates a merge request for each diff that doesn't have one yet.
   - Chains the merge requests together. Each merge request, except the first one,
     targets the previous diff branch.

The base command for this feature in the CLI is
[`stack`](https://docs.gitlab.com/cli/stack/), which
you then extend with [other commands](#available-commands).

<div class="video-fallback">
  To learn more, see: <a href="https://www.youtube.com/watch?v=TOQOV8PWYic">Stacked Diffs in the CLI overview</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/TOQOV8PWYic" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-06-18 -->

This feature is an [experiment](../../../policy/development_stages_support.md).
We'd love to hear your feedback in [issue 7473](https://gitlab.com/gitlab-org/cli/-/issues/7473).

## Create a stacked diff

Create a stacked diff when you want to break a large feature into smaller, reviewable changes.

Prerequisites:

- You must have the [GitLab CLI](https://docs.gitlab.com/cli/) installed and authenticated.

To create a stacked diff:

1. In your terminal, create a new stack and give it a name. For example:

   ```shell
   glab stack create add-authentication
   ```

1. Make your first set of changes in your editor.
1. Save your changes as the first diff:

   ```shell
   glab stack save
   ```

   When prompted, enter a commit message that describes this change.

1. Make your next set of changes and save these as a second diff:

   ```shell
   glab stack save
   ```

   Each time you run `glab stack save`, you create a new diff and branch.
   When prompted, enter a commit message that describes this change.

1. When you're ready to push your changes to GitLab and create merge requests, run:

   ```shell
   glab stack sync
   ```

Your merge requests are available for review. You can continue creating more diffs in this stack,
or switch to work on something else.

## Add changes to a diff in a stack

To return to a specific point in the stack to add more changes to it:

1. Display a list of stacks:

   ```shell
   glab stack move
   ```

1. Select the stack you want to edit and press <kbd>Enter</kbd>.
1. Make your changes.
1. When you're ready, save your changes, and run:

   ```shell
   glab stack amend
   ```

1. Optional. Change the description of the stack.
1. Push your changes:

   ```shell
   glab stack sync
   ```

When you sync an existing stack, GitLab:

- Updates the existing stack with your new changes.
- Rebases the other merge requests in the stack to bring in your latest changes.

## Available commands

Use these commands to work with stacked diffs:

| Command                                               | Description |
|-------------------------------------------------------|-------------|
| [`create`](https://docs.gitlab.com/cli/stack/create/) | Create a new stack. |
| [`save`](https://docs.gitlab.com/cli/stack/save/)     | Save your changes as a new diff. |
| [`amend`](https://docs.gitlab.com/cli/stack/amend/)   | Modify the current diff. |
| [`prev`](https://docs.gitlab.com/cli/stack/prev/)     | Move to the previous diff. |
| [`next`](https://docs.gitlab.com/cli/stack/next/)     | Move to the next diff. |
| [`first`](https://docs.gitlab.com/cli/stack/first/)   | Move to the first diff. |
| [`last`](https://docs.gitlab.com/cli/stack/last/)     | Move to the last diff. |
| [`move`](https://docs.gitlab.com/cli/stack/move/)     | Select any diff from a list. |
| [`sync`](https://docs.gitlab.com/cli/stack/sync/)     | Push branches and create/update merge requests. |

### Choose between save and amend

Use the following commands for different purposes:

- `glab stack save`: Creates a new diff (commit and branch). Use this when you're adding
  a new logical change to your stack.
- `glab stack amend`: Modifies the current diff. Use this when responding to review feedback
  or fixing the current change.
