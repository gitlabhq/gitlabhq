---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use merge request reviews to discuss and improve code before it is merged into your project."
title: Manage merge requests
---

GitLab provides tools for managing merge requests for your project and group.

## Delete a merge request

In most cases you should close, rather than delete, merge requests.
You cannot undo the deletion of a merge request.

Prerequisites:

- You must have the Owner role for the project.

To delete a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request you want to delete.
1. Select **Edit**.
1. Scroll to the bottom of the page, and select **Delete merge request**.

NOTE:
Deleting a merge request does not completely erase all data.
Some information persists to maintain project history and to support recovery processes.
For more information, see [Handle sensitive information](../../../topics/git/undo.md#handle-sensitive-information).

## Bulk edit merge requests in a project

These attributes are editable when bulk editing merge requests:

- Status (open/closed)
- Assignee
- Milestone
- Labels
- Subscriptions

Prerequisites:

- You must have at least the Developer role.

To do this:

1. In a project, go to **Code > Merge requests**.
1. Select **Bulk edit**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Select **Update selected**.

## Bulk edit merge requests in a group

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

These attributes are editable when you bulk edit merge requests for a group:

- Milestone
- Labels

Prerequisites:

- You must have at least the Developer role for the project.

To update multiple group merge requests at the same time:

1. In a group, go to **Code > Merge requests**.
1. Select **Bulk edit**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request you want to edit.
1. Select the appropriate fields and their values from the sidebar.
1. Select **Update selected**.

## Related topics

- [Bulk edit issues](../issues/managing_issues.md#bulk-edit-issues-from-a-group)
