# Milestones

Milestones allow you to organize issues and merge requests into a cohesive group, optionally setting a due date.
A common use is keeping track of an upcoming software version. Milestones are created per-project.

![milestone form](milestones/form.png)

## Groups and milestones

You can create a milestone for several projects in the same group simultaneously.
On the group's milestones page, you will be able to see the status of that milestone across all of the selected projects.

![group milestone form](milestones/group_form.png)

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
