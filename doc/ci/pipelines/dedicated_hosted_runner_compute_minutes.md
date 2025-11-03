---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Compute minutes, usage tracking, quota management for GitLab-hosted runners on GitLab Dedicated.
title: Compute usage for GitLab-hosted runners on GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

A GitLab Dedicated instance can have both GitLab Self-Managed instance runners and GitLab-hosted instance runners.

As an administrator of a GitLab Dedicated instance, you can track and monitor compute minutes used by
namespaces running jobs on either type of instance runners.

For GitLab-hosted runners:

- You can view your estimated usage in the [GitLab-hosted runner usage dashboard](#view-compute-usage).
- Quota enforcement and notifications are not available.

For GitLab Self-Managed instance runners registered to your GitLab Dedicated instance, see [view instance runner usage](instance_runner_compute_minutes.md#view-usage).

## View compute usage

{{< history >}}

- Compute usage data for GitLab-hosted runners [introduced](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524) in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must be an administrator for a GitLab Dedicated instance.

You can see compute usage:

- Total compute usage for the current month.
- By month, which you can filter by year and runner.
- By namespace, which you can filter by month and runner.

To view GitLab-hosted runner compute usage for all namespaces across your entire GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Usage quotas**.
