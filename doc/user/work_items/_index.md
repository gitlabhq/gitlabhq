---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Organize your team's work with GitLab work items. Track tasks, epics, issues, and objectives in a unified view to connect strategy with implementation and monitor progress."
title: Work items
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

Work items are the core elements for planning and tracking work in GitLab.
Planning and tracking product development often requires breaking work into smaller, manageable parts
while maintaining connection to the bigger picture.
Work items are designed around this fundamental need, providing a unified way to represent units of
work at any level, from strategic initiatives to individual tasks.

The hierarchical nature of work items enables clear relationships between different levels of work,
helping teams understand how daily tasks contribute to larger goals and how strategic objectives break
down into actionable components.

This structure supports various planning frameworks like Scrum, Kanban, and portfolio management
approaches, while giving teams visibility into progress at every level.
With work items, you can organize your team's work using common structures that support various
planning frameworks including Scrum, Kanban, and portfolio management approaches.

## Work item types

GitLab supports the following work item types:

- [Issues](../project/issues/_index.md): Track tasks, features, and bugs.
- [Epics](../group/epics/_index.md): Manage large initiatives across multiple milestones and issues.
- [Tasks](../tasks.md): Track small units of work.
- [Objectives and key results](../okrs.md): Track strategic goals and their measurable outcomes.
- [Test cases](../../ci/test_cases/_index.md): Integrate test planning directly into your GitLab workflows.

## View all work items

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513092) in GitLab 17.10 [with a flag](../../administration/feature_flags/_index.md) named `work_item_planning_view`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

To organize work items (like issues, epics, and tasks) side-by-side, use the consolidated work items view.
This view helps you understand the full scope of work, and prioritize effectively.

When you enable this feature, it:

- Removes **Plan** > **Issues** and **Plan** > **Epics** from the left sidebar in groups and projects.
- Adds **Plan** > **Work items** to the left sidebar.
- Pins **Work items** on the left sidebar for projects and groups, if you had previously pinned
  **Plan** > **Issues** or **Plan** > **Epics**.

Prerequisites:

- In the Free tier, your administrator must enable the [flag](../../administration/feature_flags/_index.md) named `namespace_level_work_items`.
- In the Premium and Ultimate tiers, your administrator must enable the [flag](../../administration/feature_flags/_index.md) named `work_item_epics`.

To view work items for a project or group:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Work items**.

### Filter work items

On the **Work items** page, you can use filters to narrow down the list:

1. At the top of the page, from the filter bar, select a filter, operator, and its value.
1. Optional. Add more filters.
1. Press <kbd>Enter</kbd> or select the search icon {{< icon name="search" >}}.

#### Available filters

{{< history >}}

- Filtering by description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536876) in GitLab 18.3.

{{< /history >}}

<!-- When the feature flag work_item_planning_view is removed, move more information from
managing_issues.md#filter-the-list-of-issues here -->

These filters are available for work items:

- Assignee
  - Operators: `is`, `is not one of`, `is one of`
- Author
  - Operators: `is`, `is not one of`, `is one of`
- Confidential
  - Values: `Yes`, `No`
- Contact
  - Operators: `is`
- Status
  - Operators: `is`
- Health status
  - Operators: `is`, `is not`
- Iteration
  - Operators: `is`, `is not`
- Label
  - Operators: `is`, `is not one of`, `is one of`
- Milestone
  - Operators: `is`, `is not`
- My reaction
  - Operators: `is`, `is not`
- Organisation
  - Operators: `is`
- Parent
  - Operators: `is`, `is not`
  - Values: Any `Issue`, `Epic`, `Objective`
- Release
  - Operators: `is`, `is not`
- Search within
  - Operators: `Titles`, `Descriptions`
- State
  - Values: `Any`, `Open`, `Closed`
- Type
  - Values: `Issue`, `Incident`, `Task`, `Epic`, `Objective`, `Key Result`, `Test case`
- Weight
  - Operators: `is`, `is not`

To access filters you've used recently, on the left side of the filter bar, select the
**Recent searches** ({{< icon name="history" >}}) dropdown list.

### Sort work items

{{< history >}}

- Sorting by status [introduced](https://gitlab.com/groups/gitlab-org/-/epics/18638) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `work_item_status_mvc2`. Enabled by default.

{{< /history >}}

<!-- When the feature flag work_item_planning_view is removed, move information from
sorting_issue_lists.md to this page and redirect here -->

Sort the list of work items by the following:

- Created date
- Updated date
- Start date
- Due date
- Title
- Status

To change the sorting criteria:

- On the right of the filter bar, select the **Created date** dropdown list.

To toggle the sorting order between ascending and descending:

- On the right of the filter bar, select **Sort direction** ({{< icon name="sort-lowest" >}}
  or {{< icon name="sort-highest" >}}).

For more information about sorting logic, see
[Sorting and ordering issue lists](../project/issues/sorting_issue_lists.md).

## Work item Markdown reference

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352861) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `extensible_reference_filters`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052) in GitLab 18.2. Feature flag `extensible_reference_filters` removed.

{{< /history >}}

You can reference work items in GitLab Flavored Markdown fields with `[work_item:123]`.
For more information, see [GitLab-specific references](../markdown.md#gitlab-specific-references).

## Related topics

- [Linked issues](../project/issues/related_issues.md)
- [Linked epics](../group/epics/linked_epics.md)
- [Issue boards](../project/issue_board.md)
- [Labels](../project/labels.md)
- [Iterations](../group/iterations/_index.md)
- [Milestones](../project/milestones/_index.md)
- [Custom fields](custom_fields.md)
