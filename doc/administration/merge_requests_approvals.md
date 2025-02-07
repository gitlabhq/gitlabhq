---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure merge request approvals for your GitLab instance."
title: Merge request approvals
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Merge request approval rules prevent users from overriding certain settings for the project.
When enabled for the entire instance, these settings
[cascade](../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
and can no longer be changed:

- In projects.
- In groups.

To enable merge request approval settings for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.
1. Expand **Merge request approvals**.
1. Choose the required options.
1. Select **Save changes**.

## Available rules

Merge request approval settings that can be set for the instance are:

- **Prevent approval by author**. Prevents project maintainers from allowing request authors to
  merge their own merge requests.
- **Prevent approvals by users who add commits**. Prevents project maintainers from allowing users
  to approve merge requests if they have submitted any commits to the source branch.
- **Prevent editing approval rules in projects and merge requests**. Prevents users from modifying
  the approvers list in project settings or in individual merge requests.

The following are also affected by rules for the entire instance:

- [Project merge request approval rules](../user/project/merge_requests/approvals/_index.md).
- [Group merge request approval settings](../user/group/manage.md#group-merge-request-approval-settings).
