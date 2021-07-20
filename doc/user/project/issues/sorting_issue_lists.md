---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sorting and ordering issue lists **(FREE)**

You can sort a list of issues several ways, including by:

- Blocking **(PREMIUM)**
- Created date
- Due date
- Label priority
- Last updated
- Milestone due date
- Popularity
- Priority
- Weight

The available sorting options can change based on the context of the list.
For sorting by issue priority, see [Label Priority](../labels.md#label-priority).

In group and project issue lists, it is also possible to order issues manually,
similar to [issue boards](../issue_board.md#how-gitlab-orders-issues-in-a-list).

## Sorting by popularity

When you select sorting by **Popularity**, the issue order changes to sort descending by the
number of upvotes ([awarded](../../award_emojis.md) "thumbs up" emoji)
on each issue. You can use this to identify issues that are in high demand.

## Manual sorting

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62178) in GitLab 12.2.

When you select **Manual** sorting, you can change
the order by dragging and dropping the issues. The changed order persists, and
everyone who visits the same list sees the updated issue order, with some exceptions.

Each issue is assigned a relative order value, representing its relative
order with respect to the other issues on the list. When you drag-and-drop reorder
an issue, its relative order value changes.

In addition, any time an issue appears in a manually sorted list,
the updated relative order value is used for the ordering.
So, if anyone drags issue `A` above issue `B` in your GitLab instance,
this ordering is maintained whenever they appear together in any list.

This ordering also affects [issue boards](../issue_board.md#how-gitlab-orders-issues-in-a-list).
Changing the order in an issue list changes the ordering in an issue board,
and vice versa.

## Sorting by blocking issues **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34247/) in GitLab 13.7.

When you select to sort by **Blocking**, the issue list changes to sort descending by the
number of issues each issue is blocking. You can use this to determine the critical path for your backlog.
