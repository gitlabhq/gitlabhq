---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tasks **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `work_items`. Disabled by default.
> - [Creating, editing, and deleting tasks](https://gitlab.com/groups/gitlab-org/-/epics/7169) introduced in GitLab 15.0.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 15.3.

WARNING:
Tasks are in [**Alpha**](../policy/alpha-beta-support.md#alpha-features).

Known limitation:

- [Tasks currently cannot be accessed via REST API.](https://gitlab.com/gitlab-org/gitlab/-/issues/368055)

For the latest updates, check the [Tasks Roadmap](https://gitlab.com/groups/gitlab-org/-/epics/7103).

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flags](../administration/feature_flags.md) named `work_items` and `work_items_hierarchy`.
On GitLab.com, this feature is available.

Use tasks to track steps needed for the [issue](project/issues/index.md) to be closed.

When planning an issue, you need a way to capture and break down technical
requirements or steps necessary to complete it. An issue with related tasks is better defined,
and so you can provide a more accurate issue weight and completion criteria.

Tasks are a type of work item, a step towards [default issue types](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)
in GitLab.
For the roadmap of migrating issues and [epics](group/epics/index.md)
to work items and adding custom work item types, visit
[epic 6033](https://gitlab.com/groups/gitlab-org/-/epics/6033) or
[Plan direction page](https://about.gitlab.com/direction/plan/).

## View tasks

View tasks in issues, in the **Tasks** section.

You can also [filter the list of issues](project/issues/managing_issues.md#filter-the-list-of-issues)
for `Type = task`.

## Create a task

Prerequisites:

- You must have at least the Guest role for the project, or the project must be public.

To create a task:

1. In the issue description, in the **Tasks** section, select **Add**.
1. Enter the task title.
1. Select **Create task**.

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
