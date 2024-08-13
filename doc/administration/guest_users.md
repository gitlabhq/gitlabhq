---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Guest users

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Users assigned the Guest role have limited access and capabilities compared to other user roles. Their permissions are restricted and are designed to provide basic visibility and interaction without compromising sensitive project data. For more information, see [Permissions and roles](../user/permissions.md).

In GitLab Ultimate, the Guest role is free and does not count towards the license seat count. Administrators can assign the Guest role to users [through the API](../api/members.md#add-a-member-to-a-group-or-project) or the GitLab UI.

Users with the Guest role can:

- View project plans, blockers, and progress indicators.
- View high-level project information such as:
  - Analytics
  - Incident reports
  - Issues and epics
  - Licenses
- Create and link new project work items.
- Access public groups and public projects.

Users with the Guest role cannot:

- Modify existing data that they have not created.
- View code in GitLab projects by default.
- Create projects, groups, and snippets in their personal namespaces.
- Access internal or private projects or groups without administrator access.

## Assign Guest role to new users on GitLab.com

Prerequisites:

- You must:
  - Be an administrator.
  - Have at least the Maintainer role.

By default, new users are not assigned the Guest role.

To assign the Guest role to new users:

1. On the left sidebar, select **Manage** > **Members**.
1. Select the relevant user or [create a new one](../user/profile/account/create_accounts.md).
1. In the **Max Role** column, select **Guest**.

## Assign Guest role to new users on GitLab self-managed

Prerequisites:

- You must:
  - Be an administrator.
  - Have at least the Maintainer role.

By default, new users are not assigned the Guest role.

To assign the Guest role to new users:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. Select the relevant user or [create a new one](../user/profile/account/create_accounts.md).
1. In the **Max Role** column, select **Guest**.
