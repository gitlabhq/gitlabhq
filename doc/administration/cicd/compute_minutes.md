---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Calculations, quotas, purchase information.
title: Compute minutes administration
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renamed](https://gitlab.com/groups/gitlab-com/-/epics/2150) from "CI/CD minutes" to "compute quota" or "compute minutes" in GitLab 16.1.

{{< /history >}}

Administrators can limit the amount of time that projects can use to run jobs on
[instance runners](../../ci/runners/runners_scope.md) each month. This limit
is tracked with a [compute minutes quota](../../ci/pipelines/compute_minutes.md).
Group and project runners are not subject to the compute quota.

On GitLab Self-Managed:

- Compute quotas are disabled by default.
- Administrators can [assign more compute minutes](#set-the-compute-quota-for-a-group)
  if a namespace uses all its monthly quota.
- The [cost factor](../../ci/pipelines/compute_minutes.md#compute-usage-calculation) is `1` for all projects.

On GitLab.com:

- To learn about the quotas and cost factors applied, see [compute minutes](../../ci/pipelines/compute_minutes.md).
- To manage compute minutes as a GitLab team member, see [compute minutes administration for GitLab.com](dot_com_compute_minutes.md).

[Trigger jobs](../../ci/yaml/_index.md#trigger) do not execute on runners, so they do not
consume compute minutes, even when using [`strategy:depend`](../../ci/yaml/_index.md#triggerstrategy)
to wait for the [downstream pipeline](../../ci/pipelines/downstream_pipelines.md) status.
The triggered downstream pipeline consumes compute minutes the same as other pipelines.

## Set the compute quota for all namespaces

By default, GitLab instances do not have a compute quota. The default value for the quota is `0`,
which is unlimited.

Prerequisites:

- You must be a GitLab administrator.

To change the default quota that applies to all namespaces:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. In the **Compute quota** box, enter a limit.
1. Select **Save changes**.

If a quota is already defined for a specific namespace, this value does not change that quota.

## Set the compute quota for a group

You can override the global value and set a compute quota for a group.

Prerequisites:

- You must be a GitLab administrator.
- The group must be a top-level group, not a subgroup.

To set a compute quota for a group or namespace:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Groups**.
1. For the group you want to update, select **Edit**.
1. In the **Compute quota** box, enter the maximum number of compute minutes.
1. Select **Save changes**.

You can also use the [update group API](../../api/groups.md#update-group-attributes) or the
[update user API](../../api/users.md#modify-a-user) instead.

## Reset compute usage

An administrator can reset the compute usage for a namespace for the current month.

### Reset usage for a personal namespace

1. Find the [user in the **Admin** area](../admin_area.md#administering-users).
1. Select **Edit**.
1. In **Limits**, select **Reset compute usage**.

### Reset usage for a group namespace

1. Find the [group in the **Admin** area](../admin_area.md#administering-groups).
1. Select **Edit**.
1. In **Permissions and group features**, select **Reset compute usage**.
