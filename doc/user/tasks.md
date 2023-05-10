---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tasks **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `work_items`. Disabled by default.
> - [Creating, editing, and deleting tasks](https://gitlab.com/groups/gitlab-org/-/epics/7169) introduced in GitLab 15.0.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 15.3.

Known limitation:

- [Tasks currently cannot be accessed via REST API.](https://gitlab.com/gitlab-org/gitlab/-/issues/368055)

For the latest updates, check the [Tasks Roadmap](https://gitlab.com/groups/gitlab-org/-/epics/7103).

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flags](../administration/feature_flags.md) named `work_items`.
On GitLab.com, this feature is available.

Use tasks to track steps needed for the [issue](project/issues/index.md) to be closed.

When planning an issue, you need a way to capture and break down technical
requirements or steps necessary to complete it. An issue with related tasks is better defined,
and so you can provide a more accurate issue weight and completion criteria.

Tasks are a type of work item, a step towards [default issue types](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)
in GitLab.
For the roadmap of migrating issues and [epics](group/epics/index.md)
to work items and adding custom work item types, see
[epic 6033](https://gitlab.com/groups/gitlab-org/-/epics/6033) or the
[Plan direction page](https://about.gitlab.com/direction/plan/).

## View tasks

View tasks in issues, in the **Tasks** section.

You can also [filter the list of issues](project/issues/managing_issues.md#filter-the-list-of-issues)
for `Type = task`.

If you select a task from an issue, it opens in a modal window.
If you select a task to open in a new browser tab, or select it from the issue list,
the task opens in a full-page view.

## Create a task

Prerequisites:

- You must have at least the Reporter role for the project, or the project must be public.

To create a task:

1. In the issue description, in the **Tasks** section, select **Add**.
1. Select **New task**.
1. Enter the task title.
1. Select **Create task**.

### From a task list item

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377307) in GitLab 15.9.

Prerequisites:

- You must have at least the Reporter role for the project.

In an issue description with task list items:

1. Hover over a task list item and select the options menu (**{ellipsis_v}**).
1. Select **Convert to task**.

The task list item is removed from the issue description and a task is created in the tasks widget from its contents.
Any nested task list items are moved up a nested level.

## Add existing tasks to an issue

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381868) in GitLab 15.6.

Prerequisites:

- You must have at least the Guest role for the project, or the project must be public.

To add a task:

1. In the issue description, in the **Tasks** section, select **Add**.
1. Select **Existing task**.
1. Search tasks by title.
1. Select one or multiple tasks to add to the issue.
1. Select **Add task**.

## Edit a task

Prerequisites:

- You must have at least the Reporter role for the project.

To edit a task:

1. In the issue description, in the **Tasks** section, select the task you want to edit.
   The task window opens.
1. Optional. To edit the title, select it and make your changes.
1. Optional. To edit the description, select the edit icon (**{pencil}**), make your changes, and
   select **Save**.
1. Select the close icon (**{close}**).

### Using the rich text editor

> - Rich text editing in the modal view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363007) in GitLab 15.6 [with a flag](../administration/feature_flags.md) named `work_items_mvc`. Disabled by default.
> - Rich text editing in the full page view [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104533) in GitLab 15.7.

FLAG:
On self-managed GitLab, by default the rich text feature is not available. To make it available per group, ask an
administrator
to [enable the feature flag](../administration/feature_flags.md) named `work_items_mvc`. On GitLab.com, this feature
is not available. The feature is not ready for production use.

Use a rich text editor to edit a task's description.

Prerequisites:

- You must have at least the Reporter role for the project.

To edit the description of a task:

1. In the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. Next to **Description**, select the edit icon (**{pencil}**). The description text box appears.
1. Above the text box, select **Rich text**.
1. Make your changes, and select **Save**.

## Remove a task from an issue

Prerequisites:

- You must have at least the Reporter role for the project.

You can remove a task from an issue. The task is not deleted, but the two are no longer connected.
It's not possible to connect them again.

To remove a task from an issue:

1. In the issue description, in the **Tasks** section, next to the task you want to remove, select the options menu (**{ellipsis_v}**).
1. Select **Remove task**.

## Delete a task

Prerequisites:

- You must either:
  - Be the author of the task and have at least the Guest role for the project.
  - Have the Owner role for the project.

To delete a task:

1. In the issue description, in the **Tasks** section, select the task you want to edit.
1. In the task window, in the options menu (**{ellipsis_v}**), select **Delete task**.
1. Select **OK**.

## Assign users to a task

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334810) in GitLab 15.4.

To show who is responsible for a task, you can assign users to it.

Users on GitLab Free can assign one user per task.
Users on GitLab Premium and Ultimate can assign multiple users to a single task.
See also [multiple assignees for issues](project/issues/multiple_assignees_for_issues.md).

Prerequisites:

- You must have at least the Reporter role for the project.

To change the assignee on a task:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. Next to **Assignees**, select **Add assignees**.
1. From the dropdown list, select the users to add as an assignee.
1. Select any area outside the dropdown list.

## Assign labels to a task

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339756) in GitLab 15.5.

Prerequisites:

- You must have at least the Reporter role for the project.

To add [labels](project/labels.md) to a task:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit. The task window opens.
1. Next to **Labels**, select **Add labels**.
1. From the dropdown list, select the labels to add.
1. Select any area outside the dropdown list.

## Set a start and due date

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/365399) in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/365399) in GitLab 15.5.

You can set a [start and due date](project/issues/due_dates.md) on a task.

Prerequisites:

- You must have at least the Reporter role for the project.

You can set start and due dates on a task to show when work should begin and end.

To set a due date:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. If the task already has a due date next to **Due date**, select it. Otherwise, select **Add due date**.
1. In the date picker, select the desired due date.

To set a start date:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. If the task already has a start date next to **Start date**, select it. Otherwise, select **Add start date**.
1. In the date picker, select the desired due date.

   The due date must be the same or later than the start date.
   If you select a start date to be later than the due date, the due date is then changed to the same day.

## Add a task to a milestone

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367463) in GitLab 15.5 [with a flag](../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/367463) to feature flag named `work_items_mvc` in GitLab 15.7. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/367463) in GitLab 15.7.

You can add a task to a [milestone](project/milestones/index.md).
You can see the milestone title when you view a task.
If you create a task for an issue that already belongs to a milestone,
the new task inherits the milestone.

Prerequisites:

- You must have at least the Reporter role for the project.

To add a task to a milestone:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. Next to **Milestone**, select **Add to milestone**.
   If a task already belongs to a milestone, the dropdown list shows the current milestone.
1. From the dropdown list, select the milestone to be associated with the task.

## Set task weight **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362550) in GitLab 15.3.

Prerequisites:

- You must have at least the Reporter role for the project.

You can set weight on each task to show how much work it needs.
This value is visible only when you view a task.

To set issue weight of a task:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. Next to **Weight**, enter a whole, positive number.
1. Select the close icon (**{close}**).

## Add a task to an iteration **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367456) in GitLab 15.5 [with a flag](../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/367456) to feature flag named `work_items_mvc` in GitLab 15.7. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/367456) in GitLab 15.7.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `work_items_mvc`.
On GitLab.com, this feature is available.

You can add a task to an [iteration](group/iterations/index.md).
You can see the iteration title and period only when you view a task.

Prerequisites:

- You must have at least the Reporter role for the project.

To add a task to an iteration:

1. In the issue description, in the **Tasks** section, select the title of the task you want to edit.
   The task window opens.
1. Next to **Iteration**, select **Add to iteration**.
1. From the dropdown list, select the iteration to be associated with the task.

## View task system notes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) to feature flag named `work_items_mvc` in GitLab 15.8. Disabled by default.
> - Changing activity sort order [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) in GitLab 15.8.
> - Filtering activity [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389971) in GitLab 15.10.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 15.10.

You can view all the system notes related to the task. By default they are sorted by **Oldest first**.
You can always change the sorting order to **Newest first**, which is remembered across sessions.
You can also filter activity by **Comments only** and **History only** in addition to the default **All activity** which is remembered across sessions.

## Comments and threads

You can add [comments](discussions/index.md) and reply to threads in tasks.
