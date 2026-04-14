---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Use child items to connect and track relationships between work items in GitLab."
title: Child items
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Child items are work items that are nested under a parent work item. This creates
a hierarchy for organizing and tracking work.

Child items can be:

- A child epic nested under a parent epic.
- An issue such as a feature or bug assigned to an epic.
- A task that can be a child of an issue.

```plaintext
Parent epic
|─ Child epic
   |─ Issue
      |- Task
   |─ Issue
      |- Task
   |─ Issue
  ```

You can use child items to solve several planning and coordination challenges.

The following examples show how child items help teams work together more effectively.

## View all child items assigned to a parent work item

In the Child items section, you can see epics, issues, and tasks assigned to an epic.

You can also see any epics, issues, and tasks inherited by descendant items.

Only epics, issues, and tasks that you can access show on the list.

You can view issues assigned to an epic if they are in the group’s child project.
This is because a project's visibility setting must be the same as, or less
restrictive than, its parent group.

## Track work item progress

You can track the progress of work items using different criteria.

### View count and weight of issues in an epic

In the **Child items** section header of an epic, the number of descendant work items
and their total weight is displayed. Task weights are included in the total issue weight.

To see the number of open and closed work items, in the section header or
under each epic name, hover over the total counts.

The numbers reflect all child work items associated with the epic, including those you might
not have permission to view.

### View epic progress

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5163) in GitLab 17.1.

{{< /history >}}

In the **Child items** section header of an epic, the epic progress percentage is displayed.

To see the completed and total weight of child items, in the section header,
hover over the percentage.

Tasks are included in the progress percentage as part of the child issue percentage.

The weights and progress reflect all issues associated with the epic, including
issues you might not have permission to view.

## Add child items

You can:

- Add existing work items as child items, including work items in a project from
  a different group hierarchy.
- Create a new work item that is automatically added as a child item.

### Add an issue to an epic

{{< history >}}

- Maximum number of child issues and epics [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/452111) to 5000 in GitLab 17.1.

{{< /history >}}

Add an existing issue to an epic, or create a new issue that's automatically
added to the epic.

The maximum number of direct child issues and epics is 5000.

#### Add an existing issue to an epic

You can add existing issues to an epic, including issues in a project from a [different group hierarchy](../group/epics/_index.md#child-issues-from-different-group-hierarchies).

Newly added issues appear at the top of the list of issues in the **Child items** section.

An epic contains a list of issues and an issue can be set as a child item of at most one epic.
When you add a new issue that's already linked to an epic, the issue is automatically unlinked from its
current parent.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the issue's project and the epic's group.

To add an existing issue to an epic:

1. On the epic's page, under **Child items**, select **Add**.
1. Select **Existing issue**.
1. Identify the issue to be added, using either of the following methods:
   - Paste the link of the issue.
   - Search for the desired issue by entering part of the issue's title, then selecting the desired
     match. Issues from different group hierarchies do not appear in search results.
     To add such an issue, enter its full URL.

   If there are multiple issues to be added, press <kbd>Space</kbd> and repeat this step.
1. Select **Add**.

#### Create an issue from an epic

Creating an issue from an epic enables you to maintain focus on the broader context of the epic
while dividing work into smaller parts.

You can create a new issue from an epic only in projects that are in the epic's group or one of its
descendant subgroups.
To create a new issue in a [project that was shared with the epic's group](../project/members/sharing_projects_groups.md),
first [create the issue directly in the project](../project/issues/create_issues.md#from-a-project), and
then [add an existing issue to an epic](#add-an-existing-issue-to-an-epic).

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the issue's project and the epic's group.

To create an issue from an epic:

1. On the epic's page, under **Child items**, select **Add**.
1. Select **Add a new issue**.
1. Under **Title**, enter the title for the new issue.
1. From the **Project** dropdown list, select the project in which the issue should be created.
1. Select **Create issue**.

The new issue is assigned to the epic.

## Reorganize child items

You can reorder child items and reorganize them within the hierarchy.

### Reorder issues assigned to an epic

New issues show at the top of the list in the **Child items** section.
You can reorder the list of issues by dragging them.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the issue's project and the epic's group.

To reorder issues assigned to an epic:

1. Go to the **Child items** section.
1. Drag issues into the desired order.

### Move issues between epics

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

New issues appear at the top of the list in the **Child items**
tab. You can move issues from one epic to another.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the issue's project and the epic's group.

To move an issue to another epic:

1. Go to the **Child items** section.
1. Drag issues into the desired parent epic in the visible hierarchy.

### Moving child items when the parent issue is moved

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371252) in GitLab 16.9 [with a flag](../../administration/feature_flags/_index.md) named `move_issue_children`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/371252) in GitLab 16.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/371252) in GitLab 17.3. Feature flag `move_issue_children` removed.

{{< /history >}}

When you move an issue to another project, all its child items are also moved to the target project
and remain as child items of the moved issue.
Each item is moved the same way as the parent, that is, it's closed in the original project and
copied to the target project.

### Remove an issue from an epic

You can remove issues from an epic when you're on the epic's details page.
After you remove an issue from an epic, the issue is no longer associated with this epic.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the issue's project and the epic's group.

To remove an issue from an epic:

1. Next to the issue you want to remove, select **Remove** ({{< icon name="close" >}}).
   The **Remove issue** warning appears.
1. Select **Remove**.

## Work with multi-level hierarchies

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Epics can contain multiple nested child epics. You can work with these
multi-level child epics in the following ways:

- Create a hierarchy of epics by adding a parent epic to an existing epic.
- Add a child epic that belongs to a group that is different from the parent epic's group.
- View an epic's child epics and related milestones on the roadmap.
- Add, move, reorder, and remove child epics from epics.

Epics can contain multiple nested child epics, up to a total of 7 levels deep.

### Add a parent epic to an epic

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11198) in GitLab 17.5.

{{< /history >}}

To create a hierarchy of epics, add a parent epic to an existing epic.
This helps organize and track related work across multiple epics.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for either the parent epic's group or the child epic's group.

To add a parent epic:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**.
1. Select an epic.
1. In the right sidebar, in the **Parent** section, select **Edit**.
1. In the search box, enter part of the parent epic's title.
   You can only search for epics in the same group hierarchy.
1. From the search results, select the epic you want to add as the parent.

The parent epic is added.

### Child epics from other groups

Add a child epic that belongs to a group that is different from the parent epic's group.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for both the child and parent epics' groups.
- Multi-level child epics must be available for both the child and parent epics' groups.

To add a child epic from another group, paste the epic's URL when [adding an existing epic](#add-a-child-epic-to-an-epic).

### View child epics on a roadmap

From an epic, view its child epics and related milestones on the [roadmap](../group/roadmap/_index.md).

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

To view child epics from the parent:

- In the **Child items** section header, select **Display options** ({{< icon name="preferences" >}}) >
  **View on a roadmap**.

### Add a child epic to an epic

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

#### New epic

To add a new epic as child epic:

1. In an epic, in the **Child items** section, select **Add** > **Add a new epic**.
1. Select a group from the dropdown list. The epic's group is selected by default.
1. Enter a title for the new epic.
1. Select **Create epic**.

#### Existing epic

To add an existing epic as child epic:

1. In an epic, in the **Child items** section, select **Add** > **Existing epic**.
1. Identify the epic to be added, using either of the following methods:
   - Paste the link of the epic.
   - Search for the desired epic by entering part of the epic's title, then
     selecting the desired match. This search is only available for epics in the
     same group hierarchy.

   If there are multiple epics to be added, press <kbd>Space</kbd> and repeat this step.
1. Select **Add**.

### Move child epics between epics

New child epics appear at the top of the list in the **Child items** section.
You can move child epics from one epic to another.
When you add a new epic that's already linked to a parent epic, the link to its current parent is removed.
Issues and child epics cannot be intermingled.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

To move child epics to another epic:

1. Go to the **Child items** section.
1. Drag epics into the desired parent epic.

### Reorder child epics assigned to an epic

New child epics appear at the top of the list in the **Child items** section.
You can reorder the list of child epics.

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

To reorder child epics assigned to an epic:

1. Go to the **Child items** section.
1. Drag epics into the desired order.

### Remove a child epic from a parent epic

Prerequisites:

- You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

To remove a child epic from a parent epic:

1. Select **Remove** ({{< icon name="close" >}}) in the parent epic's list of epics.
   The **Remove epic** warning appears.
1. Select **Remove**.

## Configure child item display preferences

You can configure what information is displayed in the **Child items** section, so that you can focus on what matters most for your workflow.

{{< history >}}

- Display options for child items [expanded](https://gitlab.com/gitlab-org/gitlab/-/work_items/551231) in GitLab 18.10.

{{< /history >}}

You can configure what information is displayed in the **Child items** section,
so that you can focus on what matters most for your workflow.

> [!note]
> When you change the information displayed in one epic or issue, you change it for all work items in your groups and projects.

1. At the top-right corner of the **Child items** section header, select
   **Display options** ({{< icon name="preferences" >}}).

   By default, all options and fields are visible.
1. To change the displayed information, turn the following toggles on or off:

   - For display options:
     - **Show closed items**
   - For fields displayed:
     - **Status**
     - **Assignee**
     - **Labels**
     - **Weight**
     - **Milestone**
     - **Iteration**
     - **Dates**
     - **Health**
     - **Blocked/Blocking**

## Related topics

- [Manage epics](../group/epics/manage_epics.md)
- [Manage issues](../project/issues/managing_issues.md)
