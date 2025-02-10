---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Iterations
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

An iteration in GitLab refers to a time-boxed workflow that groups issues to be worked on during
a specific period of time, usually lasting 1-3 weeks.

Teams can use iterations to track velocity and volatility metrics.
For tracking the same item over multiple concurrent periods, you can use iterations with [milestones](../../project/milestones/_index.md).
Create and manage various [iteration cadences](#iteration-cadences) in a group.

For example, you can use:

- Milestones for Program Increments, which span 8-12 weeks.
- Iterations for Sprints, which span 2 weeks.

In GitLab, iterations are similar to milestones, with a few differences:

- Iterations are only available to groups.
- Iterations are grouped into iteration cadences.
- Iterations require both a start and an end date.
- Iteration date ranges cannot overlap within an iteration cadence.

## Planning workflows with iterations

You can use iterations to organize and track work in fixed time periods.
The following examples show how iterations help teams maintain consistent delivery cycles.

### Sprint planning and execution

Use iterations to plan and execute work in fixed time periods, and help teams maintain a
predictable delivery cadence.
When teams work in sprints, each iteration provides a clear timebox for planning,
execution, and delivery of work items.
For more information, see
[Tutorial: Use GitLab to facilitate Scrum](../../../tutorials/scrum_events/_index.md).

For example, when running two-week sprints, teams often need to coordinate multiple workstreams.
The development team tracks implementation in the current sprint, while product managers prepare
backlog items for upcoming sprints.

By using iterations:

- Teams can visualize their entire sprint schedule.
- Work automatically rolls over between sprints.
- Stakeholders can track sprint progress through burndown charts.
- Teams can measure velocity across multiple sprints.

This structure helps teams complete work consistently while maintaining visibility into progress.

When you set up iterations for sprints:

- Each team works in the same iteration cadence.
- Teams can view work status in iteration reports.
- Sprint planning becomes more predictable.

### Rapid development cycles

Use iterations to support shorter development cycles when your team needs frequent releases.
When practicing methodologies like Extreme Programming (XP), teams can use one-week iterations
to maintain fast feedback loops.

For example, when implementing rapid changes, teams might deploy to production multiple times
per iteration.
The team tracks their work in weekly iterations while maintaining the flexibility
to release whenever code is ready.

By using iterations:

- Teams maintain structured timeboxes.
- You can track development velocity.
- Teams can adapt planning based on weekly metrics.
- Stakeholders can see concrete progress each week.

This approach helps teams balance agile practices with organized planning.

When you use iterations for rapid cycles:

- Work is organized into clear weekly boundaries.
- Teams track progress in smaller increments.
- Release planning aligns with iteration boundaries.

## Iteration cadences

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5077) in GitLab 14.1 [with a flag](../../../administration/feature_flags.md), named `iteration_cadences`. Disabled by default.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/354977) in GitLab 15.0: All scheduled iterations must start on the same day of the week as the cadence start day. Start date of cadence cannot be edited after the first iteration starts.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/354878) in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/367493) in GitLab 15.4: A new automation start date can be selected for cadence. Upcoming iterations are scheduled to start on the same day of the week as the changed start date. Iteration cadences can be manually managed by turning off the automatic scheduling feature.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/354878) in GitLab 15.5. Feature flag `iteration_cadences` removed.

Iteration cadences are containers for iterations and can be used to automate iteration scheduling.
You can use them to automate creating iterations every 1, 2, 3, or 4 weeks. You can also
configure iteration cadences to automatically roll over incomplete issues to the next iteration.

### Create an iteration cadence

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for a group.

To create an iteration cadence:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.
1. Select **New iteration cadence**.
1. Enter the title and description of the iteration cadence.

   To manually manage the iteration cadence, clear the **Enable automatic scheduling** checkbox and skip the next step.
1. Complete the required fields to use automatic scheduling.
   - Select the automation start date of the iteration cadence. Iterations are scheduled to
     begin on the same day of the week as the day of the week of the start date.
   - From the **Duration** dropdown list, select how many weeks each iteration should last.
   - From the **Upcoming iterations** dropdown list, select how many upcoming iterations should be
     created and maintained by GitLab.
   - Optional. To move incomplete issues to the next iteration, select the **Enable roll over** checkbox.
     At the end of the current iteration, [Automation Bot](#gitlab-automation-bot-user) moves all open
     issues to the next iteration.
     Issues are moved at midnight in the instance time zone (UTC by default).
     Administrators can change the instance time zone.
1. Select **Create cadence**. The cadence list page opens.

To manually manage the created cadence, see [Create an iteration manually](#create-an-iteration-manually).

### View the iterations list

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.

To view all the iterations in a cadence, ordered by descending date, select that iteration cadence.
From there you can create a new iteration or select an iteration to get a more detailed view.

NOTE:
If a project has issue tracking
[turned off](../../project/settings/_index.md#configure-project-features-and-permissions),
to view the iterations list, enter its URL. To do so, add: `/-/cadences` to your project or group URL.
For example `https://gitlab.com/gitlab-org/sample-data-templates/sample-gitlab-project/-/cadences`.
[Issue 339009](https://gitlab.com/gitlab-org/gitlab/-/issues/339009) tracks improving this.

### Edit an iteration cadence

Prerequisites:

- You must have at least the Planner role for a group.

To edit an iteration cadence:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.
1. To the right of the cadence you want to edit, select the vertical ellipsis (**{ellipsis_v}**) and
   then select **Edit cadence**.
1. Edit the fields.
   - When you use automatic scheduling and edit the **Automation start date** field,
     you must set a new start date that doesn't overlap with the existing
     current or past iterations.
   - Editing **Upcoming iterations** is a non-destructive action.
     For example, if ten upcoming iterations already exist, changing the number under **Upcoming iterations** to `2`
     doesn't delete the eight existing upcoming iterations.
1. Select **Save changes**.

#### Turn on and off automatic scheduling for an iteration cadence

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.
1. To the right of the cadence for which you want to turn on or off automatic scheduling, select the
   vertical ellipsis (**{ellipsis_v}**) and then select **Edit cadence**.
1. Select or clear the **Enable automatic scheduling** checkbox.
1. If you're turning on automatic scheduling,
   complete the required fields **Automation start date**, **Duration**, and **Upcoming iterations**.
   - For **Automation start date**, you can select any date that doesn't overlap with the existing open iterations.
     If you have upcoming iterations, the automatic scheduling adjusts them appropriately to fit
     your chosen duration.
1. Select **Save changes**.

#### Example: Turn on automatic scheduling for a manual iteration cadence

Suppose it's Friday, April 15, and you have three iterations in a manual iteration cadence:

- Monday, April 4 - Friday, April 8 (closed)
- Tuesday, April 12 - Friday, April 15 (ongoing)
- Tuesday, May 3 - Friday, May 6 (upcoming)

The earliest possible **Automation start date** you can choose in this scenario
is Saturday, April 16, because April 15 overlaps with the ongoing iteration.

If you select Monday, April 18 as the automation start date to
automate scheduling iterations every week up to two upcoming iterations,
after the conversion you have the following iterations:

- Monday, April 4 - Friday, April 8 (closed)
- Tuesday, April 12 - Friday, April 15 (ongoing)
- Monday, April 18 - Sunday, April 24 (upcoming)
- Monday, April 25 - Sunday, May 1 (upcoming)

Your existing upcoming iteration "Tuesday, April 12 - Friday, April 15"
is changed to "April 18 - Sunday, April 24".

An additional upcoming iteration "April 25 - Sunday, May 1" is scheduled
to satisfy the requirement that there are at least two upcoming iterations scheduled.

### Delete an iteration cadence

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for a group.

Deleting an iteration cadence also deletes all iterations in that cadence.

To delete an iteration cadence:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.
1. To the right of the cadence you want to delete, select the vertical ellipsis (**{ellipsis_v}**) and then select **Delete cadence**.
1. Select **Delete cadence**.

### GitLab Automation Bot user

When iteration roll-over is enabled, at the end of the current iteration, all open issues are moved
to the next iteration.

Iterations are changed by the special GitLab Automation Bot user, which you can see in the issue
[system notes](../../project/system_notes.md).
This user isn't a [billable user](../../../subscriptions/self_managed/_index.md#billable-users),
so it does not count toward the license limit count.

On GitLab.com, this is the `automation-bot1` user.

## Create an iteration manually

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

When an iteration cadence has automatic scheduling enabled, iterations are created on schedule.
If you disable that option, you can create iterations manually.

Prerequisites:

- You must have at least the Planner role for a group.
- There must be at least one iteration cadence in the group and
  [automatic scheduling must be disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.

To create an iteration:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations**.
1. To the right of the cadence in which you want create an iteration, select the vertical ellipsis
   (**{ellipsis_v}**) and then select **Add iteration**.
1. Complete the fields.
1. Select **Create iteration**. The iteration details page opens.

## Edit an iteration

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for a group.

To edit an iteration:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations** and select an iteration cadence.
1. Select the iteration you want edit. The iteration details page opens.
1. In the upper-right corner, select the vertical ellipsis (**{ellipsis_v}**) and then select **Edit**.
1. Edit the fields:
   - You can edit **Title**, **Start date**, and **Due date** only if [automatic scheduling is disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.
1. Select **Save changes**.

## Delete an iteration

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for a group.
- [Automatic scheduling must be disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.

To delete an iteration:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations** and select an iteration cadence.
1. Select the iteration you want edit. The iteration details page opens.
1. In the upper-right corner, select the vertical ellipsis (**{ellipsis_v}**) and then select **Delete**.
1. Select **Delete**.

## Iteration report

You can track the progress of an iteration by reviewing iteration reports.
An iteration report displays a list of all the issues assigned to an iteration and their status.

The report also shows a breakdown of total issues in an iteration.
Open iteration reports show a summary of completed, unstarted, and in-progress issues.
Closed iteration reports show the total number of issues completed by the due date.

### View an iteration report

To view an iteration report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations** and select an iteration cadence.
1. Select an iteration.

### Iteration burndown and burnup charts

The iteration report includes [burndown and burnup charts](../../project/milestones/burndown_and_burnup_charts.md),
similar to how they appear when viewing a [milestone](../../project/milestones/_index.md):

- Burndown charts help track completion progress of total scope.
- Burnup charts track the daily total count and weight of issues added to and completed in a given timebox.

#### View iteration charts scoped to subgroups or projects

View burndown and burnup charts for iterations created for a group in any of its
subgroups or projects.
When you do this, the charts only count the issues that belong to the subgroup or project.

For example, suppose a group has two projects named `Project 1` and `Project 2`.
Each project has a single issue assigned to the same iteration from the group.

An iteration report generated for the group shows issue counts for all the group's projects:

- Completed: 0 of 2
- Incomplete: 0 of 2
- Unstarted: 2 of 2
- Burndown chart total issues: 2
- Burnup chart total issues: 2

An iteration report generated for `Project 1` shows only issues that belong to this project:

- Completed: 0 of 1
- Incomplete: 0 of 1
- Unstarted: 1 of 1
- Burndown chart total issues: 1
- Burnup chart total issues: 1

### Group issues by label

Group the list of issues by label to view issues that belong to your team, and get a more accurate
understanding of scope attributable to each label.

To group issues by label:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Plan > Iterations** and select an iteration cadence.
1. Select an iteration.
1. From the **Group by** dropdown list, select **Label**.
1. From the **Filter by label** dropdown list, select the labels you want to group by.
1. Select any area outside the label dropdown list. The page is now grouped by the selected labels.

## Related topics

- [Add an issue to an iteration](../../project/issues/managing_issues.md#add-an-issue-to-an-iteration)
- [Tutorial: Use GitLab to run an Agile iteration](../../../tutorials/agile_sprint/_index.md)
