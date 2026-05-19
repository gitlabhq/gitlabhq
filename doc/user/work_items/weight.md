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

- Work item weights for epics [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/12273) in GitLab 18.11.

{{< /history >}}

When you have a lot of work items, it can be hard to get an overview.
With weighted work items, you can get a better idea of how much time,
value, or complexity a given work item has or costs. You can also [sort by weight](_index.md#sort-work-items)
to see which work items need to be prioritized.

## View the work item weight

You can view the weight of a work item in the work item page itself or
on several related boards and lists throughout the UI.

To view the work item weight for an individual work item:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select a work item.
1. In the right sidebar, under **Weight**, view the work item weight.

To view work item weights on the **Work items** list:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. In the filter box, select the **Weight** ({{< icon name="weight" >}}) filter and add a value, like `1`.
1. View work items and their weights.

To view the work item weight on an issue board:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Issue boards**.
1. On an individual work item, hover over **Weight** ({{< icon name="weight" >}}) to view the work item weight.

To view the work item weight on the **Milestones** page:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Milestones**.
1. Select a milestone.
1. On the **Milestone** page, in the right sidebar under **Total weight**, view the total sum of work item weights.

## View the work item roll up weight

The work item roll up weight is the sum of all child work item weights rolled
up to their parent.

For example, if a work item has an explicit weight of seven and two child items
with weights of four and five, the roll up weight would be nine.

To view the roll up weight for a work item:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select a parent work item.
1. Next to **Child items**, view the work item roll up **Weight** ({{< icon name="weight" >}}).

On lists and boards, only the directly set weight for a work item is displayed.

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
