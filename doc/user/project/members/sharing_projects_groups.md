---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sharing projects and groups
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to display invited group members on the Members tab of the Members page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
- Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.
- Feature flag `webui_members_inherited_users` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) in GitLab 17.4. Members of invited groups displayed by default.

{{< /history >}}

You can share by invitation:

- A project with a group.
- A group with another group.

## Sharing projects

When you want a group to have access to your project,
you can invite the [group](../../group/_index.md) to the project.
The group's direct and inherited members get access to the project, which becomes a **shared project**.

In this case, inherited members are members that are inherited from parent groups into the groups that are invited.
Only members of the group that is invited get access to the shared project.
If you want to give members of a subgroup of the group you are inviting access to the project, you have to invite the subgroup.

The following table provides an overview of the group members that get access to a shared project.

| Group member source                                                 | Access to shared project |
|---------------------------------------------------------------------|--------------------------|
| Direct member of the group that is shared                           | {{< icon name="check-circle" >}} Yes   |
| Inherited member of the group that is shared                        | {{< icon name="check-circle" >}} Yes   |
| Direct member of a subgroup, but not of the group that is shared    | {{< icon name="dotted-circle" >}} No   |
| Inherited member of a subgroup, but not of the group that is shared | {{< icon name="dotted-circle" >}} No   |

The [visibility level](../../public_access.md) of the group you're inviting must be at least as restrictive as that of the project.
For example, you can invite:

- A **private** group to a **private** project.
- A **private** group to an **internal** project.
- A **private** group to a **public** project.
- An **internal** group to an **internal** project.
- An **internal** group to a **public** project.
- A **public** group to a **public** project.

If the project's top-level group does not allow the project to be shared outside the hierarchy,
the invited group or subgroup must be in the project's [namespace](../../namespace/_index.md).

### Member access and roles

When you invite a group to a project, the following members get access to the project:

- Direct group members.
- Inherited group members.
- Members of other [groups that are shared](sharing_projects_groups.md#invite-a-group-to-a-group) with the invited group.

Each member's access depends on:

- Their role in the group.
- The maximum role you choose when you invite the group.

Invited members keep the lower of these two roles. For example, if a member has the Guest
role in their group, and you add their group to a project with a maximum role of Maintainer,
they keep the Guest role in the project.

In addition:

- On the group's page, the project is listed on the **Shared projects** tab.
- On the project's **Members** page, the group is listed on the **Groups** tab. This list includes both public and private groups.
- On the project's **Members** page, the members of the invited group are listed on the **Members** tab.
- On the usage quota page, members who have the **Project Invite** badge next to their profile count towards the billable members of the shared project's top-level group.

[In GitLab 16.11 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144638),
the invited group's name and membership source are masked on the **Members** and the **Groups** tabs,
unless one of the following applies:

- The invited group is public.
- The current user is a member of the invited group.
- The current user is an Owner of the current group or the Maintainer/Owner of the current project.

{{< alert type="note" >}}

The invited group's name and membership source are masked from members who do not have access to the invited group.
However, even if project Maintainers and Owners cannot access the private invited group, they can see the source of private invited group members.
This behavior is intended to help project Maintainers and Owners to better manage the memberships of the projects they own.

{{< /alert >}}

### Examples

A project in the namespace `group/subgroup01/project`:

- Can be shared with `group/subgroup02` or `group/subgroup01/subgroup03`.
- Can be shared with `group_abc` unless the project's top-level group does not allow the project to be shared outside the hierarchy.

For a project that was created by `Group 1`:

- The members of `Group 1` have access to the project.
- The Owner of `Group 1` can invite `Group 2` to the project.
  This way, members of both `Group 1` and `Group 2` have access to the shared project.

### Invite a group to a project

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to display invited group members on the Members tab of the Members page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
- Feature flag `webui_members_inherited_users` [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.
- Access expiration date for direct members of subgroups and projects [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/471051), and feature flag `webui_members_inherited_users` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/364078) in GitLab 17.4.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role.
- Sharing the project with other groups must not be prevented.
- You must be a member of the invited group or subgroup.

To invite a group to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Select **Invite a group**.
1. In the **Select a group to invite** list, select the group you want to invite.
1. From the **Select maximum role** list, select the [role](../../permissions.md) the invited group's members can have in the project. Invited members receive the lower of:
   - The maximum role you select
   - Their existing role in the group

   Invited group members cannot have a higher role in the project than they have in the group. For more information, see [member access and roles](#member-access-and-roles).
1. Optional. Select an **Access expiration date**.
   From that date onward, the invited group can no longer access the project.
1. Select **Invite**.

The invited group is displayed on the **Groups** tab.
You can also use the REST API to [list a project's invited groups](../../../api/projects.md#list-a-projects-invited-groups).

Private groups are:

- Masked from unauthorized users.
- Displayed in project settings for protected branches, protected tags, and protected environments.

The **Members** tab shows:

- Members who were directly added to the project.
- Inherited members of the group [namespace](../../namespace/_index.md) that the project was added to.

The members of the invited group are not displayed on the **Members** tab unless the `webui_members_inherited_users` feature flag is enabled.

#### Examples

A project with the name `project-01` has the following direct members:

- User A, Owner
- User B, Maintainer

A group with the name `group-01` has the following direct members:

- User C, Owner
- User D, Maintainer
- User E, Reporter

When `group-01` is invited to `project-01` with `Developer` permissions, users have the following roles:

- User A, Owner
- User B, Maintainer
- User C, Developer
- User D, Developer
- User E, Reporter

When `group-01` is invited to `project-01` with `Owner` permissions, users have the following roles:

- User A, Owner
- User B, Maintainer
- User C, Owner
- User D, Maintainer
- User E, Reporter

### View shared projects

A shared project is a project that has invited your group members to access its resources through the [**Invite a group**](#invite-a-group-to-a-project) action.

To view projects that have shared access with your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the group page, select the **Shared projects** tab.

A list of shared projects is displayed.
You can also use the REST API to [list a group's shared projects](../../../api/groups.md#list-shared-projects).

### Prevent a project from being shared with groups

Sharing a project with another group increases the number of users who can invite yet more members to the project.
Each (sub)group can be an additional source of access permissions,
which can be confusing and difficult to control.

To prevent a project from being shared with other groups:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Projects in `<group_name>` cannot be shared with other groups**.
1. Select **Save changes**.

When this setting is enabled:

- It applies to all subgroups, unless overridden by a group Owner.
- Groups already added to a project lose access to it.

{{< alert type="note" >}}

After you [specify a user cap for the group](../../group/manage.md#specify-a-user-cap-for-a-group), you cannot disable this setting.

{{< /alert >}}

## Sharing groups

When you want another group's members to have access to your group,
you can invite the [group](../../group/_index.md) to your group.
The group's direct members get access to the group, which becomes a **shared group**.

Only direct members of the invited group get access to the shared group, not inherited or subgroup members. To grant subgroup members access, invite the subgroup directly.

The following table provides an overview of the group members that get access to a shared group:

| Group member source                                          | Access to shared group |
|--------------------------------------------------------------|------------------------|
| Direct member of the group that is invited                   | {{< icon name="check-circle" >}} Yes   |
| Inherited member of the group that is invited                | {{< icon name="dotted-circle" >}} No    |
| Member of a subgroup, but not of the group that is invited    | {{< icon name="dotted-circle" >}} No    |

### Member access and roles

Each member's access depends on:

- Their role in the invited group.
- The maximum role you choose when you invite the group.

Invited members keep the lower of these two roles. For example, if a member has the Guest
role in their group, and you invite their group to another group with a maximum role of Maintainer,
they keep the Guest role in the new group.

After you invite a group to your group:

- On the group's overview page, groups that this group has been shared with are listed on the **Shared groups** tab.
- On the group's **Members** page, the invited group is listed on the **Groups** tab. This list includes both public and private groups.
- On the group's **Members** page, the members of the invited group are listed on the **Members** tab.
- On the group's usage quota page, direct members of the invited group who have the **Group Invite** badge next to their profile count towards the billable members of the inviting group.

[In GitLab 16.11 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144638),
the invited group's name and membership source are masked on the **Members** and the **Groups** tabs,
unless one of the following applies:

- The invited group is public.
- The current user is a member of the invited group.
- The current user is an Owner of the current group or the Maintainer/Owner of the current project.

{{< alert type="note" >}}

The invited group's name and membership source are masked from members who do not have access to the invited group.
However, even if group Owners cannot access the private invited group, they can see the source of private invited group members.
This behavior is intended to help group Owners to better manage the memberships of the groups they own.

{{< /alert >}}

### Examples

`User A` is a direct member of `Group 1` and has the Maintainer role for the group.
`Group 2` invites `Group 1` with the Developer role.
`User A` has the Developer role in `Group 2`.

`User B` is an inherited member of `Group 1`. This user doesn't get access to `Group 2` when `Group 1` is invited.

### Invite a group to a group

{{< history >}}

- Access expiration date for direct members of subgroups and projects [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/471051) in GitLab 17.4.

{{< /history >}}

Similar to how you invite a group to a project, you can invite a group to another group.

Prerequisites:

- You must be a member of the invited and inviting groups.

To invite a group to your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select **Invite a group**.
1. In the **Select a group to invite** list, select the group you want to invite.
1. From the **Select maximum role** list, select the [role](../../permissions.md) the invited group's members can have in the group. Invited members receive the lower of:
   - The maximum role you select
   - Their existing role in the invited group

   Invited members cannot have a higher role than they have in the invited group. For more information, see [member access and roles](#member-access-and-roles-1).
1. Select the highest [role](../../permissions.md) or [custom role](../../custom_roles/_index.md#assign-a-custom-role-to-an-invited-group) for users in the group.
1. Optional. Select an **Access expiration date**.
   From that date onward, the invited group can no longer access the group.
1. Select **Invite**.

### Remove an invited group

To remove an invited group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Groups** tab.
1. To the right of the group you want to remove, select **Remove group** ({{< icon name="remove" >}}).

When you remove the invited group from your group:

- All direct members of the invited group no longer have access to your group.
- Members of the invited group no longer count towards the billable members of your group.

### View shared groups

A shared group is a group that has invited your group members to access its resources through the [**Invite a group**](#invite-a-group-to-a-group) action.

To view groups that have shared access with your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the group page, select the **Shared groups** tab.

A list of shared groups is displayed.
You can also use the REST API to [list a group's shared groups](../../../api/groups.md#list-shared-groups).

### Prevent inviting groups outside the group hierarchy

You can configure a top-level group so its subgroups and projects
cannot invite other groups outside of the top-level group's hierarchy.
This option is only available for top-level groups.

For example, in the following group and project hierarchy:

- **Animals > Dogs > Dog Project**
- **Animals > Cats**
- **Plants > Trees**

If you prevent inviting groups outside the hierarchy for the **Animals** group:

- **Dogs** can invite the group **Cats**.
- **Dogs** cannot invite the group **Trees**.
- **Dog Project** can invite the group **Cats**.
- **Dog Project** cannot invite the group **Trees**.

To prevent inviting groups outside of the group's hierarchy:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Select **Members cannot invite groups outside of `<group_name>` and its subgroups**.
1. Select **Save changes**.

## Setting up a group for collaboration

If you intend to collaborate with external users on projects in your group, consider the following best practices:

- Structure your groups and subgroups logically based on organizational needs. Avoid creating unnecessary groups.
- If you have a lot of users to manage, consider organizing users in groups separate from the groups organizing projects. Share these user groups into the groups and projects they need access to.
- Carefully consider which groups you invite to your projects. Invite only groups that need access, to prevent oversharing and maintain security.
- When you invite a group:
  - Set the maximum role appropriately. It's better to assign the minimum permissions needed, instead of defaulting to the highest role.
  - Members from subgroups of the invited group do not gain access to the project. You might prefer to invite subgroups separately instead.
- Check the maximum role of users who belong to multiple groups with access to a project. To prevent unintended high permissions, you might want to change the users' roles.
- Periodically review group access to shared projects and update as appropriate. If a group no longer needs access to a project, remove it.
