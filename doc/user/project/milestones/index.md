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

You can create a milestone for several projects in the same group simultaneously.
On the group's **Issues ➔ Milestones** page, you will be able to see the status
of that milestone across all of the selected projects. To create a new milestone
for selected projects in the group, click the **New milestone** button. The
form is the same as when creating a milestone for a specific project with the
addition of the selection of the projects you want to inherit this milestone.

![Creating a group milestone](img/milestone_group_create.png)

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
