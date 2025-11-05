---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "A specific step in a work item's workflow ('In progress', 'Done', 'Won't do') that belongs to a category and maps to a binary state (open/closed)."
title: Status
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/543862) in GitLab 18.2 [with a flag](../../administration/feature_flags/_index.md) named `work_item_status_feature_flag`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/521286) in GitLab 18.4. Feature flag `work_item_status_feature_flag` removed.

{{< /history >}}

<!-- Turn off the future tense test because of "won't do". -->
<!-- vale gitlab_base.FutureTense = NO -->

Work item status represents a specific step in a work item's workflow, such as **In progress**, **Done**, or **Won't do**.
Status provides more granular tracking than the traditional binary open/closed state system used in GitLab Free.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview, see [Configurable Status for Issues and Tasks - Complete Walkthrough (GitLab 18.2)](https://www.youtube.com/watch?v=oxN95MSo6UU).
<!-- Video published on 2025-07-11 -->

Use status to:

- Track work items through different stages of completion.
- Provide clearer visibility into work item progress.
- Replace the need for labels to manage work item lifecycles.
- Standardize workflows across teams and projects.

Status is available for tasks and issues.
For information on plans to add status to epics and other work item types, see [epic 5099](https://gitlab.com/groups/gitlab-org/-/epics/5099).

## Default statuses

GitLab provides default statuses to get you started with work item tracking.
These statuses cannot be modified.

The default statuses are:

- **To do**: Work item is ready to be started.
- **In progress**: Work item is being actively worked on.
- **Done**: Work item has been completed.
- **Won't do**: Work item will not be completed.
- **Duplicate**: Work item is a duplicate of another item.

## Status categories

Status categories are logical groupings that determine how a status affects a work item's state and icon. Each status belongs to one of five categories:

- **Triage**: For new or unprocessed work items.
- **To do**: For work items ready to be started.
- **In progress**: For work items being actively worked on.
- **Done**: For completed work items.
- **Canceled**: For work items that won't be completed.

Statuses in the **Done** and **Canceled** categories automatically set work items to closed state. All other categories maintain work items in open state.

<!-- vale gitlab_base.FutureTense = YES -->

## Lifecycles

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/556113) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `work_item_status_mvc2`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/576610) in GitLab 18.6. Feature flag `work_item_status_mvc2` removed.

{{< /history >}}

A lifecycle is a collection of statuses that can be applied to a work item type. Lifecycles group statuses into meaningful workflows that can be reused consistently across work item types and namespaces.

Each lifecycle defines default transition statuses:

- **Default open status**: Applied when creating and reopening work items.
- **Default closed status**: Applied when closing work items.
- **Default duplicated status**: Applied when marking work items as duplicates, moved, or promoted.

### Create a lifecycle

Prerequisites:

- You must have at least the Maintainer role for the group.
- This group must be at the top level.

To create a lifecycle:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Issues**.
1. In the **Statuses** section, select **Create lifecycle**.
1. Add the lifecycle name and choose either the default lifecycle configuration or one of the existing lifecycles to start from. This pre-populates the new lifecycle with statuses which you can customize afterwards.
1. Select **Create**.

### Rename a lifecycle

Prerequisites:

- You must have at least the Maintainer role for the group.
- This group must be at the top level.

To rename a lifecycle:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Issues**.
1. In the **Statuses** section, hover over the lifecycle detail view.
1. Select **Rename**.
1. Rename the lifecycle and select **Save**.

### Remove a lifecycle

Prerequisites:

- You must have at least the Maintainer role for the group.
- This group must be at the top level.
- The lifecycle must not be in use i.e., should not be associated with any work item type

To remove a lifecycle:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Issues**.
1. In the **Statuses** section, select **Remove lifecycle** for the lifecycle you want to remove.
1. On the confirmation dialog, select **Remove**.

### Change lifecycle for a work item type

Prerequisites:

- You must have at least the Maintainer role for the group.
- This group must be at the top level.

To change the lifecycle for a work item type:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Issues**.
1. In the **Statuses** section, either:
   - Select **Change lifecycle**.
   - If the lifecycle is used with more than one work item type, select it from the dropdown list.
1. Select a new lifecycle for the work item type. You can either choose an existing lifecycle or create a new lifecycle.
1. Select **Next**.

   All current statuses show which new status from the new lifecycle they get.

1. Optional. To choose a different replacement status, select it from the dropdown list.
1. Select **Save**.

## Custom statuses

Custom statuses are namespace-defined statuses that replace default statuses for all groups and projects in that namespace.
When you edit a lifecycle, custom statuses replace the default statuses for that namespace.

Custom statuses have the following limits:

- Maximum 70 statuses per namespace
- Maximum 30 statuses per lifecycle

### Configure custom statuses for a namespace

Configure custom statuses for top-level groups to make them available for work items in that group, its subgroups, and projects.

Prerequisites:

- You must have at least the Maintainer role for the group.
- This group must be at the top level.

To configure custom statuses:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Issues**.
1. In the **Statuses** section, select **Edit statuses** for the lifecycle being used by the work item type.
1. Add, edit, or reorder statuses for the namespace.
1. Select **Close**.

### Set status for a work item

Prerequisites:

- You must have at least the Planner role for the work item's project or group, be the author of the work item, or be assigned to the work item.

To set a status for a work item:

1. Go to an issue or task.
1. On the right sidebar, in the **Status** section, select **Edit**.
1. Select the desired status.
1. Select any area outside the dropdown list.

The work item's status updates immediately.
