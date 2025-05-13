---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Configure limits on the number of single push events your instance will allow.
title: Push event activities limit and bulk push events
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Set the number of branches or tags to limit the number of single push events
allowed at once. If the number of events is greater than this value, GitLab creates a
bulk push event instead.

For example, if the limit is three push events, but you push to four branches simultaneously,
the activity feed displays a single {{< icon name="commit">}} `Pushed to 4 branches at (project name)`
event instead of four separate push events. The single push event helps maintain good
system performance, and prevents spam on the activity feed.

To modify this setting from its default value of `3`, either:

- In the [Application settings API](../../api/settings.md#available-settings), set the
  `push_event_activities_limit`.

- In the GitLab UI:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > Network**.
  1. Expand **Performance optimization**.
  1. Edit the **Push event activities limit** setting.
  1. Select **Save changes**.

The value can be greater than or equal to `0`. Setting this value to `0` does not disable throttling.
