# Milestones

Milestones allow you to organize issues and merge requests into a cohesive group,
optionally setting a due date. A common use is keeping track of an upcoming
software version. Milestones can be created per-project or per-group.

## Creating a project milestone

>**Note:**
You need [Master permissions](../../permissions.md) in order to create a milestone.

You can find the milestones page under your project's **Issues ➔ Milestones**.
To create a new milestone, simply click the **New milestone** button when in the
milestones page. A milestone can have a title, a description and start/due dates.
Once you fill in all the details, hit the **Create milestone** button.

![Creating a milestone](img/milestone_create.png)

## Creating a group milestone

>**Note:**
You need [Master permissions](../../permissions.md) in order to create a milestone.

You can create a milestone for a group that will be shared across group projects.
On the group's **Issues ➔ Milestones** page, you will be able to see the state
of that milestone and the issues/merge requests count that it shares across the group projects. To create a new milestone click the **New milestone** button. The form is the same as when creating a milestone for a specific project which you can find in the previous item.

In addition to that you will be able to filter issues or merge requests by group milestones in all projects that belongs to the milestone group.

## Milestone promotion

You will be able to promote a project milestone to a group milestone [in the future](https://gitlab.com/gitlab-org/gitlab-ce/issues/35833).

## Special milestone filters

In addition to the milestones that exist in the project or group, there are some
special options available when filtering by milestone:

* **No Milestone** - only show issues or merge requests without a milestone.
* **Upcoming** - show issues or merge request that belong to the next open
  milestone with a due date, by project. (For example: if project A has
  milestone v1 due in three days, and project B has milestone v2 due in a week,
  then this will show issues or merge requests from milestone v1 in project A
  and milestone v2 in project B.)
* **Started** - show issues or merge requests from any milestone with a start
  date less than today. Note that this can return results from several
  milestones in the same project.

## Milestone progress statistics

Milestone statistics can be viewed in the milestone sidebar. The milestone percentage statistic
is calculated as; closed and merged merge requests plus all closed issues divided by
total merge requests and issues.

![Milestone statistics](img/progress.png)

## Quick actions

[Quick actions](../quick_actions.md) are available for assigning and removing project milestones only. [In the future](https://gitlab.com/gitlab-org/gitlab-ce/issues/34778), this will also apply to group milestones.
