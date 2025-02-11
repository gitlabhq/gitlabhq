---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure limits on the number of single push events your instance will allow."
title: Push event activities limit and bulk push events
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Set the number of branches or tags to limit the number of single push events
allowed at once. If the number of events is greater than this, GitLab creates
bulk push event instead.

For example, if 4 branches are pushed and the limit is set to 3,
the activity feed displays:

![The activity feed, showing a push to 4 branches with a single event.](img/bulk_push_event_v12_4.png)

With this feature, a single push changing 1,000 branches creates one bulk push event
instead of 1,000 push events. This helps maintain good system performance and prevents spam on
the activity feed.

To modify this setting:

- In the **Admin** area:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. Select **Settings > Network**.
  1. Expand **Performance optimization**.
  1. Edit the **Push event activities limit** setting.
- Through the [Application settings API](../../api/settings.md#available-settings)
  as `push_event_activities_limit`.

The default value is `3`, but the value can be greater than or equal to `0`. Setting this value to `0` does not disable throttling.
