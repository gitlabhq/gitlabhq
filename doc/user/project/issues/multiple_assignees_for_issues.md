---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn how to assign multiple people to a single issue in GitLab to clarify ownership, improve collaboration, and track shared responsibilities in large teams.
title: Multiple assignees for issues
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Users on GitLab Free can assign one user to an issue.
Users on GitLab Premium and Ultimate can assign multiple users to an issue.

In large teams with shared ownership, it can be difficult
to track who is working on an issue, who's already done, or who hasn't started yet.

You can add multiple [assignees](managing_issues.md#assignees) to an issue, making it easier to
track, and making it clearer who is accountable for it.

Multiple assignees for issues make collaboration smoother,
and allow shared responsibilities to be clearly displayed.
All assignees are shown across your team's workflows and receive notifications (as they
would as single assignees), simplifying communication and ownership.

After an assignee completes their work, they remove themselves as an assignee, making
it clear that their task is complete.

## Assign multiple users to an issue

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the project.

To assign multiple users to an issue:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Plan** > **Work items**, then filter by **Type** = **Issue** and select your issue.
1. In the right sidebar, in the **Assignees** section, select **Edit**.
1. From the dropdown list, select the users to assign.
   The dropdown list stays open, so you can select more than one user.
1. Select **Apply**, or select any area outside the dropdown list.

GitLab saves your selections only when you close the dropdown list.

You can also use the [`/assign` quick action](../quick_actions.md#assign) to add assignees.

## Remove an assignee

To remove an assignee from an issue:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Plan** > **Work items**, then filter by **Type** = **Issue** and select your issue.
1. In the right sidebar, in the **Assignees** section, select **Edit**.
1. From the dropdown list, clear the user's selection.
1. Select **Apply**, or select any area outside the dropdown list.

You can also use the [`/unassign` quick action](../quick_actions.md#unassign).

## Related topics

- [Assign users to a task](../../tasks.md#assign-users-to-a-task)
- [Issues API](../../../api/issues.md)
