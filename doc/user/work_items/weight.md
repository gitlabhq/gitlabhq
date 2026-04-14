---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Assign a numerical weight to GitLab work items to represent their estimated effort, value, or complexity and help with planning and prioritization.
title: Work item weight
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced for epics](https://gitlab.com/groups/gitlab-org/-/work_items/12273) in GitLab 18.11.

{{< /history >}}

When you have a lot of work items, it can be hard to get an overview.
With weighted work items, you can get a better idea of how much time,
value, or complexity a given work item has or costs. You can also [sort by weight](_index.md#sort-work-items)
to see which work items need to be prioritized.

## View the work item weight

You can view the work item weight on:

- The right sidebar of each work item.
- The [work items list](_index.md#view-all-work-items), next to a weight icon ({{< icon name="weight" >}}).
- [Issue boards](../project/issue_board.md), next to a weight icon ({{< icon name="weight" >}}).
- The [milestone](../project/milestones/_index.md) page, as a total sum of work item weights.

## Set the work item weight

{{< history >}}

- Minimum role to set work item weight [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the parent project or group.

The following apply:

- You can set the work item weight when you create or edit a work item.
- You must enter whole, positive numbers.
- When you change the weight of a work item, the new value overwrites the previous value.

### When you create a work item

To set the work item weight when you create a work item, enter a
number under **Weight**.

### From an existing work item

To set the work item weight from an existing work item:

1. Go to the work item.
1. In the right sidebar, in the **Weight** section, select **Edit**.
1. Enter the new weight.
1. Select any area outside the dropdown list.

### From an issue board

To set the issue weight when you [edit an issue from an issue board](../project/issue_board.md#edit-an-issue):

1. Go to your issue board.
1. Select an issue card (not its title).
1. In the right sidebar, in the **Weight** section, select **Edit**.
1. Enter the new weight.
1. Select any area outside the dropdown list.

## Remove work item weight

{{< history >}}

- Minimum role to remove work item weight [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the parent project or group.

To remove the work item weight, follow the same steps as when you [set the work item weight](#set-the-work-item-weight),
and select **remove weight**.
