---
type: reference
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/time_tracking.html'
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Time tracking **(FREE)**

You can estimate and track the time you spend on [issues](issues/index.md)
and [merge requests](merge_requests/index.md).

Then you can [view a report](#view-a-time-tracking-report) that shows totals over time.

Use time tracking for these tasks:

- Record the time spent working on an issue or a merge request.
- Add or update an estimate of the total time to complete an issue or a merge
  request.
- View a breakdown of time spent working on an issue or a merge request.

You don't have to indicate an estimate to enter the time spent, and vice versa.

To enter and remove time tracking data, you must use [quick actions](quick_actions.md).
Type all quick actions on their own lines.
If you use any quick action more than once in a single comment, only its last occurrence is applied.

You can see the data about time tracking on the right sidebar in issues and merge requests:

![Time tracking in the sidebar](img/time_tracking_sidebar_v13_12.png)

## Estimates

The estimate is designed to show the total time needed to complete an issue or merge request.

You can see the estimated time remaining when you hover over the time tracking information in the right sidebar.

![Estimated time remaining](img/remaining_time_v14_2.png)

### Add an estimate

Prerequisites:

- You must have at least the Reporter role for the project.

To enter an estimate, use the `/estimate` [quick action](quick_actions.md), followed by the time.

For example, if you need to enter an estimate of 1 month, 2 weeks, 3 days, 4 hours, and 5 minutes,
type `/estimate 1mo 2w 3d 4h 5m`.
Check the [time units you can use](#available-time-units).

An issue or a merge request can have only one estimate.
Every time you enter a new time estimate, it overwrites the previous value.

### Remove an estimate

Prerequisites:

- You must have at least the Reporter role for the project.

To remove an estimate entirely, use the `/remove_estimate` [quick action](quick_actions.md).

## Time spent

As you work, you can log the time you've spent.

Every new time spent entry is added to the current total time spent for the
issue or the merge request.

### Add time spent

Prerequisites:

- You must have at least the Reporter role for the project.

To enter time spent, use the `/spend` [quick action](quick_actions.md), followed by the time.

For example, if you need
to log 1 month, 2 weeks, 3 days, 4 hours, and 5 minutes, type `/spend 1mo 2w 3d 4h 5m`.
Check the [time units you can use](#available-time-units).

To add a [time tracking report](#view-a-time-tracking-report) entry with a note, create a comment
with a description and the quick action.
It then shows in the time tracking report **Summary/Notes** column. For example:

```plaintext
Draft MR and respond to initial comments

/spend 30m
```

### Add time spent on a specific date

Prerequisites:

- You must have at least the Reporter role for the project.

You can log time in the past by providing a date after the time.
For example, to log 1 hour of time spent on 31 January 2021,
type `/spend 1h 2021-01-31`.

If you type a future date, no time is logged.

### Remove time spent

Prerequisites:

- You must have at least the Reporter role for the project.

To subtract time, enter a negative value. For example, `/spend -3d` removes three
days from the total time spent. You can't go below 0 minutes of time spent,
so if you remove more time than already entered, GitLab ignores the subtraction.

To remove all the time spent at once, use the `/remove_time_spent` [quick action](quick_actions.md).

## View a time tracking report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271409) in GitLab 13.12.

You can view a breakdown of time spent on an issue or merge request.

Prerequisites:

- You must have at least the [Reporter role](../permissions.md#project-members-permissions) for a project.

To view a time tracking report:

1. Go to an issue or a merge request.
1. In the right sidebar, select **Time tracking report**.

![Time tracking report](img/time_tracking_report_v13_12.png)

The breakdown of spent time is limited to a maximum of 100 entries.

## Available time units

The following time units are available:

| Time unit | What to type                | Conversion rate |
| --------- | --------------------------- | --------------- |
| Month     | `mo`, `month`, or `months`  | 4w (160h)       |
| Week      | `w`, `week`, or `weeks`     | 5d (40h)        |
| Day       | `d`, `day`, or `days`       | 8h              |
| Hour      | `h`, `hour`, or `hours`     | 60m             |
| Minute    | `m`, `minute`, or `minutes` |                 |

### Limit displayed units to hours **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/29469/) in GitLab 12.1.

In GitLab self-managed instances, you can limit the display of time units to hours.
To do so:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Localization**.
1. Under **Time tracking**, select the **Limit display of time tracking units to hours** checkbox.
1. Select **Save changes**.

With this option enabled, `75h` is displayed instead of `1w 4d 3h`.

## Related topics

- [Time tracking solutions page](https://about.gitlab.com/solutions/time-tracking/)
- Time tracking GraphQL references:
  - [Connection](../../api/graphql/reference/index.md#timelogconnection)
  - [Edge](../../api/graphql/reference/index.md#timelogedge)
  - [Fields](../../api/graphql/reference/index.md#timelog)
  - [Timelogs](../../api/graphql/reference/index.md#querytimelogs)
  - [Group timelogs](../../api/graphql/reference/index.md#grouptimelogs)
  - [Project Timelogs](../../api/graphql/reference/index.md#projecttimelogs)
  - [User Timelogs](../../api/graphql/reference/index.md#usertimelogs)
