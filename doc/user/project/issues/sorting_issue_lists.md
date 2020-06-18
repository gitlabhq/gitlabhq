---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Sorting and ordering issue lists

You can sort a list of issues several ways, including by issue creation date, milestone due date,
etc. The available sorting options can change based on the context of the list.
For sorting by issue priority, see [Label Priority](../labels.md#label-priority).

In group and project issue lists, it is also possible to order issues manually,
similar to [issue boards](../issue_board.md#issue-ordering-in-a-list).

## Manual sorting

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62178) in GitLab 12.2.

When you select **Manual** sorting, you can change
the order by dragging and dropping the issues. The changed order will persist. Everyone who visits the same list will see the reordered list, with some exceptions.

Each issue is assigned a relative order value, representing its relative
order with respect to the other issues in the list. When you drag-and-drop reorder
an issue, its relative order value changes accordingly.

In addition, any time that issue appears in a manually sorted list,
the updated relative order value will be used for the ordering. This means that
if issue `A` is drag-and-drop reordered to be above issue `B` by any user in
a given list inside your GitLab instance, any time those two issues are subsequently
loaded in any list in the same instance (could be a different project issue list or a
different group issue list, for example), that ordering will be maintained.

This ordering also affects [issue boards](../issue_board.md#issue-ordering-in-a-list).
Changing the order in an issue list changes the ordering in an issue board,
and vice versa.
