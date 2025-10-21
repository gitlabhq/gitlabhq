---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage epics
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This page collects instructions for all the things you can do with [epics](_index.md) or in relation
to them.

## Create an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.
- Assigning milestones to epics [introduced](https://gitlab.com/groups/gitlab-org/-/epics/329) in GitLab 18.2.

{{< /history >}}

Prerequisites:

- You must have at least the Planner role for the epic's group.

To create an epic in the group you're in:

1. Get to the New Epic form:
   - Go to your group and from the left sidebar select **Epics**. Then select **New epic**.
   - From an epic in your group, in the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}). Then select **New related epic**.
   - From anywhere, in the top menu, select **New** ({{< icon name="plus-square" >}}). Then select **New epic**.
   - In an empty [roadmap](../roadmap/_index.md), select **New epic**.

1. Enter a title.
1. Complete the fields.
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

- You must have at least the Planner role for the epic's group.

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

- You must have at least the Planner role for the project, be the author of the epic, or be
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

- You must have at least the Planner role for the parent epic's group.

To update multiple epics at the same time:

1. In a group, go to **Epics** > **List**.
1. Select **Bulk edit**. A sidebar on the right appears with editable fields.
1. Select the checkboxes next to each epic you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Select **Update selected**.

When bulk editing epics in a group, you can edit the following attributes:

- State (open or closed)
- [Assignees](#assignees)
- [Milestone](../../project/milestones/_index.md)
- [Labels](../../project/labels.md)
- [Health status](#health-status)
- [Notification](../../profile/notifications.md) subscription
- [Confidentiality](#make-an-epic-confidential)
- [Parent](#add-a-parent-epic-to-an-epic)

## Prevent truncating descriptions with "Read more"

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

- You must have at least the Planner role for the group.

To change the assignee on an epic:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**, then select your epic to view it.
1. On the right sidebar, in the **Assignees** section, select **Edit**.
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

- You must have at least the Planner role for the epic's group.

To change an epic's color:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. Select **New epic** or select an existing epic.
1. On the right sidebar, in the **Color** section, select **Edit**.
1. Select an existing color or enter an RGB or hex value.
1. Select any area outside the dialog.

The epic's color is updated.

## Delete an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/452189) in GitLab 16.11. In GitLab 16.10 and earlier, if you delete an epic, all its child epics and their descendants are deleted as well. If needed, you can [remove child epics](#remove-a-child-epic-from-a-parent-epic) from the parent epic before you delete it.
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

- You must have at least the Planner role for the epic's group.

To close an epic:

- In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}), then **Close epic**.

You can also use the `/close` [quick action](../../project/quick_actions.md).

## Reopen a closed epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

You can reopen an epic that was closed.

Prerequisites:

- You must have at least the Planner role for the epic's group.

To do so, either:

- In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}) and then **Reopen epic**.
- Use the `/reopen` [quick action](../../project/quick_actions.md).

You can also create an epic by
[promoting an issue](../../project/issues/managing_issues.md#promote-an-issue-to-an-epic).

## Go to an epic from an issue

<!-- Update this section after flag work_item_view_for_issues is removed to refer to the Parent section in the sidebar -->

If an issue belongs to an epic, you can go to the parent epic from:

- Breadcrumbs at the top of the issue.
- The **Epic** section in the right sidebar.

## View epics list

In a group, the left sidebar displays the total count of open epics.
This number indicates all epics associated with the group and its subgroups, including epics you
might not have permission to view.

Prerequisites:

- You must be a member of either:
  - The group
  - A project in the group
  - A project in one of the group's subgroups

To view epics in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.

### Who can view an epic

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

Whether you can view an epic depends on the [group visibility level](../../public_access.md) and
the epic's [confidentiality status](#make-an-epic-confidential):

- Public group and a non-confidential epic: Anyone can view the epic.
- Private group and non-confidential epic: You must have at least the Guest role for the group.
- Confidential epic (regardless of group visibility): You must have at least the Planner
  role for the group.

### Configure epic display preferences

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393559) in GitLab 18.2.

{{< /history >}}

You can customize how epics are displayed in the epic list by showing or hiding specific metadata
fields and configuring view preferences.

GitLab saves your display preferences at different levels:

- **Fields**: Saved per namespace. You can have different field visibility settings for different
  groups and projects based on your workflow needs. For example, you can show assignee and labels
  in one group, but hide them in another group.
- **Your preferences**: Saved globally across all projects and groups. This ensures consistent
  behavior for how you prefer to view work items.

To configure epic display preferences:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. In the upper-right corner, select **Display options** ({{< icon name="preferences" >}}).
1. Under **Fields**, turn on or turn off the metadata you want to display:
   - **Assignee**: Who the epic is assigned to.
   - **Labels**: Epic labels.
   - **Milestone**: Milestone information.
   - **Dates**: Due dates and date ranges.
   - **Health**: Health status indicators.
   - **Blocked/Blocking**: Blocking relationship indicators.
   - **Comments**: Comment counts.
   - **Popularity**: Popularity metrics.
1. Under **Your preferences**, turn on or turn off **Open items in side panel** to choose how
   epics open when you select them:
   - On (default): Epics open in a drawer on the right side of the screen.
   - Off: Epics open in a full page view.

### Open epics in a drawer

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464698) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `work_item_view_for_issues`. Enabled by default.
- Toggling between drawer and full page view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536620) in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

When you select an epic from the Epics page or an epic board, it opens in a drawer.
You can then view and edit its details without losing context of the epic list or board.

When using the drawer:

- Select an epic from the list to open it in the drawer.
- The drawer appears on the right side of the screen.
- You can edit the epic directly in the drawer.
- To close the drawer, select the close icon ({{< icon name="close" >}}) or press **Escape**.

#### Open an epic in full page view

To open an epic in the full page view:

- Open the epic in a new tab. From the list of epics, either:
  - Right-click the epic and open it in a new browser tab.
  - Hold <kbd>Command</kbd> or <kbd>Control</kbd> and select the epic.
- Select an epic, and from the drawer, in the upper-left corner, select **Open in full page** ({{< icon name="maximize" >}}).

#### Set preference whether to open epics in a drawer

To configure how epics open on the Epics page:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. In the upper-right corner, select **Display options** ({{< icon name="preferences" >}}).
1. Toggle **Open items in side panel**:
   - **On** (default): Epics open in a drawer overlay.
   - **Off**: Epics open in a full page view.

Your preference is saved and remembered across all your sessions and devices.

### Cached epic count

The total count of open epics displayed in the sidebar is cached if higher
than 1000. The cached value is rounded to thousands or millions and updated every 24 hours.

## Filter the list of epics

{{< history >}}

- Filtering by custom fields was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525462) in GitLab 17.11.

{{< /history >}}

You can filter the list of epics by:

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
- [Custom fields](../../../user/work_items/custom_fields.md) enabled for epics

To filter:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. Select the field **Search or filter results**.
1. From the dropdown list, select the scope or enter plain text to search by epic title or description.
1. Press <kbd>Enter</kbd> on your keyboard. The list is filtered.

### Filter with the OR operator

{{< history >}}

- OR filtering for labels and authors was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/382969) in GitLab 15.9 [with a flag](../../../administration/feature_flags/_index.md) named `or_issuable_queries`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104292) in GitLab 15.9.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/296031) in GitLab 17.0. Feature flag `or_issuable_queries` removed.

{{< /history >}}

You can use the OR operator (**is one of: `||`**) when you [filter the list of epics](#filter-the-list-of-epics) by:

- Authors
- Labels

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
[Roadmap](../roadmap/_index.md).

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

{{< alert type="note" >}}

A confidential epic can only contain [confidential issues](../../project/issues/confidential_issues.md)
and confidential child epics. However, merge requests are public, if created in a public project.
Read [Merge requests for confidential issues](../../project/merge_requests/confidential.md)
to learn how to create a confidential merge request.

{{< /alert >}}

Prerequisites:

- You must have at least the Planner role for the epic's group.

To make an epic confidential:

- **When creating an epic**: Select the checkbox next to **Turn on confidentiality**.
- **In an existing epic**: In the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}). Then select **Turn on confidentiality**.

You can also use the `/confidential` [quick action](../../project/quick_actions.md).

## Manage issues assigned to an epic

This section collects instructions for all the things you can do with [issues](../../project/issues/_index.md)
in relation to epics.

### View issues assigned to an epic

In the **Child items** section, you can see epics, issues, and tasks assigned to this epic.
You can also see any epics, issues, and tasks inherited by descendant items.
Only epics, issues, and tasks that you can access show on the list.

You can always view the issues assigned to the epic if they are in the group's child project.
It's possible because the visibility setting of a project must be the same as or less restrictive than
of its parent group.

### View count and weight of issues in an epic

In the **Child items** section header, the number of descendant epics and issues and their total
weight is displayed. Tasks are not included in these counts.

To see the number of open and closed epics and issues:

- In the section header or under each epic name, hover over the total counts.

The numbers reflect all child issues and epics associated with the epic, including those you might
not have permission to view.

### View epic progress

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5163) in GitLab 17.1.

{{< /history >}}

In the **Child items** section header, the epic progress percentage is displayed.
Tasks are not included in this calculation.

To see the completed and total weight of child issues:

- In the section header, hover over the percentage.

The weights and progress reflect all issues associated with the epic, including issues you might
not have permission to view.

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

- You must have at least the Planner role for the group.

To change the health status of an epic:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. Select an epic.
1. In the right sidebar, in the **Health status** section, select **Edit**.
1. From the dropdown list, select a status.

The epic's health status is updated.

You can also set and clear health statuses using the `/health_status` and `/clear_health_status` [quick actions](../../project/quick_actions.md#issues-merge-requests-and-epics).

### Add an issue to an epic

{{< history >}}

- Maximum number of child issues and epics [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/452111) to 5000 in GitLab 17.1.

{{< /history >}}

Add an existing issue to an epic, or create a new issue that's automatically
added to the epic.

The maximum number of direct child issues and epics is 5000.

#### Add an existing issue to an epic

You can add existing issues to an epic, including issues in a project from a [different group hierarchy](_index.md#child-issues-from-different-group-hierarchies).
Newly added issues appear at the top of the list of issues in the **Child items** section.

An epic contains a list of issues and an issue can be set as a child item of at most one epic.
When you add a new issue that's already linked to an epic, the issue is automatically unlinked from its
current parent.

Prerequisites:

- You must have at least the Guest role for the issue's project and the epic's group.

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
To create a new issue in a [project that was shared with the epic's group](../../project/members/sharing_projects_groups.md),
first [create the issue directly in the project](../../project/issues/create_issues.md#from-a-project), and
then [add an existing issue to an epic](#add-an-existing-issue-to-an-epic).

Prerequisites:

- You must have at least the Guest role for the issue's project and the epic's group.

To create an issue from an epic:

1. On the epic's page, under **Child items**, select **Add**.
1. Select **Add a new issue**.
1. Under **Title**, enter the title for the new issue.
1. From the **Project** dropdown list, select the project in which the issue should be created.
1. Select **Create issue**.

The new issue is assigned to the epic.

### Remove an issue from an epic

You can remove issues from an epic when you're on the epic's details page.
After you remove an issue from an epic, the issue is no longer associated with this epic.

Prerequisites:

- You must have at least the Guest role for the issue's project and the epic's group.

To remove an issue from an epic:

1. Next to the issue you want to remove, select **Remove** ({{< icon name="close" >}}).
   The **Remove issue** warning appears.
1. Select **Remove**.

![List of issues assigned to an epic](img/issue_list_v15_11.png)

### Reorder issues assigned to an epic

New issues show at the top of the list in the **Child items** section.
You can reorder the list of issues by dragging them.

Prerequisites:

- You must have at least the Guest role for the issue's project and the epic's group.

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

- You must have at least the Guest role for the issue's project and the epic's group.

To move an issue to another epic:

1. Go to the **Child items** section.
1. Drag issues into the desired parent epic in the visible hierarchy.

## Multi-level child epics

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can add any epic that belongs to a group or subgroup of the parent epic's group.
New child epics appear at the top of the list of epics in the **Child items** section.

When you add an epic that's already linked to a parent epic, the link to its current parent is removed.

Epics can contain multiple nested child epics, up to a total of 7 levels deep.

### Add a parent epic to an epic

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11198) in GitLab 17.5.

{{< /history >}}

To create a hierarchy of epics, add a parent epic to an existing epic.
This helps organize and track related work across multiple epics.

Prerequisites:

- You must have at least the Guest role for either the parent epic's group or the child epic's group.

To add a parent epic:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan** > **Epics**.
1. Select an epic.
1. In the right sidebar, in the **Parent** section, select **Edit**.
1. In the search box, enter part of the parent epic's title.
   You can only search for epics in the same group hierarchy.
1. From the search results, select the epic you want to add as the parent.

The parent epic is added.

### Child epics from other groups

Add a child epic that belongs to a group that is different from the parent epic's group.

Prerequisites:

- You must have at least the Guest role for both the child and parent epics' groups.
- Multi-level child epics must be available for both the child and parent epics' groups.

To add a child epic from another group, paste the epic's URL when [adding an existing epic](#add-a-child-epic-to-an-epic).

### View child epics on a roadmap

From an epic, view its child epics and related milestones on the [roadmap](../roadmap/_index.md).

Prerequisites:

- You must have at least the Guest role for the parent epic's group.

To view child epics from the parent:

- In an epic, in the **Child items** section, select **Roadmap view**.

### Add a child epic to an epic

Prerequisites:

- You must have at least the Guest role for the parent epic's group.

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
   - Search for the desired issue by entering part of the epic's title, then selecting the desired match. This search is only available for epics in the same group hierarchy.

   If there are multiple epics to be added, press <kbd>Space</kbd> and repeat this step.
1. Select **Add**.

### Move child epics between epics

New child epics appear at the top of the list in the **Child items** section.
You can move child epics from one epic to another.
When you add a new epic that's already linked to a parent epic, the link to its current parent is removed.
Issues and child epics cannot be intermingled.

Prerequisites:

- You must have at least the Guest role for the parent epic's group.

To move child epics to another epic:

1. Go to the **Child items** section.
1. Drag epics into the desired parent epic.

### Reorder child epics assigned to an epic

New child epics appear at the top of the list in the **Child items** section.
You can reorder the list of child epics.

Prerequisites:

- You must have at least the Guest role for the parent epic's group.

To reorder child epics assigned to an epic:

1. Go to the **Child items** section.
1. Drag epics into the desired order.

### Remove a child epic from a parent epic

Prerequisites:

- You must have at least the Guest role for the parent epic's group.

To remove a child epic from a parent epic:

1. Select **Remove** ({{< icon name="close" >}}) in the parent epic's list of epics.
   The **Remove epic** warning appears.
1. Select **Remove**.
