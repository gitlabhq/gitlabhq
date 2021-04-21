---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Bulk editing issues and merge requests at the project level

NOTE:
Bulk editing issues, epics, and merge requests is also available at the **group level**.
For more details, see
[Bulk editing issues, epics, and merge requests at the group level](../group/bulk_editing/index.md).

If you want to update attributes across multiple issues or merge requests, you can do it
by bulk editing them, that is, editing them together.

Only the items visible on the current page are selected for bulk editing (up to 20).

![Bulk editing](img/bulk_editing_v13_11.png)

## Bulk edit issues at the project level

> - Assigning epic ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/210470) in GitLab 13.2.
> - Editing health status [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218395) in GitLab 13.2.
> - Editing iteration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196806) in GitLab 13.9.

Users with permission level of [Reporter or higher](../permissions.md) can manage issues.

When bulk editing issues in a project, you can edit the following attributes:

- Status (open/closed)
- Assignee
- [Epic](../group/epics/index.md)
- [Milestone](milestones/index.md)
- [Labels](labels.md)
- [Health status](issues/managing_issues.md#health-status)
- Notification subscription
- [Iteration](../group/iterations/index.md)

To update multiple project issues at the same time:

1. In a project, go to **{issues}** **Issues > List**.
1. Click **Edit issues**. A sidebar on the right-hand side of your screen appears with editable fields.
1. Select the checkboxes next to each issue you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Click **Update all**.

## Bulk edit merge requests at the project level

Users with permission level of [Developer or higher](../permissions.md) can manage merge requests.

When bulk editing merge requests in a project, you can edit the following attributes:

- Status (open/closed)
- Assignee
- Milestone
- Labels
- Subscriptions

To update multiple project merge requests at the same time:

1. In a project, go to **{merge-request}** **Merge Requests**.
1. Click **Edit merge requests**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Click **Update all**.
