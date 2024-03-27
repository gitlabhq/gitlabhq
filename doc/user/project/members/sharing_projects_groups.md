---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sharing projects and groups

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can share by invitation:

- [A project with a group](share_project_with_groups.md).
- [A group with another group](../../group/manage.md#share-a-group-with-another-group).

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to display invited group members on the Members tab of the Members page in GitLab 16.10 behind `webui_members_inherited_users` feature flag. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per user, an administrator can [enable the feature flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is not available.

[In GitLab 16.11 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144638),
the invited group's name and membership source are masked on the **Members** and the **Groups** tabs, unless one of the following applies:

- The invited group is public.
- The current user is a member of the invited group.
- The current user is an owner of the current group or the maintainer/owner of the current project.

## Sharing a project with a group

When you want a group to have access to your project,
you can invite the [group](../../group/index.md) to the project.
The group's direct and inherited members get access to the project, which becomes a **shared project**.

In this case, inherited members are members that are inherited from parent groups into the groups that are shared.
Only members of the group that is shared get access to the project.
If you want to give members of a subgroup of the group you are sharing access to the project, you have to share the subgroup.

The following table provides an overview of the group members that get access to a shared project.

| Group member source                                                 | Access to shared project |
|---------------------------------------------------------------------|--------------------------|
| Direct member of the group that is shared                           | **{check-circle}** Yes   |
| Inherited member of the group that is shared                        | **{check-circle}** Yes   |
| Direct member of a subgroup, but not of the group that is shared    | **{dotted-circle}** No   |
| Inherited member of a subgroup, but not of the group that is shared | **{dotted-circle}** No   |

The [visibility level](../../public_access.md) of the group you're inviting must be at least as restrictive as that of the project.
For example, you can invite:

- A **private** group to a **private** project.
- A **private** group to an **internal** project.
- A **private** group to a **public** project.
- An **internal** group to an **internal** project.
- An **internal** group to a **public** project.
- A **public** group to a **public** project.

If the project's top-level group [does not allow the project to be shared outside the hierarchy](../../group/access_and_permissions.md#prevent-group-sharing-outside-the-group-hierarchy), the invited group or subgroup must be in the project's [namespace](../../namespace/index.md).

If a group in the project's hierarchy [does not allow projects to be shared with groups](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups), the option to **Invite a group** is not available.

### Member access and roles

When you share a project, the following members get access to the project:

- All direct group members.
- Inherited group members.
- Members of other [groups that are shared](../../group/manage.md#share-a-group-with-another-group) with the invited group.

In addition:

- On the group's page, the project is listed on the **Shared projects** tab.
- On the project's **Members** page, the group is listed on the **Groups** tab. This list includes both public and private groups.
- On the project's **Members** page, the members of the invited group are listed on the **Members** tab.
- Each user is assigned a maximum role.
- On the usage quota page, members who have the **Project Invite** badge next to their profile count towards the billable members of the shared project's top-level group.

NOTE:
The invited group's name and membership source are masked from members who do not have access to the invited group.
However, even if project maintainers and owners cannot access the private invited group, they can see the source of private invited group members.
This behavior is intended to help project maintainers and owners to better manage the memberships of the projects they own.

### Examples

A project in the namespace `group/subgroup01/project`:

- Can be shared with `group/subgroup02` or `group/subgroup01/subgroup03`.
- Can be shared with `group_abc` unless the project's top-level group does not allow the project to be shared outside the hierarchy.

For a project that was created by `Group 1`:

- The members of `Group 1` have access to the project.
- The owner of `Group 1` can invite `Group 2` to the project.
  This way, members of both `Group 1` and `Group 2` have access to the shared project.

## Sharing a group with another group

After you invite a group to your group:

- The **Groups** tab of the group's **Members** page lists the invited group. This list includes both public and private groups.
- The **Members** tab of the group's **Members** page lists the members of the invited group.
- All direct members of the invited group have access to the inviting group.
  The least access is granted between the access in the invited group and the access in the inviting group.
- Inherited members of the invited group do not gain access to the inviting group.
- On the group's usage quota page, direct members of the invited group who have the **Group Invite** badge
  next to their profile count towards the billable members of the inviting group.

NOTE:
The invited group's name and membership source are masked from members who do not have access to the invited group.
However, even if group owners cannot access the private invited group, they can see the source of private invited group members.
This behavior is intended to help group owners to better manage the memberships of the groups they own.

### Examples

`User A` is a direct member of `Group 1` and has the Maintainer role in the group.
`Group 2` invites `Group 1` with the Developer role.
`User A` has the Developer role in `Group 2`.

`User B` is an inherited member of `Group 1`. This user doesn't get access to `Group 2` when `Group 1` is invited.

## Setting up a group for collaboration

If you intend to collaborate with external users on projects in your group, consider the following best practices:

- Structure your groups and subgroups logically based on organizational needs. Avoid creating unnecessary groups.
- If you have a lot of users to manage, consider organizing users in groups separate from the groups organizing projects. Share these user groups into the groups and projects they need access to.
- Carefully consider which groups you invite to your projects. Invite only groups that need access, to prevent oversharing and maintain security.
- When you invite a group:
  - Set the maximum role appropriately. It's better to assign the minimum permissions needed, instead of defaulting to the highest role.
  - Inherited members from subgroups of the invited group also gain access to the project. You might prefer to invite subgroups separately instead.
- Check the maximum role of users who belong to multiple groups with access to a project. To prevent unintended high permissions, you might want to change the users' roles.
- Periodically review group access to shared projects and update as appropriate. If a group no longer needs access to a project, remove it.
