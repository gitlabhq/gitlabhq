---
stage: Foundations
group: Personal Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: To-Do List
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Your *To-Do List* is a chronological list of items waiting for your input.
The items are known as *to-do items*.

You can use the To-Do List to track [actions](#actions-that-create-to-do-items)
related to the work you do in GitLab. When people contact you or your attention is
needed, a to-do item appears in your To-Do List.

## Access the To-Do List

To access your To-Do List:

On the left sidebar, at the top, select **To-Do List** ({{< icon name="task-done" >}}).

### Filter the To-Do List

To filter your To-Do List:

1. Above the list, put your cursor in the text box.
1. Select from one of the predefined filters.
1. Press <kbd>Enter</kbd>.

### Sort the To-Do List

To sort the To-Do List:

1. On the **To Do** tab, in the upper-right corner, select from the options:

   - **Recommended** sorts by the combination of created date and previously snoozed dates, with previously snoozed items at the top.
   - **Updated** sorts by the date the item was most recently updated.
   - **Label priority** sorts [by priorities you've set](project/labels.md#set-label-priority).

1. Optional. Select the sort direction.

{{< alert type="note" >}}

On the **Snoozed** and **Done** tabs, **Recommended** sorts items by their creation date only.

{{< /alert >}}

## Actions that create to-do items

{{< history >}}

- Multiple to-do items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28355) in GitLab 13.8 [with a flag](../administration/feature_flags.md) named `multiple_todos`. Disabled by default.
- Member access request notifications [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374725) in GitLab 15.8.
- Multiple to-do items [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/28355) in GitLab 16.2.
- Multiple to-do items [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/28355) in GitLab 17.8. Feature flag `multiple_todos` enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Many to-do items are created automatically.
Some of the actions that add a to-do item to your To-Do List:

- An issue or merge request is assigned to you.
- A [merge request review](project/merge_requests/reviews/_index.md) is requested.
- You're [mentioned](discussions/_index.md#mentions) in the description or
  comment of an issue, merge request, or epic.
- You're mentioned in a comment on a commit or design.
- The CI/CD pipeline for your merge request fails.
- An open merge request cannot be merged due to conflict, and one of the
  following is true:
  - You're the author.
  - You're the user that set the merge request to automatically merge after a
    pipeline succeeds.
- A merge request is removed from a [merge train](../ci/pipelines/merge_trains.md), and you're the user that added it.
- A member access request is raised for a group or project you're an owner of.

[In GitLab 17.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/28355), you receive a new to-do notification every time someone mentions you, even in the same issue or merge request.

For other actions that create to-do items like assignments or review requests,
you receive only one notification per action type, even if that action occurs multiple times in the same issue or merge request.

To-do items aren't affected by [GitLab notification email settings](profile/notifications.md).
The only exception: If your notification setting is set to **Custom** and **Added as approver** is
selected, you get a to-do item when you are eligible to approve a merge request.

## Create a to-do item

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390549) in objectives, key results, and tasks in GitLab 16.0.

{{< /history >}}

You can manually add an item to your To-Do List.

1. Go to your:

   - [Issue](project/issues/_index.md)
   - [Merge request](project/merge_requests/_index.md)
   - [Epic](group/epics/_index.md)
   - [Design](project/issues/design_management.md)
   - [Incident](../operations/incident_management/incidents.md)
   - [Objective or key result](okrs.md)
   - [Task](tasks.md)

1. In the upper-right corner, select **Add a to-do item** ({{< icon name="todo-add" >}}).

### Create a to-do item by mentioning someone

You can create a to-do item by mentioning someone anywhere except for a code block. Mentioning a user many times in one message only creates one to-do item.

For example, from the following comment, everyone except `frank` gets a to-do item created for them:

````markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

> @dan what do you think?

Hey @erin, this is what they said:

```
Hi, please message @frank :incoming_envelope:
```
````

### Re-add a done to-do item

If you marked a to-do item as done by mistake, you can re-add it from the **Done** tab:

1. On the left sidebar, at the top, select **To-Do List** ({{< icon name="task-done" >}}).
1. At the top, select **Done**.
1. [Find the to-do item](#filter-the-to-do-list) you want to re-add.
1. Next to this to-do item, select **Re-add this to-do item** {{< icon name="redo" >}}.

The to-do item is now visible in the **To Do** tab of the To-Do List.

## Actions that mark a to-do item as done

Various actions on the to-do item object (like issue, merge request, or epic) mark its
corresponding to-do item as done.

To-do items are marked as done if you:

- Add an emoji reaction to the description or comment.
- Add or remove a label.
- Change the assignee.
- Change the milestone.
- Close the to-do item's object.
- Create a comment.
- Edit the description.
- Resolve a [design discussion thread](project/issues/design_management.md#resolve-a-discussion-thread-on-a-design).
- Accept or deny a project or group membership request.

To-do items are **not** marked as done if you:

- Add a linked item (like a [linked issue](project/issues/related_issues.md)).
- Add a child item (like [child epic](group/epics/manage_epics.md#multi-level-child-epics) or [task](tasks.md)).
- Add a [time entry](project/time_tracking.md).
- Assign yourself.
- Change the [health status](project/issues/managing_issues.md#health-status).

If someone else closes, merges, or takes action on an issue, merge request, or
epic, your to-do item remains pending.

## Mark a to-do item as done

You can manually mark a to-do item as done.

There are two ways to do this:

- In the To-Do List, to the right of the to-do item, select **Mark as done** ({{< icon name="check" >}}).
- In the upper-right corner of the resource (for example, issue or merge request), select **Mark as done** ({{< icon name="todo-done" >}}).

### Bulk edit to-do items

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16564) in GitLab 17.10.

{{< /history >}}

You can bulk edit your to-do items:

- On the **To Do** tab: Mark to-do items as done or snooze them.
- On the **Snoozed** tab: Mark to-do items as done or remove them.
- On the **Done** tab: Restore to-do items.

To bulk edit to-do items:

1. In your To-Do List:
   - To select individual items, to the left of each item you want to edit, select the checkbox.
   - To select all items on the page, in the upper-left corner, select the **Select all** checkbox.
1. In the upper-right corner, select the desired action.

## Snooze to-do items

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17712) in GitLab 17.9.

{{< /history >}}

You can snooze to-do items to temporarily hide them from your main To-Do List. This allows you to focus on more urgent tasks and return to snoozed items later.

To snooze a to-do item:

1. In your To-Do List, next to the to-do item you want to snooze, select Snooze ({{< icon name="clock" >}}).
1. If you wish to snooze the to-do item until a specific time and date, select the
   `Until a specific time and date` option. Otherwise, choose one of the preset snooze durations:
   - For one hour
   - Until later today (4 hours later)
   - Until tomorrow (tomorrow at 8 AM local time)

Snoozed to-do items are removed from your main To-Do List and appear in a separate **Snoozed** tab.

When the snooze period ends, the to-do item automatically returns to your main To-Do List. It appears with an indicator showing when it was originally created.

## View snoozed to-do items

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17712) in GitLab 17.9.

{{< /history >}}

To view or manage your snoozed to-do items:

1. Go to your To-Do List.
1. At the top of the list, select the Snoozed tab.

From the Snoozed tab, you can:

- View when a snoozed to-do is scheduled to return to your main list.
- Remove the snooze to immediately return an item to your main To-Do List.
- Mark a snoozed to-do as done.

## How a user's To-Do List is affected when their access changes

For security reasons, GitLab deletes to-do items when a user no longer has access to a related resource.
For example, if the user no longer has access to an issue, merge request, epic, project, or group,
GitLab deletes the related to-do items.

This process occurs in the hour after their access changes. Deletion is delayed to
prevent data loss, in case the user's access was accidentally revoked.
