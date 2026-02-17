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
{{< icon name="commit" >}} `Pushed to 4 branches at (project name)` event instead of four separate
push events.

Bulk push events behave differently from standard push events:

- Activity feed: A single bulk push entry appears instead of individual push events.
- Events API: Returns bulk push events with `commit_count: 0` and `ref_count` that shows the
  number of refs pushed. Individual commit details (`commit_from`, `commit_to`, `ref`,
  `commit_title`) are `null`.

If your integrations or external systems must process every pushed ref individually:

- Keep the number of refs per push below the `push_event_activities_limit`.
- Split large pushes into multiple smaller pushes.

> [!note]
> Webhook triggering is controlled separately by the `push_event_hooks_limit` setting.
> For more information, see [Push event limits](../../user/project/integrations/webhooks.md#push-event-limits).

Prerequisites:

- Administrator access.

To set a different **Push event activities limit**, either:

- In the [Application settings API](../../api/settings.md#available-settings), set the
  `push_event_activities_limit`.

- In the GitLab UI:
  1. In the upper-right corner, select **Admin**.
  1. On the left sidebar, select **Settings** > **Network**.
  1. Expand **Performance optimization**.
  1. Edit the **Push event activities limit** setting.
  1. Select **Save changes**.

The value can be greater than or equal to `0`. Setting this value to `0` does not disable throttling.
