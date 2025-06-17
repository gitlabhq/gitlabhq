---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Configure merge request approvals for your GitLab instance.
title: Merge request approvals
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Merge request approval rules prevent users from overriding certain project settings.
When enabled, these settings are 
[enforced for all projects and groups](../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
in the instance.

These merge request approval settings can be set for the entire instance:

- **Prevent approval by author**. Prevents project maintainers from allowing request authors to
  merge their own merge requests.
- **Prevent approvals by users who add commits**. Prevents project maintainers from allowing users
  to approve merge requests if they have submitted any commits to the source branch.
- **Prevent editing approval rules in projects and merge requests**. Prevents users from modifying
  the approvers list in project settings or in individual merge requests.

The following are also affected by rules for the entire instance:

- [Project merge request approval rules](../user/project/merge_requests/approvals/_index.md).
- [Group merge request approval settings](../user/group/manage.md#group-merge-request-approval-settings).

## Enable merge request approval settings for an instance

To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.
1. Expand **Merge request approvals**.
1. Select the checkbox for any of the approval rules.
1. Select **Save changes**.
