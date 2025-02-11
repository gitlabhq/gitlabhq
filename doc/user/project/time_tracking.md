---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Time tracking
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Time tracking for tasks [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438577) in GitLab 17.0.
> - Time tracking for epics [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12396) in GitLab 17.5. Your administrator must have [enabled the new look for epics](../group/epics/epic_work_items.md).
> - Minimum role to add, edit, and remove estimate [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

You can estimate and track the time you spend on an item, such as:

- [Epic](../group/epics/_index.md). Your administrator must have [enabled the new look for epics](../group/epics/epic_work_items.md).
- [Issue](issues/_index.md).
- [Task](../tasks.md).
- [Merge request](merge_requests/_index.md).

Then you can [view a report](#view-an-items-time-tracking-report) that shows totals over time.

Use time tracking for these tasks:

- Record the time spent working on an item.
- Add or update an estimate of the total time to complete an item.
- View a breakdown of time spent working on an item.

You don't have to indicate an estimate to enter the time spent, and vice versa.

To enter and remove time tracking data, you must use [quick actions](quick_actions.md).
Type all quick actions on their own lines.
If you use any quick action more than once in a single comment, only its last occurrence is applied.

You can see the data about time tracking on the right sidebar:

![Time tracking in the sidebar](img/time_tracking_sidebar_v13_12.png)

## Estimates

The estimate is designed to show the total time needed to complete an item.

You can see the estimated time remaining when you hover over the time tracking information in the right sidebar.

![Estimated time remaining](img/remaining_time_v14_2.png)

### Add an estimate

Prerequisites:

- In issues, you must have at least the Planner role for the project.
- In tasks, you must have at least the Planner role for the project.
- In merge requests, you must have at least the Developer role for the project.

To enter an estimate, use the `/estimate` [quick action](quick_actions.md), followed by the time.

For example, if you need to enter an estimate of 1 month, 2 weeks, 3 days, 4 hours, and 5 minutes,
type `/estimate 1mo 2w 3d 4h 5m`.
Check the [time units you can use](#available-time-units).

An item can have only one estimate.
Every time you enter a new time estimate, it overwrites the previous value.

### Remove an estimate

Prerequisites:

- In issues, you must have at least the Planner role for the project.
- In tasks, you must have at least the Planner role for the project.
- In merge requests, you must have at least the Developer role for the project.

To remove an estimate entirely, use the `/remove_estimate` [quick action](quick_actions.md).

## Time spent

As you work, you can log the time you've spent.

Every new time spent entry is added to the current total time spent for the
issue, task, or the merge request.

The total amount of time spent on an issue, task, or merge request cannot exceed a year.

### Add time spent

Prerequisites:

- You must have at least the Planner role for the project.

#### Using the user interface

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101563) in GitLab 15.7.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150564) in GitLab 17.0. When you don't specify when time was spent, current time is used.

To add a time entry using the user interface:

1. In the **Time tracking** section of the sidebar, select **Add time entry** (**{plus}**). A dialog opens.
1. Enter:

   - The amount of time spent.
   - Optional. When it was spent. If empty, uses current time.
   - Optional. A summary.

1. Select **Save**.

The **Spent** total in the sidebar is updated and you can view all entries in a [time tracking report](#view-an-items-time-tracking-report).

#### Using a quick action

To enter time spent, use the `/spend` [quick action](quick_actions.md), followed by the time.

For example, if you need
to log 1 month, 2 weeks, 3 days, 4 hours, and 5 minutes, type `/spend 1mo 2w 3d 4h 5m`.
Check the [time units you can use](#available-time-units).

To add a [time tracking report](#view-an-items-time-tracking-report) entry with a note, create a comment
with a description and the quick action.
It then shows in the time tracking report **Summary/Notes** column. For example:

```plaintext
Draft MR and respond to initial comments

/spend 30m
```

To log when time was spent, enter a date after the time, using the `YYYY-MM-DD` format.

For example, to log 1 hour of time spent on 31 January 2021,
enter `/spend 1h 2021-01-31`.

If you type a future date, no time is logged.

### Subtract time spent

Prerequisites:

- You must have at least the Planner role for the project.

To subtract time, enter a negative value. For example, `/spend -3d` removes three
days from the total time spent. You can't go below 0 minutes of time spent,
so if you remove more time than already entered, GitLab ignores the subtraction.

### Delete time spent

> - Delete button [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356796) in GitLab 15.1.

A timelog is a single entry of time spent, either positive or negative.

Prerequisites:

- You must be the author of the timelog or have at least the Maintainer role for the project.

To delete a timelog, either:

- In the time tracking report, on the right of a timelog entry, select **Delete time spent** (**{remove}**).
- Use the [GraphQL API](../../api/graphql/reference/_index.md#mutationtimelogdelete).

### Delete all the time spent

Prerequisites:

- You must have at least the Planner role for the project.

To delete all the time spent at once, use the `/remove_time_spent` [quick action](quick_actions.md).

## View an item's time tracking report

To view a time tracking report of time spent on an item:

- For an issue or a merge request:

  1. Go to an issue or a merge request.
  1. In the right sidebar, select **Time tracking report**.

- For an epic or a task:

  1. Go to an epic or a task.
  1. In the right sidebar, select the time next to **Spent**.

![Time tracking report](img/time_tracking_report_v15_1.png)

The breakdown of spent time displayed is limited to a maximum of 100 entries.

## Global time tracking report

DETAILS:
**Status**: Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344002) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `global_time_tracking_report`. Disabled by default.
> - Enabled on GitLab.com in GitLab 16.5.

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `global_time_tracking_report`.
On GitLab.com, this feature is available. On GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

View a report of time spent in issues, tasks, and merge requests across all of GitLab.

This feature is an [experiment](../../policy/development_stages_support.md).
If you find a bug, let us know in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435222).

To view the global time tracking report:

1. In your browser, enter the global report's URL:
   - For self-managed, add `/-/timelogs` to your base URL. For example, `https://gitlab.example.com/-/timelogs`.
   - For GitLab.com, go to <https://gitlab.com/-/timelogs>.
1. Optional. To filter by a specific user, enter their username without the `@` symbol.
1. Select start and end dates.
1. Select **Run report**.

![global time tracking report](img/global_time_report_v16_5.png)

## Available time units

The following time units are available:

| Time unit | What to type                | Conversion rate |
| --------- | --------------------------- | --------------- |
| Month     | `mo`, `month`, or `months`  | 4 w (160 h)     |
| Week      | `w`, `week`, or `weeks`     | 5 d (40 h)      |
| Day       | `d`, `day`, or `days`       | 8 h             |
| Hour      | `h`, `hour`, or `hours`     | 60 m            |
| Minute    | `m`, `minute`, or `minutes` |                 |

### Limit displayed units to hours

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

On GitLab Self-Managed, you can limit the display of time units to hours.
To do so:

1. On the left sidebar, select **Search or go to**.
1. Select **Settings > Preferences**.
1. Expand **Localization**.
1. Under **Time tracking**, select the **Limit display of time tracking units to hours** checkbox.
1. Select **Save changes**.

With this option enabled, `75h` is displayed instead of `1w 4d 3h`.

## Related topics

- Time tracking GraphQL references:
  - [Connection](../../api/graphql/reference/_index.md#timelogconnection)
  - [Edge](../../api/graphql/reference/_index.md#timelogedge)
  - [Fields](../../api/graphql/reference/_index.md#timelog)
  - [Timelogs](../../api/graphql/reference/_index.md#querytimelogs)
  - [Group timelogs](../../api/graphql/reference/_index.md#grouptimelogs)
  - [Project Timelogs](../../api/graphql/reference/_index.md#projecttimelogs)
  - [User Timelogs](../../api/graphql/reference/_index.md#usertimelogs)
