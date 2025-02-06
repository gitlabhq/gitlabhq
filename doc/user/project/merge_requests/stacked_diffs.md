---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use stacked diffs to create small merge changes that build upon each other to ultimately deliver a feature."
title: Stacked diffs
---

DETAILS:
**Tier:** Core, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

> - Released in [v1.42.0 of the GitLab CLI](https://gitlab.com/gitlab-org/cli/-/releases/v1.42.0) as an [experiment](../../../policy/development_stages_support.md#experiment).

In the [GitLab CLI](https://gitlab.com/gitlab-org/cli), stacked diffs are a way of
creating small changes that build upon each other to ultimately deliver a feature.
Each stack is separate, so you can keep building your feature in one stack
while previous parts of the stack receive reviews and updates.

The base command for this feature in the CLI is
[`stack`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/stack), which
you then extend with other commands.

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

To do create a stacked diff in the GitLab CLI:

1. In your terminal window, create a new stack with `glab stack create`, and give your stack a name.
1. Make your first set of changes.
1. To save your first set of changes, enter `glab stack save`, then a commit message.
1. Continue creating changes, saving them with `glab stack save`. Each time you
   save a stack, `glab` creates a new branch.
1. To push your changes up to GitLab, enter `glab stack sync`. GitLab creates a
   merge request for each stack.

### Commands that build upon `glab stack`

Use these sub-commands with `glab stack`:

- [`amend`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/amend.md)
- [`create`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/create.md)
- [`first`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/first.md)
- [`last`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/last.md)
- [`move`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/move.md)
- [`next`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/next.md)
- [`prev`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/prev.md)
- [`save`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/save.md)
- [`sync`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/stack/sync.md)

## Add changes to a diff in a stack

To return to a specific point in the stack to add more changes to it:

1. In your terminal window, use the `glab stack move` command. `glab` displays
   a list of stacks.
1. Select the stack you want to edit, and make your changes.
1. When you're ready to save your changes, use the `glab stack amend` command.
1. Optional. Change the description of the stack, if desired.
1. Run `glab stack sync` to push your changes back up to GitLab.

When you sync an existing stack, GitLab:

- Updates the existing stack with your new changes.
- Rebases the other merge requests in the stack to bring in your latest changes.
