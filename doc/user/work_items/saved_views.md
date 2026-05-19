---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Create and use saved views to filter and organize your list of work items.
title: Saved views
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/479571) in GitLab 18.9.

{{< /history >}}

Saved views are custom filter combinations for your list of work items that you can reuse and share.
Create multiple views for different workflows, like filters for assignee, status, or priority, and switch between them quickly.
Each view also saves your list's [display options](_index.md#configure-list-display-preferences),
including which fields to show or how items are sorted.

## Saved view visibility

When you create a saved view, you control who can see, use, and change it.

Private views:

- Are visible to only the creator of the view.
- Cannot be edited or used by other users.

Shared views:

- Are visible to all members of the group or project.
- Can be added and used by other members.
- Can be edited by members who meet the [prerequisites](#edit-a-saved-view).

## Create a saved view

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the project or group.

To create a saved view:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. At the top of the page, from the filter bar, select a filter, operator, and its value.
1. Optional. Add more filters.
1. Above the filter bar, select **Add view** > **New view**.
1. Enter a title.
1. Optional. Enter a description.
   This field can help others find the view and learn what it is for.
1. Under **Visibility**, select either:
   - **Private**. Private views are visible only to you.
   - **Shared**. Shared views are visible to all members of the group or project.
1. Select **Create view**.

The view is created and added above the filter bar, to the right of your other saved views (if there are any).

## Add a saved view to your list

Add views that you or your teammates created to your saved view list.
Only you can see which views you have added to your list.

When you browse views, you can see all available views, including your private views and
shared views from teammates.

To add a saved view to your list:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Above the filter bar, select **Add view** > **Browse views**.
1. From the list, select a view you want to add.

## Edit a saved view

Edit a saved view to change its name, description, or visibility.

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the project or group.

To edit a saved view:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select the view you want to edit.
1. Select the view again, then select **Edit**.
1. Edit the title or description of the view.
1. Edit the visibility of the view. To change this setting, you must be the creator of the view.
1. Select **Save**.

## Copy a link to a saved view

Link to a saved view to share it with others.
When you select a link to a saved view that isn't already in your list, it's added to your list automatically.

To copy a link to a saved view:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select the view you want to copy.
1. Select the view again, then select **Copy link to view**.

## Remove a saved view from your list

To remove a saved view from your list:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select the view you want to remove.
1. Select the view again, then select **Remove from list**.

The view is removed from your list but remains available to add again.

## Delete a saved view

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the project or group.

> [!warning]
> When you delete a view, it disappears for everybody.
> Make sure other team members aren't using it.

To delete a saved view:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Plan** > **Work items**.
1. Select the view you want to delete.
1. Select the view again, then select **Delete view**.
1. In the confirmation dialog, select **Delete view**.

## Saved view limits

Users in the Free tier can have only five saved views at a time.
This limit does not include the default **All items** view.

When you reach the saved view limit:

- If you create or add a saved view, it replaces the last saved view in your list.
- If you select a link to a saved view, the view is not automatically added to your list.

## Related topics

- [View all work items](_index.md#view-all-work-items)
