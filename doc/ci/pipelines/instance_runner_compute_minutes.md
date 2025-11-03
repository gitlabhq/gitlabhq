---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Compute minutes, purchasing, usage tracking, quota management for instance runners on GitLab.com and GitLab Self-Managed.
title: Compute usage for instance runners
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The amount of compute minute usage that projects can consume to run jobs on admin-managed [instance runners](../runners/runners_scope.md#instance-runners)
is limited. This limit is tracked with an instance runner compute quota on the GitLab server. When a namespace exceeds quota, the [quota is enforced](#enforcement).

Admin-managed instance runners are those [managed by the GitLab instance administrator](../../administration/cicd/compute_minutes.md).

{{< alert type="note" >}}

On GitLab.com instance runners are both admin-managed and GitLab-hosted because the instance is managed by GitLab.

{{< /alert >}}

## Compute quota enforcement

### Monthly reset

Compute minutes usage is reset to `0` monthly.
The compute quota is [reset to the monthly allocation](https://about.gitlab.com/pricing/).

For example, if you have a monthly quota of 10,000 compute minutes:

1. On April 1 you have 10,000 compute minutes available.
1. During April, you use 6,000 of the 10,000 compute minutes available in the quota.
1. On May 1, the accumulated compute usage resets to 0, and you have 10,000
   compute minutes available for May.

Usage data for the previous month is kept to show a historical view of the consumption over time.

### Notifications

An in-app banner is displayed and an email notification sent to the
namespace owners when the remaining compute minutes is:

- Less than 25% of the quota.
- Less than 5% of the quota.
- Completely used (zero minutes remaining).

### Enforcement

When the compute quota is used for the current month, instance runners stop processing new jobs.
In pipelines that have already started:

- Any pending job (not yet started) or retried job that must be processed by instance runners is dropped.
- Jobs running on instance runners can continue to run until the overall namespace usage goes over-quota
  by 1,000 compute minutes. After the 1,000 compute minute grace period, any remaining running jobs
  are also dropped.

Project and group runners are not affected by the compute quota and continue processing jobs.

## View usage

You can view the compute usage for a group or personal namespace to understand
compute usage trends and how many compute minutes remain.

In some cases, the quota limit is replaced by one of the following labels:

- **Unlimited**: For namespaces with unlimited compute quota.
- **Not supported**: For namespaces where instance runners are not enabled.

### View usage for a group

Prerequisites:

- You must have the Owner role for the group.

To view compute usage for your group:

1. On the left sidebar, select **Search or go to** and
   find your group. The group must not be a subgroup.
1. Select **Settings** > **Usage quotas**.
1. Select the **Pipelines** tab.

The projects list shows projects with compute usage or instance runners usage
in the current month only. The list includes all projects in the namespace and its
subgroups, sorted in descending order of compute usage.

### View usage for a personal namespace

You can view the compute usage for your personal namespace:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage quotas**.

The projects list shows [personal projects](../../user/project/working_with_projects.md)
with compute usage or instance runners usage in the current month only.
