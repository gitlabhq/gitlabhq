---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Manage epics
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This page collects instructions for all the things you can do with [epics](_index.md)
or in relation to them.

For information on managing child items of an epic, see [child items](../../work_items/child_items.md).

## Create an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.
- Assigning milestones to epics [introduced](https://gitlab.com/groups/gitlab-org/-/epics/329) in GitLab 18.2.
- Assigning weight to epics [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/12273) in GitLab 18.11.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To create an epic in the group you're in:

1. Get to the New Epic form:
   - Go to your group and from the left sidebar select **Work items**. Then select **New item**.
   - From an epic in your group, in the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}). Then select **New related item**.
   - From anywhere, in the top menu, select **New** ({{< icon name="plus-square" >}}). Then select **New work item**.
   - In an empty [roadmap](../roadmap/_index.md), select **New work item**.

1. From the **Type** dropdown list, select **Epic** if it is not already selected.
1. Complete the fields.
   - Enter a title.
   - Enter a description.
   - To [make the epic confidential](#make-an-epic-confidential), select the checkbox next to **Turn on confidentiality**.
   - Choose labels.
   - Select a start and due date, or [inherit](#start-and-due-date-inheritance) them.
   - Select a [color](#epic-color).
1. Select **Create epic**.

The newly created epic opens.

### Start and due date inheritance

If you select **Inherited**:

- For the **start date**: GitLab scans all child epics and issues assigned to the epic,
  and sets the start date to match the earliest start date found in the child epics or the milestone
  assigned to the child items.
- For the **due date**: GitLab scans all child epics and issues assigned to the epic,
  and sets the due date to match the latest due date found in the child epics or the milestone
  assigned to the child items.

These dates are dynamic and recalculated if any of the following occur:

- A child epic's dates change.
- Milestones are reassigned to an issue.
- A milestone's dates change.
- Issues are added to, or removed from, the epic.

Because the epic's dates can inherit dates from its children, the start date and due date propagate from the bottom to the top.
If the start date of a child epic on the lowest level changes, that becomes the earliest possible start date for its parent epic.
The parent epic's start date then reflects this change and propagates upwards to the top epic.

## Edit an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

After you create an epic, you can edit the following details:

- Title
- Description
- Start date
- Due date
- Labels
- Milestone
- [Color](#epic-color)

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To edit an epic's title or description:

1. Select **Edit**.
1. Make your changes.
1. Select **Save changes**.

To edit an epic's start date, due date, milestone, or labels:

1. Next to each section in the right sidebar, select **Edit**.
1. Select the dates, milestone, or labels for your epic.

### Reorder list items in the epic description

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

When you view an epic that has a list in the description, you can also reorder the list items.

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the project, be the author of the epic, or be
  assigned to the epic.
- The epic's description must have an [ordered, unordered](../../markdown.md#lists), or
  [task](../../markdown.md#task-lists) list.

To reorder list items, when viewing an epic:

1. Hover over the list item row to make the grip icon ({{< icon name="grip" >}}) visible.
1. Select and hold the grip icon.
1. Drag the row to the new position in the list.
1. Release the grip icon.

### Bulk edit epics

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200186) more bulk editing attributes in GitLab 18.3.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204037) bulk editing support for parent attribute in GitLab 18.5.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the parent epic's group.

To update multiple epics at the same time:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.
1. Select **Bulk edit**. On the right, a sidebar with editable fields appears.
1. Select the checkboxes next to each epic you want to edit.
1. From the sidebar, edit the available fields.
1. Select **Update selected**.

When bulk editing epics in a group, you can edit the following attributes:

- State (open or closed)
- [Assignees](#assignees)
- [Labels](../../project/labels.md)
- [Health status](#health-status)
- [Notification](../../profile/notifications.md) subscription
- [Confidentiality](#make-an-epic-confidential)
- [Milestone](../../project/milestones/_index.md)
- [Parent](../../work_items/child_items.md#add-a-parent-epic-to-an-epic)

## Prevent truncating descriptions with **Read more**

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) in GitLab 17.10.

{{< /history >}}

If an epic description is long, GitLab displays only part of it.
To see the whole description, you must select **Read more**.
This truncation makes it easier to find other elements on the page without scrolling through lengthy text.

To change whether descriptions are truncated:

1. On an epic, in the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}).
1. Toggle **Truncate descriptions** according to your preference.

This setting is remembered and affects all issues, tasks, epics, objectives, and key results.

## Hide the right sidebar

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) in GitLab 17.10.

{{< /history >}}

Epic attributes are shown in a sidebar to the right of the description when space allows.

To hide the sidebar and increase space for the description:

1. On an epic, in the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}).
1. Select **Hide sidebar**.

This setting is remembered and affects all issues, tasks, epics, objectives, and key results.

To show the sidebar again:

- Repeat the previous steps and select **Show sidebar**.

## Assignees

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4231) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `work_items_beta`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/551805) in GitLab 18.2. Moved from behind feature flag `work_items_beta`.

{{< /history >}}

An epic can be assigned to one or more users.

The assignees can be changed as often as needed.
The idea is that the assignees are people responsible for the epic.

If a user is not a member of a group, an epic can only be assigned to them if another group member
assigns them.

### Change assignee on an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To change the assignee on an epic:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.
1. Select your epic to view it.
1. In the right sidebar, in the **Assignees** section, select **Edit**.
1. From the dropdown list, select the users to add as an assignee.
1. Select any area outside the dropdown list.

The assignee is changed without having to refresh the page.

## Epic color

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79940) in GitLab 14.9 [with a flag](../../../administration/feature_flags/_index.md) named `epic_color_highlight`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/365336) in GitLab 16.11. Feature flag `epic_color_highlight` removed.
- Customizable color [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394864) in GitLab 17.5.

{{< /history >}}

You can set a color for an epic to categorize and prioritize tasks visually.
Use colors to:

- Associate epics with teams or company initiatives.
- Indicate levels in the epic hierarchy.
- Group related epics together.

Epic colors are visible in [roadmaps](../roadmap/_index.md) and [epic boards](epic_boards.md).

On roadmaps, the timeline bars match the epic's color:

![Epics differentiated by color in v17.0](img/epic_color_roadmap_v17_0.png)

On epic boards, the color shows on the epic's card accent:

![Cards accented with their associated epic color in v17.0](img/epic_accent_boards_v17_0.png)

### Change an epic's color

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To change an epic's color:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.
1. Select an epic.
1. In the right sidebar, in the **Color** section, select **Edit**.
1. Select an existing color or enter an RGB or hex value.
1. Select any area outside the dialog.

The epic's color is updated.

## Delete an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/452189) in GitLab 16.11. In GitLab 16.10 and earlier, if you delete an epic, all its child epics and their descendants are deleted as well. If needed, you can [remove child epics](../../work_items/child_items.md#remove-a-child-epic-from-a-parent-epic) from the parent epic before you delete it.
- [Allowed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) Planner role to delete an epic in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner or Owner role for the epic's group.

To delete an epic:

1. In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}), then **Delete epic**.
1. Select **Delete**. On the confirmation dialog, select **Delete epic**.

Deleting an epic releases all existing issues from their associated epic in the system.

## Close an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To close an epic:

- In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}), then **Close epic**.

You can also use the [`/close` quick action](../../project/quick_actions.md#close).

## Reopen a closed epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

You can reopen an epic that was closed.

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To do so, either:

- In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}) and then **Reopen epic**.
- Use the [`/reopen` quick action](../../project/quick_actions.md#reopen).

You can also create an epic by
[promoting an issue](../../project/issues/managing_issues.md#promote-an-issue-to-an-epic).

## Go to an epic from an issue

If an issue belongs to an epic, you can go to the parent epic from:

- Breadcrumbs at the top of the issue.
- The **Parent** section in the right sidebar.

## View epics list

Prerequisites:

- You must be a member of either:
  - The group
  - A project in the group
  - A project in one of the group's subgroups

To view epics in a group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.

To set which attributes are shown for epics on the epics list, [configure display preferences](../../work_items/_index.md#configure-list-display-preferences).

### Who can view an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Whether you can view an epic depends on the [group visibility level](../../public_access.md) and
the epic's [confidentiality status](#make-an-epic-confidential):

- Public group and a non-confidential epic: Anyone can view the epic.
- Private group and non-confidential epic: You must have the Guest, Planner, Reporter, Developer, Maintainer, or Owner role for the group, or be a member of a project in the group or one of its subgroups.
- Confidential epic (regardless of group visibility): You must have at least the Planner
  role for the group.

### Open epics in a drawer

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464698) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `work_item_view_for_issues`. Enabled by default.
- Toggling between drawer and full page view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536620) in GitLab 18.2.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/500367) in GitLab 18.6. Feature flag `epics_list_drawer` removed.

{{< /history >}}

When you select an epic from the work items page or an epic board, it opens in a details panel.
You can then view and edit its details without losing context of the epic list or board.

When using the drawer:

- Select an epic from the list to open it in the drawer.
- The drawer appears on the right side of the screen.
- You can edit the epic directly in the drawer.
- To close the drawer, select the close icon ({{< icon name="close" >}}) or press **Escape**.

#### Open an epic in full page view

To open an epic in the full page view:

- Open the epic in a new tab. From the list of work items, either:
  - Right-click the epic and open it in a new browser tab.
  - Hold <kbd>Command</kbd> or <kbd>Control</kbd> and select the epic.
- Select an epic, and from the drawer, either:
  - In the upper-left corner, select the issue reference, for example `my_project#123`.
  - In the upper-right corner, select **Open in full page** ({{< icon name="maximize" >}}).

To always open work items in full page view, see [set preference whether to open items in a drawer](../../work_items/_index.md#configure-list-display-preferences).

## Filter a list of epics

{{< history >}}

- Filtering by custom fields was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525462) in GitLab 17.11.

{{< /history >}}

You can filter a list of epics by:

- Title or description (select **Search within**)
- Author name / username
- Confidentiality
- Groups
- Health
- Labels
- Milestones
- Reaction emoji
- Parent
- Subscribed
- [Custom fields](../../work_items/custom_fields.md) enabled for epics

To filter:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.
1. Select additional filters, operators, and values as needed.
   To search by title or description, type in the filter bar.
1. Press <kbd>Enter</kbd> or select the magnifying glass ({{< icon name="search" >}}).

### Filter with the OR operator

{{< history >}}

- OR filtering for labels and authors was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/382969) in GitLab 15.9 [with a flag](../../../administration/feature_flags/_index.md) named `or_issuable_queries`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104292) in GitLab 15.9.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/296031) in GitLab 17.0. Feature flag `or_issuable_queries` removed.

{{< /history >}}

You can use the OR operator (**is one of: `||`**) when you [filter the list of epics](#filter-a-list-of-epics) by:

- Assignee
- Author
- Label

`is one of` represents an inclusive OR. For example, if you filter by `Label is one of Deliverable` and
`Label is one of UX`, GitLab shows epics with either `Deliverable`, `UX`, or both labels.

## Sort the list of epics

You can sort the epics list by:

- Created date
- Updated date
- Closed date
- Milestone due date
- Due date
- Popularity
- Title
- Start date
- Health
- Blocking

Each option contains a button that can toggle the order between **Ascending** and **Descending**.
The sort option and order is saved and used wherever you browse epics, including the
[roadmap](../roadmap/_index.md).

## Change activity sort order

You can reverse the default order and interact with the activity feed sorted by most recent items
at the top. Your preference is saved in local storage and automatically applied to every epic and issue
you view.

To change the activity sort order, select the **Oldest first** dropdown list and select either oldest
or newest items to be shown first.

## Make an epic confidential

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

If you're working on items that contain private information, you can make an epic confidential.

> [!note]
> A confidential epic can only contain [confidential issues](../../project/issues/confidential_issues.md)
> and confidential child epics. However, merge requests are public, if created in a public project.
> To create a confidential merge request, see [merge requests for confidential issues](../../project/merge_requests/confidential.md).

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the epic's group.

To make an epic confidential:

- **When creating an epic**: Select the checkbox next to **Turn on confidentiality**.
- **In an existing epic**: In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}). Then select **Turn on confidentiality**.

You can also use the [`/confidential` quick action](../../project/quick_actions.md#confidential).

## Manage issues assigned to an epic

This section collects instructions for all the things you can do with [issues](../../project/issues/_index.md)
in relation to epics.

### Health status

{{< details >}}

- Tier: Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9002) in GitLab 17.5.

{{< /history >}}

Use health status on epics to gain quick insight into project progress.
Health status helps you communicate and manage potential issues proactively.

You can view an epic's health status in the epic view and in the **Child items** and **Linked items** sections.

You can set the health status to:

- On track (green)
- Needs attention (amber)
- At risk (red)

To address risks to timely delivery of your planned work, incorporate a review of epic health status into your:

- Daily stand-up meetings
- Project status reports
- Weekly meetings

#### Change health status of an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To change the health status of an epic:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Plan** > **Work items**, then filter by **Type** = **Epic**.
1. Select an epic.
1. In the right sidebar, in the **Health status** section, select **Edit**.
1. From the dropdown list, select a status.

The epic's health status is updated.

You can also set and clear health statuses using the [`/health_status`](../../project/quick_actions.md#health_status) and [`/clear_health_status`](../../project/quick_actions.md#clear_health_status) quick actions.

### Participants

Participants are users who interacted with an epic.
For information about viewing participants, see [participants](../../participants.md).

## Related topics

- [Linked items](../../work_items/linked_items.md)
- [Child items](../../work_items/child_items.md)
- [Weight](../../work_items/weight.md)
