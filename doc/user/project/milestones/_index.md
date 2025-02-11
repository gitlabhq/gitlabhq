---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Milestones
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Milestones in GitLab are a way to track issues and merge requests created to achieve a broader goal
in a certain period of time, such as a program increment or upcoming release.
When you use milestones together with [iterations](../../group/iterations/_index.md), you can track
work across two concurrent timeboxes with different start and end dates.

Milestones allow you to organize issues and merge requests into a cohesive group, with an optional start date and an optional due date.

## Milestones as releases

Milestones can be used to track releases. To do so:

1. Set the milestone due date to represent the release date of your release.
   If you do not have a defined start date for your release cycle, you can leave the milestone start
   date blank.
1. Set the milestone title to the version of your release, such as `Version 9.4`.
1. Add issues to your release by selecting the milestone from the issue's right sidebar.

Additionally, to automatically generate release evidence when you create your release, integrate
milestones with the [Releases feature](../releases/_index.md#associate-milestones-with-a-release).

## Project milestones and group milestones

A milestone can belong to [project](../_index.md) or [group](../../group/_index.md).

You can assign **project milestones** to issues or merge requests in that project only.
You can assign **group milestones** to any issue or merge request of any project in that group.

For information about project and group milestones API, see:

- [Project Milestones API](../../../api/milestones.md)
- [Group Milestones API](../../../api/group_milestones.md)

### View project or group milestones

To view the milestone list:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Milestones**.

In a project, GitLab displays milestones that belong to the project.
In a group, GitLab displays milestones that belong to the group and all projects and subgroups in the group.

### View milestones in a project with issues turned off

If a project has issue tracking
[turned off](../settings/_index.md#configure-project-features-and-permissions),
to get to the milestones page, enter its URL.

To do so:

1. Go to your project.
1. Add: `/-/milestones` to your project URL.
   For example `https://gitlab.com/gitlab-org/sample-data-templates/sample-gitlab-project/-/milestones`.

Alternatively, this project's issues are visible in the group's milestone page.

Improving this experience is tracked in issue [339009](https://gitlab.com/gitlab-org/gitlab/-/issues/339009).

### View all milestones

You can view all the milestones you have access to in the entire GitLab namespace.
You might not see some milestones because they're in projects or groups you're not a member of.

To do so:

1. On the left sidebar, select **Search or go to**.
1. Select **Your work**.
1. On the left sidebar, select **Milestones**.

### View milestone details

To view more information about a milestone,
in the **Milestones** page, select the title of the milestone you want to view.

The milestone view shows the title and description.
The tabs below the title and description show the following:

- **Issues**: Shows all issues assigned to the milestone. Issues are displayed in three columns named:
  - Unstarted Issues (open and unassigned)
  - Ongoing Issues (open and assigned)
  - Completed Issues (closed)
- **Merge Requests**: Shows all merge requests assigned to the milestone. Merge requests are displayed in four columns named:
  - Work in progress (open and unassigned)
  - Waiting for merge (open and assigned)
  - Rejected (closed)
  - Merged
- **Participants**: Shows all assignees of issues assigned to the milestone.
- **Labels**: Shows all labels that are used in issues assigned to the milestone.

#### Burndown charts

The milestone view contains a [burndown and burnup chart](burndown_and_burnup_charts.md),
showing the progress of completing a milestone.

![burndown and burnup chart](img/burndown_and_burnup_charts_v15_3.png)

#### Milestone sidebar

The sidebar on the milestone view shows the following:

- Percentage complete, which is calculated as number of closed issues divided by total number of issues.
- The start date and due date.
- The total time spent on all issues and merge requests assigned to the milestone.
- The total issue weight of all issues assigned to the milestone.
- The count of total, open, closed, and merged merge requests.
- Links to associated releases.
- The milestone's reference you can copy to your clipboard.

![Project milestone page](img/milestones_project_milestone_page_sidebar_v13_11.png)

## Create a milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

You can create a milestone either in a project or a group.

Prerequisites:

- You must have at least the Planner role for the project or group the milestone belongs to.

To create a milestone:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Milestones**.
1. Select **New milestone**.
1. Enter the title.
1. Optional. Enter description, start date, and due date.
1. Select **New milestone**.

![New milestone](img/milestones_new_project_milestone_v16_11.png)

## Edit a milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for the project or group the milestone belongs to.

To edit a milestone:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Milestones**.
1. Select a milestone's title.
1. In the upper-right corner, select **Milestone actions** (**{ellipsis_v}**) and then select **Edit**.
1. Edit the title, start date, due date, or description.
1. Select **Save changes**.

## Close a milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for the project or group the milestone belongs to.

To close a milestone:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Milestones**.
1. Either:
   - Next to the milestone you want to close, select **Milestone actions** (**{ellipsis_v}**) > **Close**.
   - Select the milestone title, and then select **Close**.

## Delete a milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for the project or group the milestone belongs to.

To delete a milestone:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Milestones**.
1. Either:
   - Next to the milestone you want to delete, select **Milestone actions** (**{ellipsis_v}**) > **Delete**.
   - Select the milestone title, and then select **Milestone actions** (**{ellipsis_v}**) > **Delete**.
1. Select **Delete milestone**.

## Promote a project milestone to a group milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

If you are expanding the number of projects in a group, you might want to share the same milestones
among this group's projects.
You can promote project milestones to the parent group to
make them available to other projects in the same group.

Promoting a milestone merges all project milestones across all projects in this group with the same
name into a single group milestone.
All issues and merge requests that were previously assigned to one of these project
milestones become assigned to the new group milestone.

WARNING:
This action cannot be reversed and the changes are permanent.

Prerequisites:

- You must have at least the Planner role for the group.

To promote a project milestone:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Milestones**.
1. Either:
   - Next to the milestone you want to promote, select **Milestone actions** (**{ellipsis_v}**) > **Promote**.
   - Select the milestone title, and then select **Milestone actions** (**{ellipsis_v}**) > **Promote**.
1. Select **Promote Milestone**.

## Assign a milestone to an issue or merge request

Every issue and merge request can be assigned one milestone.
The milestones are visible on every issue and merge request page, on the right sidebar.
They are also visible in the issue board.

To assign or unassign a milestone:

1. View an issue or a merge request.
1. On the right sidebar, next to **Milestones**, select **Edit**.
1. In the **Assign milestone** list, search for a milestone by typing its name.
   You can select from both project and group milestones.
1. Select the milestone you want to assign.

To assign or unassign a milestone, you can also:

- Use the `/milestone` [quick action](../quick_actions.md) in a comment or description
- Drag an issue to a [milestone list](../issue_board.md#milestone-lists) in a board
- [Bulk edit issues](../issues/managing_issues.md#bulk-edit-issues-from-a-project) from the issues list

## Filter issues and merge requests by milestone

### Filters in list pages

You can filter by both group and project milestones from the project and group issue/merge request list pages.

### Filters in issue boards

From [project issue boards](../issue_board.md), you can filter by both group milestones and project
milestones in:

- [Search and filter bar](../issue_board.md#filter-issues)
- [Issue board configuration](../issue_board.md#configurable-issue-boards)

From [group issue boards](../issue_board.md#group-issue-boards), you can filter by only group milestones in:

- [Search and filter bar](../issue_board.md#filter-issues)
- [Issue board configuration](../issue_board.md#configurable-issue-boards)

### Special milestone filters

When filtering by milestone, in addition to choosing a specific project milestone or group milestone, you can choose a special milestone filter.

- **None**: Show issues or merge requests with no assigned milestone.
- **Any**: Show issues or merge requests that have an assigned milestone.
- **Upcoming**: Show issues or merge requests that have been assigned the open milestone and has the nearest due date in the future.
- **Started**: Show issues or merge requests that have an open assigned milestone with a start date that is before today.

<!--- When Upcoming and Started milestones change in GitLab 18.0, integrate the contents
of the below topic into "Special milestone filters" -->

#### "Upcoming" and "Started" filters (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/501294) in GitLab 17.7
and is [planned for change](https://gitlab.com/gitlab-org/gitlab/-/issues/429728) in 18.0.

The behavior of "Upcoming" and "Started" special filters is planned to change in upcoming GitLab major release 18.0.
The new behavior of both the filters is outlined in
[issue 429728](https://gitlab.com/gitlab-org/gitlab/-/issues/429728#proposed-issue-filter-logic-for-upcoming-and-started-milestones).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
