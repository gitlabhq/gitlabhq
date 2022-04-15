---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Iterations **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214713) in GitLab 13.1 [with a flag](../../../administration/feature_flags.md) named `group_iterations`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) in GitLab 13.2.
> - Moved to GitLab Premium in 13.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) in GitLab 14.6. [Feature flag `group_iterations`](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) removed.

WARNING:
After [Iteration Cadences](#iteration-cadences) becomes generally available,
manual iteration scheduling will be [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069) in GitLab 15.6.
To enhance the role of iterations as time boundaries, we will also deprecate the title field.

Iterations are a way to track issues over a period of time. This allows teams
to track velocity and volatility metrics. Iterations can be used with [milestones](../../project/milestones/index.md)
for tracking over different time periods.

For example, you can use:

- Milestones for Program Increments, which span 8-12 weeks.
- Iterations for Sprints, which span 2 weeks.

In GitLab, iterations are similar to milestones, with a few differences:

- Iterations are only available to groups.
- A group can only have one active iteration at a time.
- Iterations require both a start and an end date.
- Iteration date ranges cannot overlap.

## View the iterations list

To view the iterations list, go to **{issues}** **Issues > Iterations**.
To view all the iterations in a cadence, ordered by descending date, select that iteration cadence.
From there you can create a new iteration or select an iteration to get a more detailed view.

## Create an iteration

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069) in GitLab 14.10.

WARNING:
Manual iteration management is in its end-of-life process. Creating an iteration is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069)
in GitLab 14.10, and is planned for removal in GitLab 16.0.

Prerequisites:

- You must have at least the Developer role for a group.

To create an iteration:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select **New iteration**.
1. Enter the title, a description (optional), a start date, and a due date.
1. Select **Create iteration**. The iteration details page opens.

## Edit an iteration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218277) in GitLab 13.2.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069) in GitLab 14.10.

WARNING:
Editing all attributes, with the exception of `description` is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069)
in GitLab 14.10, and is planned for removal in GitLab 16.0.
In the future only editing an iteration's `description` will be allowed.

Prerequisites:

- You must have at least the Developer role for a group.

To edit an iteration, select the three-dot menu (**{ellipsis_v}**) > **Edit**.

## Delete an iteration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292268) in GitLab 14.3.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069) in GitLab 14.10.

WARNING:
Manual iteration management is in its end-of-life process. Deleting an iteration is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/356069)
in GitLab 14.10, and is planned for removal in GitLab 16.0.

Prerequisites:

- You must have at least the Developer role for a group.

To delete an iteration, select the three-dot menu (**{ellipsis_v}**) > **Delete**.

## Add an issue to an iteration

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

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. In the **Group by** dropdown, select **Label**.
1. Select the **Filter by label** dropdown.
1. Select the labels you want to group by in the labels dropdown.
   You can also search for labels by typing in the search input.
1. Select any area outside the label dropdown list. The page is now grouped by the selected labels.

## Iteration cadences

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5077) in GitLab 14.1.
> - Deployed behind a [feature flag](../../feature_flags.md), named `iteration_cadences`, disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an
administrator to [enable the feature flag](../../../administration/feature_flags.md) named
`iteration_cadences` for a root group.
On GitLab.com, this feature is not available. This feature is not ready for production use.

Iteration cadences automate iteration scheduling. You can use them to
automate creating iterations every 1, 2, 3, 4, or 6 weeks. You can also
configure iteration cadences to automatically roll over incomplete issues to the next iteration.

### Create an iteration cadence

Prerequisites:

- You must have at least the Developer role for a group.

To create an iteration cadence:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select **New iteration cadence**.
1. Fill out required fields, and select **Create iteration cadence**. The cadence list page opens.

### Delete an iteration cadence

Prerequisites:

- You must have at least the Developer role for a group.

Deleting an iteration cadence also deletes all iterations within that cadence.

To delete an iteration cadence:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select the three-dot menu (**{ellipsis_v}**) > **Delete cadence** for the cadence you want to delete.
1. Select **Delete cadence** in the confirmation modal.

### Convert manual cadence to use automatic scheduling

WARNING:
The upgrade is irreversible. After it's done, manual iteration cadences cannot be created.

When you **enable** the iteration cadences feature, all iterations are added
to a default iteration cadence.
In this default iteration cadence, you can continue to add, edit, and remove iterations.

To upgrade the iteration cadence to use the automation features:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Issues > Iterations**.
1. Select the three-dot menu (**{ellipsis_v}**) > **Edit cadence** for the cadence you want to upgrade.
1. Fill out required fields, and select **Save changes**.
