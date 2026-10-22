---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use stacked diffs in the GitLab CLI to split a feature into a series of small, dependent changes.
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

Use stacked diffs in the [GitLab CLI](https://docs.gitlab.com/cli/) to split a feature into
small, dependent changes. Each stack contains diffs. Each diff is a commit on its own branch,
built on the branch of the previous diff.

When you sync the stack, each diff becomes a merge request, and GitLab shows
them as [stacked merge requests](reviews/stacked_merge_requests.md). Reviewers can review and
merge the earlier merge requests while you keep building on top of them.

The workflow for stacked diffs is:

1. Build the stack locally: create a stack, then save each set of changes as a new diff,
   or amend an existing diff as you work.
1. Sync the stack to GitLab: the GitLab CLI pushes your branches and creates or updates
   a merge request for each diff. GitLab chains the merge requests together as stacked
   merge requests. When you merge a merge request and delete its source branch, GitLab
   retargets the merge request above it.

The base command for this feature in the CLI is `glab stack`.
For all subcommands, see the [`glab stack` commands](https://docs.gitlab.com/cli/stack/).

<div class="video-fallback">
  To learn more, see: <a href="https://www.youtube.com/watch?v=TOQOV8PWYic">Stacked Diffs in the CLI overview</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/TOQOV8PWYic" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-06-18 -->

This feature is an [experiment](../../../policy/development_stages_support.md).
We'd love to hear your feedback in [issue 7473](https://gitlab.com/gitlab-org/cli/-/issues/7473).

## Create a stack

Create a stack when you want to break a large feature into smaller, reviewable changes.

Prerequisites:

- You must have the [GitLab CLI](https://docs.gitlab.com/cli/) installed and authenticated.

To create a stack:

1. In your terminal, create a new stack and give it a name. For example:

   ```shell
   glab stack create add-authentication
   ```

   The branch you have checked out becomes the base branch of the stack.
   If the base branch isn't on GitLab yet, push it before you sync the stack.

1. Make your first set of changes in your editor.
1. Save your changes as the first diff:

   ```shell
   glab stack save <file_name>
   ```

   Replace `<file_name>` with the file to include in the diff.
   When prompted, enter a commit message that describes this change.

1. Make your next set of changes and save them as a second diff:

   ```shell
   glab stack save <file_name>
   ```

   Each time you run `glab stack save`, you create a new diff and branch, and check out that branch.
   When prompted, enter a commit message that describes this change.

1. When you're ready to push your changes to GitLab and create merge requests, run:

   ```shell
   glab stack sync
   ```

Your merge requests are available for review. You can continue creating more diffs in this stack,
or switch to work on something else.

## Add changes to a diff in a stack

To return to a specific diff in the stack to add more changes to it:

1. Optional. If the diff is in a different stack, switch to that stack:

   ```shell
   glab stack switch
   ```

1. Display a list of the diffs in the stack:

   ```shell
   glab stack move
   ```

1. Select the diff you want to edit and press <kbd>Enter</kbd>.
1. Make your changes.
1. Add the changes to the diff:

   ```shell
   glab stack amend <file_name>
   ```

   When prompted, keep or update the description of the diff.

1. Push your changes:

   ```shell
   glab stack sync
   ```

When you sync, the GitLab CLI:

- Rebases the diffs after the one you changed.
- Updates the merge requests for the changed diff and the diffs after it.

## Choose between save and amend

Use the following commands for different purposes:

- `glab stack save`: Creates a new diff (commit and branch). Use this when you're adding
  a new logical change to your stack.
- `glab stack amend`: Adds your changes to the diff you have checked out. Use this when
  responding to review feedback or fixing an existing change.

## Related topics

- [Stacked merge requests](reviews/stacked_merge_requests.md)
