---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Configure limits on the number of single push events your instance allows.
title: Push event activities limit and bulk push events
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To maintain good system performance and prevent spam on the activity feed, set a **Push event activities limit**.
By default, GitLab sets this limit to `3`. When you push changes that affect more than 3 branches and tags,
GitLab creates a bulk push event instead of individual push events.

For example, if you push to four branches simultaneously, the activity feed displays a single
{{< icon name="commit">}} `Pushed to 4 branches at (project name)` event instead of four separate
push events.

To set a different **Push event activities limit**, either:

- In the [Application settings API](../../api/settings.md#available-settings), set the
  `push_event_activities_limit`.

- In the GitLab UI:
  1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
  1. On the left sidebar, select **Settings** > **Network**.
  1. Expand **Performance optimization**.
  1. Edit the **Push event activities limit** setting.
  1. Select **Save changes**.

The value can be greater than or equal to `0`. Setting this value to `0` does not disable throttling.
