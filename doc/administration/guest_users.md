---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Guest users
description: Assign basic access with limited permissions as an entry-level user role.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Users with the Guest role have limited access and capabilities compared to other user roles. Their [permissions](../user/permissions.md) are restricted and designed to provide only basic visibility and interaction without compromising sensitive project data.

Users with the Guest role:

- Can access public groups and projects.
- Can view project plans, blockers, and progress indicators.
- Can create and link new project work items.
- Can view high-level project information such as:
  - Analytics
  - Incident reports
  - Issues and epics
  - Licenses
- Cannot create projects, groups, and snippets in their personal namespaces.
- Cannot modify existing data they didn't create.
- Cannot view code in projects.

## Seat usage

- In GitLab Free and Premium, users with the Guest role count as a billable user and consume a license seat.
- In GitLab Ultimate, users with the Guest role do not count as a billable user or consume a license seat.

{{< alert type="note" >}}

While the Guest role generally provides limited access, creating a [custom role](../user/custom_roles/_index.md) with the [`View repository code`](../user/custom_roles/abilities.md#source-code-management) permission allows you to provide access to code in your repositories without consuming a license seat. Adding any other permissions causes the role to occupy a billable seat.

{{< /alert >}}

## Assign Guest role to users

Prerequisites:

- You must have at least the Maintainer role.

You can assign the Guest role to a current member of a group or project, or assign this role when creating a new member. You can do this [through the API](../api/members.md#add-a-member-to-a-group-or-project) or the GitLab UI.

To assign the Guest role to a current group or project member:

1. On the left sidebar, select **Search or go to** and find your group or project. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Manage** > **Members**.
1. In the **Role** column of the group or project member you want to assign the Guest role to, select their current role (for example, **Developer**).
1. In the **Role details** drawer, change the Role to **Guest**.
1. Select **Update role**.

If the user you want to assign the Guest role to is not yet a
member of the group or project:

1. On the left sidebar, select **Search or go to** and find your group or project. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Manage** > **Members**.
1. Select **Invite members**.
1. In **Username, name or email address**, select the relevant user.
1. In **Select a role**, select **Guest**.
1. Optional. In **Access expiration date**, enter a date.
1. Select **Invite**.
