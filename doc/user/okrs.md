---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Objectives and key results (OKR) **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103355) in GitLab 15.6 [with a flag](../administration/feature_flags.md) named `okrs_mvc`. Disabled by default.

OKRs are an [Experiment](../policy/alpha-beta-support.md#experiment).
For the OKR feature roadmap, see [epic 7864](https://gitlab.com/groups/gitlab-org/-/epics/7864).

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project, ask an administrator to [enable the featured flag](../administration/feature_flags.md) named `okrs_mvc`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

[Objectives and key results](https://en.wikipedia.org/wiki/OKR) (OKRs) are a framework for setting
and tracking goals that are aligned with your organization's overall strategy and vision.

The objective and the key result in GitLab share many features. In the documentation, the term
**OKRs** refers to both objectives and key results.

OKRs are a type of work item, a step towards [default issue types](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)
in GitLab.
For the roadmap of migrating [issues](project/issues/index.md) and [epics](group/epics/index.md)
to work items and adding custom work item types, see
[epic 6033](https://gitlab.com/groups/gitlab-org/-/epics/6033) or the
[Plan direction page](https://about.gitlab.com/direction/plan/).

## Designing effective OKRs

Use objectives and key results to align your workforce towards common goals and track the progress.
Set a big goal with an objective and use [child objectives and key results](#child-objectives-and-key-results)
to measure the big goal's completion.

**Objectives** are aspirational goals to be achieved and define **what you're aiming to do**.
They show how an individual's, team's, or department's work impacts overall direction of the
organization by connecting their work to overall company strategy.

**Key results** are measures of progress against aligned objectives. They express
**how you know if you have reached your goal** (objective).
By achieving a specific outcome (key result), you create progress for the linked objective.

To know if your OKR makes sense, you can use this sentence:

<!-- vale gitlab.FutureTense = NO -->
> I/we will accomplish (objective) by (date) through attaining and achieving the following metrics (key results).
<!-- vale gitlab.FutureTense = YES -->

To learn how to create better OKRs and how we use them at GitLab, see the
[Objectives and Key Results handbook page](https://about.gitlab.com/company/okrs/).

## Create an objective

Prerequisites:

- You must have at least the Guest role for the project.

To create an objective:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues**.
1. In the upper-right corner, next to **New issue**, select the down arrow **{chevron-lg-down}** and then select **New objective**.
1. Select **New objective** again.
1. Enter the objective title.
1. Select **Create objective**.

To create a key result, [add it as a child](#add-a-child-key-result) to an existing objective.

## View an objective

Prerequisites:

- You must have at least the Guest role for the project.

To view an objective:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues**.
1. [Filter the list of issues](project/issues/managing_issues.md#filter-the-list-of-issues)
for `Type = objective`.
1. Select the title of an objective from the list.

## View a key result

Prerequisites:

- You must have at least the Guest role for the project.

To view a key result:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues**.
1. [Filter the list of issues](project/issues/managing_issues.md#filter-the-list-of-issues)
for `Type = key_result`.
1. Select the title of a key result from the list.

Alternatively, you can access a key result from the **Child objectives and key results** section in
its parent's objective.

## Edit title and description

Prerequisites:

- You must have at least the Reporter role for the project.

To edit an OKR:

1. [Open the objective](okrs.md#view-an-objective) or [key result](#view-a-key-result) that you want to edit.
1. Optional. To edit the title, select it, make your changes, and select any area outside the title
   text box.
1. Optional. To edit the description, select the edit icon (**{pencil}**), make your changes, and
   select **Save**.

## View OKR system notes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) to feature flag named `work_items_mvc` in GitLab 15.8. Disabled by default.
> - Changing activity sort order [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) in GitLab 15.8.
> - Filtering activity [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389971) in GitLab 15.10.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/334812) in GitLab 15.10.

Prerequisites:

- You must have at least the Reporter role for the project.

You can view all the system notes related to the task. By default they are sorted by **Oldest first**.
You can always change the sorting order to **Newest first**, which is remembered across sessions.

## Comments and threads

You can add [comments](discussions/index.md) and reply to threads in tasks.

## Assign users

To show who is responsible for an OKR, you can assign users to it.

Users on GitLab Free can assign one user per OKR.
Users on GitLab Premium and Ultimate can assign multiple users to a single OKR.
See also [multiple assignees for issues](project/issues/multiple_assignees_for_issues.md).

Prerequisites:

- You must have at least the Reporter role for the project.

To change the assignee on an OKR:

1. [Open the objective](okrs.md#view-an-objective) or [key result](#view-a-key-result) that you want to edit.
1. Next to **Assignees**, select **Add assignees**.
1. From the dropdown list, select the users to add as an assignee.
1. Select any area outside the dropdown list.

## Assign labels

Prerequisites:

- You must have at least the Reporter role for the project.

Use [labels](project/labels.md) to organize OKRs among teams.

To add labels to an OKR:

1. [Open the objective](okrs.md#view-an-objective) or [key result](#view-a-key-result) that you want to edit.
1. Next to **Labels**, select **Add labels**.
1. From the dropdown list, select the labels to add.
1. Select any area outside the dropdown list.

## Add an objective to a milestone

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367463) in GitLab 15.7.

You can add an objective to a [milestone](project/milestones/index.md).
You can see the milestone title when you view an objective.

Prerequisites:

- You must have at least the Reporter role for the project.

To add an objective to a milestone:

1. [Open the objective](okrs.md#view-an-objective) that you want to edit.
1. Next to **Milestone**, select **Add to milestone**.
   If an objective already belongs to a milestone, the dropdown list shows the current milestone.
1. From the dropdown list, select the milestone to be associated with the objective.

## Set objective progress

Show how much of the work needed to achieve an objective is finished.

You can only set progress manually on objectives, and it's not rolled up from child objectives or
key results.

Prerequisites:

- You must have at least the Reporter role for the project.

To set progress of an objective:

1. [Open the objective](okrs.md#view-an-objective) that you want to edit.
1. Next to **Progress**, select the text box.
1. Enter a number from 0 to 100.

## Set health status

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381899) in GitLab 15.7.

To better track the risk in meeting your goals, you can assign a [health status](project/issues/managing_issues.md#health-status)
to each objective and key result.
You can use health status to signal to others in your organization whether OKRs are progressing
as planned or need attention to stay on schedule.

Prerequisites:

- You must have at least the Reporter role for the project.

To set health status of an OKR:

1. [Open the key result](okrs.md#view-a-key-result) that you want to edit.
1. Next to **Health status**, select the dropdown list and select the desired health status.

## Close an OKR

When an OKR is achieved, you can close it.
The OKR is marked as closed but is not deleted.

Prerequisites:

- You must have at least the Reporter role for the project.

To close an OKR:

1. [Open the objective](okrs.md#view-an-objective) that you want to edit.
1. Next to **Status**, select **Closed**.

You can reopen a closed OKR the same way.

## Child objectives and key results

In GitLab, objectives are similar to key results.
In your workflow, use key results to measure the goal described in the objective.

You can add child objectives to a total of 9 levels. An objective can have up to 100 child OKRs.
Key results are children of objectives and cannot have children items themselves.

Child objectives and key results are available in the **Child objectives and key results** section
below an objective's description.

### Add a child objective

Prerequisites:

- You must have at least the Guest role for the project.

To add a new objective to an objective:

1. In an objective, in the **Child objectives and key results** section, select **Add** and then
   select **New objective**.
1. Enter a title for the new objective.
1. Select **Create objective**.

To add an existing objective to an objective:

1. In an objective, in the **Child objectives and key results** section, select **Add** and then
   select **Existing objective**.
1. Search for the desired objective by entering part of its title, then selecting the
   desired match.

   To add multiple objectives, repeat this step.
1. Select **Add objective**.

### Add a child key result

Prerequisites:

- You must have at least the Guest role for the project.

To add a new key result to an objective:

1. In an objective, in the **Child objectives and key results** section, select **Add** and then
   select **New key result**.
1. Enter a title for the new key result.
1. Select **Create key result**.

To add an existing key result to an objective:

1. In an objective, in the **Child objectives and key results** section, select **Add** and then
   select **Existing key result**.
1. Search for the desired OKR by entering part of its title, then selecting the
   desired match.

   To add multiple objectives, repeat this step.
1. Select **Add key result**.
