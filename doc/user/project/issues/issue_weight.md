---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Issue weight **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

When you have a lot of issues, it can be hard to get an overview.
With weighted issues, you can get a better idea of how much time,
value, or complexity a given issue has or costs.

## View the issue weight

You can view the issue weight on:

- The right sidebar of each issue.
- The issues page, next to a weight icon (**{weight}**).
- [Issue boards](../issue_board.md), next to a weight icon (**{weight}**).
- The [milestone](../milestones/index.md) page, as a total sum of issue weights.

## Set the issue weight

Prerequisites:

- You must have at least the Reporter role for the project.

You can set the issue weight when you create or edit an issue.

You must enter whole, positive numbers.

When you change the weight of an issue, the new value overwrites the previous value.

### When you create an issue

To set the issue weight when you [create an issue](create_issues.md), enter a
number under **Weight**.

### From an existing issue

To set the issue weight from an existing issue:

1. Go to the issue.
1. On the right sidebar, in the **Weight** section, select **Edit**.
1. Enter the new weight.
1. Select any area outside the dropdown list.

### From an issue board

To set the issue weight when you [edit an issue from an issue board](../issue_board.md#edit-an-issue):

1. Go to your issue board.
1. Select an issue card (not its title).
1. On the right sidebar, in the **Weight** section, select **Edit**.
1. Enter the new weight.
1. Select any area outside the dropdown list.

## Remove issue weight

Prerequisites:

- You must have at least the Reporter role for the project.

To remove the issue weight, follow the same steps as when you [set the issue weight](#set-the-issue-weight),
and select **remove weight**.
