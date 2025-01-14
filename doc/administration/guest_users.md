---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Guest users

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Users assigned the Guest role have limited access and capabilities compared to other user roles. Their permissions are restricted and are designed to provide basic visibility and interaction without compromising sensitive project data. For more information, see [Roles and permissions](../user/permissions.md).

In GitLab Ultimate, the Guest role is free and does not count towards the license seat count. You can assign the Guest role to users [through the API](../api/members.md#add-a-member-to-a-group-or-project) or the GitLab UI.

## Assign Guest role to users

Prerequisites:

- You must have at least the Maintainer role.

You can assign the Guest role to a current member of a group or project, or assign this role when creating a new member.

To assign the Guest role to a current group or project member:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Manage** > **Members**.
1. In the **Role** column of the group or project member you want to assign the Guest role to, select their current role (for example, **Developer**).
1. In the **Role details** drawer, change the Role to **Guest**.
1. Select **Update role**.

If the user you want to assign the Guest role to is not yet a
member of the project or group:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Manage** > **Members**.
1. Select **Invite members**.
1. In **Username, name or email address**, select the relevant user.
1. In **Select a role**, select **Guest**.
1. Optional. In **Access expiration date**, enter a date.
1. Select **Invite**.

## Guest user permissions and restrictions

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
