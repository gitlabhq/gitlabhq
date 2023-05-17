---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Iterations **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214713) in GitLab 13.1 [with a flag](../../../administration/feature_flags.md) named `group_iterations`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) in GitLab 13.2.
> - Moved to GitLab Premium in 13.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) in GitLab 14.6. [Feature flag `group_iterations`](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) removed.

Iterations are a way to track issues over a period of time. This allows teams
to track velocity and volatility metrics. For tracking over different time periods, you can use iterations [milestones](../../project/milestones/index.md).
You can create and manage various [iteration cadences](#iteration-cadences).

For example, you can use:

- Milestones for Program Increments, which span 8-12 weeks.
- Iterations for Sprints, which span 2 weeks.

In GitLab, iterations are similar to milestones, with a few differences:

- Iterations are only available to groups.
- Iterations are grouped into iteration cadences.
- Iterations require both a start and an end date.
- Iteration date ranges cannot overlap within an iteration cadence.

## Iteration cadences

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5077) in GitLab 14.1 [with a flag](../../../administration/feature_flags.md), named `iteration_cadences`. Disabled by default.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/354977) in GitLab 15.0: All scheduled iterations must start on the same day of the week as the cadence start day. Start date of cadence cannot be edited after the first iteration starts.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/354878) in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/367493) in GitLab 15.4: A new automation start date can be selected for cadence. Upcoming iterations are scheduled to start on the same day of the week as the changed start date. Iteration cadences can be manually managed by turning off the automatic scheduling feature.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/354878) in GitLab 15.5. Feature flag `iteration_cadences` removed.

Iteration cadences are containers for iterations and can be used to automate iteration scheduling.
You can use them to automate creating iterations every 1, 2, 3, or 4 weeks. You can also
configure iteration cadences to automatically roll over incomplete issues to the next iteration.

### Create an iteration cadence

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.

Prerequisites:

- You must have at least the Reporter role for a group.

To create an iteration cadence:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select **New iteration cadence**.
1. Enter the title and description of the iteration cadence.
1. To manually manage the iteration cadence, clear the **Enable automatic scheduling** checkbox and skip the next step.
1. Complete the required fields to use automatic scheduling.
   - Select the automation start date of the iteration cadence. Iterations are scheduled to
     begin on the same day of the week as the day of the week of the start date.
   - From the **Duration** dropdown list, select how many weeks each iteration should last.
   - From the **Upcoming iterations** dropdown list, select how many upcoming iterations should be
     created and maintained by GitLab.
   - Optional. To move incomplete issues to the next iteration, select **Roll over issues**.
     At the end of the current iteration, all open issues are added to the next iteration.
     Issues are moved at midnight in the instance time zone (UTC by default). Administrators can change the instance time zone.
1. Select **Create cadence**. The cadence list page opens.

If you want to manually manage the created cadence, read [Manual Iteration Management](#manual-iteration-management).

### View the iterations list

1. On the top bar, select **Main menu > Groups** and find your group.
1. Select **Issues > Iterations**.

To view all the iterations in a cadence, ordered by descending date, select that iteration cadence.
From there you can create a new iteration or select an iteration to get a more detailed view.

NOTE:
If a project has issue tracking
[turned off](../../project/settings/index.md#configure-project-visibility-features-and-permissions),
to view the iterations list, enter its URL. To do so, add: `/-/cadences` to your project or group URL.
For example `https://gitlab.com/gitlab-org/sample-data-templates/sample-gitlab-project/-/cadences`.
This is tracked in [issue 339009](https://gitlab.com/gitlab-org/gitlab/-/issues/339009).

### Edit an iteration cadence

Prerequisites:

- You must have at least the Developer role for a group.

To edit an iteration cadence:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select **Edit iteration cadence**.

When you use automatic scheduling and edit the **Automation start date** field,
you must set a new start date that doesn't overlap with the existing
current or past iterations.

Editing **Upcoming iterations** is a non-destructive action.
If ten upcoming iterations already exist, changing the number under **Upcoming iterations** to `2`
doesn't delete the eight existing upcoming iterations.

#### Turn on and off automatic scheduling for an iteration cadence

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Next to the cadence for which you want to turn on or off automatic scheduling, select the
   three-dot menu (**{ellipsis_v}**) **> Edit cadence**.
1. Select or clear the **Enable automatic scheduling** checkbox.
1. If you're turning on automatic scheduling,
   complete the required fields **Duration**, **Upcoming iterations**, and **Automation start date**.

   For **Automation start date**, you can select any date that doesn't overlap with the existing open iterations.
   If you have upcoming iterations, the automatic scheduling adjusts them appropriately to fit
   your chosen duration.
1. Select **Save changes**.

#### Example of turning on automatic scheduling for a manual iteration cadence

Suppose it's Friday, April 15, and you have three iteration in a manual iteration cadence:

- Monday, April 4 - Friday, April 8 (closed)
- Tuesday, April 12 - Friday, April 15 (ongoing)
- Tuesday, May 3 - Friday, May 6 (upcoming)

The earliest possible **Automation start date** you can choose
is Saturday, April 16 in this scenario, because April 15 overlaps with
the ongoing iteration.

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

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.

Prerequisites:

- You must have at least the Reporter role for a group.

Deleting an iteration cadence also deletes all iterations within that cadence.

To delete an iteration cadence:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select the three-dot menu (**{ellipsis_v}**) > **Delete cadence** for the cadence you want to delete.
1. Select **Delete cadence**.

## Manual iteration management

If you don't want your iterations to be scheduled by iteration cadences,
you can also create and manage them manually.

### Create an iteration

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.

Prerequisites:

- You must have at least the Reporter role for a group.
- [Automatic scheduling must be disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.

To create an iteration:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations** and select an iteration cadence.
1. Select **New iteration**.
1. Enter the title, a description (optional), a start date, and a due date.
1. Select **Create iteration**. The iteration details page opens.

### Edit an iteration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218277) in GitLab 13.2.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.

Prerequisites:

- You must have at least the Reporter role for a group.
- [Automatic scheduling must be disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.

To edit an iteration, select the three-dot menu (**{ellipsis_v}**) > **Edit**.

### Delete an iteration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292268) in GitLab 14.3.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.

Prerequisites:

- You must have at least the Reporter role for a group.
- [Automatic scheduling must be disabled](#turn-on-and-off-automatic-scheduling-for-an-iteration-cadence) for the iteration cadence.

To delete an iteration, select the three-dot menu (**{ellipsis_v}**) > **Delete**.

### Add an issue to an iteration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216158) in GitLab 13.2.

To learn how to add an issue to an iteration, see the steps in
[Managing issues](../../project/issues/managing_issues.md#add-an-issue-to-an-iteration).

## View an iteration report

> Viewing iteration reports in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222763) in GitLab 13.5.

You can track the progress of an iteration by reviewing iteration reports.
An iteration report displays a list of all the issues assigned to an iteration and their status.

The report also shows a breakdown of total issues in an iteration.
Open iteration reports show a summary of completed, unstarted, and in-progress issues.
Closed iteration reports show the total number of issues completed by the due date.

To view an iteration report, go to the iterations list page and select an iteration's period.

### Iteration burndown and burnup charts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222750) in GitLab 13.6.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/269972) in GitLab 13.7.
> - Scoped burnup and burndown charts in subgroups and projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326029) in GitLab 14.9.

The iteration report includes [burndown and burnup charts](../../project/milestones/burndown_and_burnup_charts.md),
similar to how they appear when viewing a [milestone](../../project/milestones/index.md).

Burndown charts help track completion progress of total scope, and burnup charts track the daily
total count and weight of issues added to and completed in a given timebox.

#### Iteration charts scoped to subgroups or projects

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326029) in GitLab 14.9.

You can view burndown and burnup charts for iterations created for a group in any of its
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225500) in GitLab 13.8.

You can group the list of issues by label.
This can help you view issues that have your team's label,
and get a more accurate understanding of scope attributable to each label.

To group issues by label:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. In the **Group by** dropdown list, select **Label**.
1. Select the **Filter by label** dropdown list.
1. Select the labels you want to group by in the labels dropdown list.
   You can also search for labels by typing in the search input.
1. Select any area outside the label dropdown list. The page is now grouped by the selected labels.
