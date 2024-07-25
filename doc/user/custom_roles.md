---
stage: Govern
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom roles

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Custom roles feature introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `customizable_roles`.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.
> - Ability to create and remove a custom role with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393235) in GitLab 16.4.
> - Ability to use the UI to add a user to your group with a custom role, change a user's custom role, or remove a custom role from a group member [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393239) in GitLab 16.7.
> - Ability to create and remove an instance-wide custom role on GitLab self-managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562) in GitLab 16.9.

Custom roles allow an organization to create user roles with the precise privileges and permissions required for that organization's needs.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).

You can discuss individual custom role and permission requests in [issue 391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760).

NOTE:
Most custom roles are considered [billable users that use a seat](#billing-and-seat-usage). When you add a user to your group with a custom role, a warning is displayed if you are about to incur additional charges for having more seats than are included in your subscription.

## Available permissions

For more information on available permissions, see [custom permissions](custom_roles/abilities.md).

WARNING:
Depending on the permissions added to a lower base role such as Guest, a user with a custom role might be able to perform actions that are usually restricted to the Maintainer role or higher. For example, if a custom role is Guest plus managing CI/CD variables, a user with this role can manage CI/CD variables added by other Maintainers or Owners for that group or project.

## Create a custom role

You create a custom role by adding [permissions](#available-permissions) to a base role.

You can select any number of permissions. For example, you can create a custom role
with the permission to:

- View vulnerability reports.
- Change the status of vulnerabilities.
- Approve merge requests.

### GitLab SaaS

Prerequisites:

- You must have the Owner role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Roles and Permissions**.
1. Select **New role**.
1. In **Base role to use as template**, select an existing default role.
1. In **Role name**, enter the custom role's title.
1. In **Description**, enter a description for the custom role. 255 characters max.
1. Select the **Permissions** for the new custom role.
1. Select **Create role**.

In **Settings > Roles and Permissions**, the list of all custom roles displays the:

- Custom role name.
- Role ID.
- Base role that the custom role uses as a template.
- Permissions.

### GitLab self-managed

Prerequisites:

- You must be an administrator for the self-managed instance.

After you create a custom role for your self-managed instance, you can assign that custom role to a user in any group or subgroup in that instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Roles and Permissions**.
1. Select **New role**.
1. In **Base role to use as template**, select an existing default role.
1. In **Role name**, enter the custom role's title.
1. In **Description**, enter a description for the custom role. 255 characters max.
1. Select the **Permissions** for the new custom role.
1. Select **Create role**.

In **Settings > Roles and Permissions**, the list of all custom roles displays the:

- Custom role name.
- Role ID.
- Base role that the custom role uses as a template.
- Permissions.

To create a custom role, you can also [use the API](../api/graphql/reference/index.md#mutationmemberrolecreate).

## Edit a custom role

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/437590) in GitLab 17.0.

After a custom role has been created, you can edit that custom role's name, description,
and permissions. You cannot change the base role. If you need to change the base role,
you must create a new custom role.

### GitLab SaaS

Prerequisites:

- You must have the Owner role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Roles and Permissions**.
1. Select the vertical ellipsis (**{ellipsis_v}**) for the custom role, then
   select **Edit role**.
1. Modify the role as needed.
1. Select **Save role** to update the role.

### GitLab self-managed and GitLab Dedicated

Prerequisites:

- You must be an administrator for the self-managed instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Roles and Permissions**.
1. Select the vertical ellipsis (**{ellipsis_v}**) for the custom role, then
   select **Edit role**.
1. Modify the role as needed.
1. Select **Save role** to update the role.

To edit a custom role, you can also [use the API](../api/graphql/reference/index.md#mutationmemberroleupdate).

## Delete the custom role

Prerequisites:

- You must be an administrator or have the Owner role for the group.

You can remove a custom role from a group only if no members have that role. See [unassign a custom role from a group or project member](#unassign-a-custom-role-from-a-group-or-project-member).

1. On the left sidebar:
   - For self-managed, at the bottom, select **Admin**.
   - For SaaS, select **Search or go to** and find your group.
1. Select **Settings > Roles and Permissions**.
1. Select **Custom Roles**.
1. In the **Actions** column, select **Delete role** (**{remove}**) and confirm.

You can also [use the API](../api/graphql/reference/index.md#mutationmemberroledelete) to delete a custom role. To use the API, you must know the `id` of the custom role. If you do not know this `id`, find it by making an [API request on the group](../api/graphql/reference/index.md#groupmemberroles) or an [API request on the instance](../api/graphql/reference/index.md#querymemberroles).

## Add a user with a custom role to your group or project

Prerequisites:

If you are adding a user with a custom role:

- To your group, you must have the Owner role for the group.
- To your project, you must have at least the Maintainer role for the project.

To add a user with a custom role:

- To a group, see [add users to a group](group/index.md#add-users-to-a-group).
- To a project, see [add users to a project](project/members/index.md#add-users-to-a-project).

If a group or project member has a custom role, the [group or project members list](group/index.md#view-group-members) displays "Custom Role" in the **Max role** column of the table.

## Assign a custom role to an existing group or project member

Prerequisites:

If you are assigning a custom role to an existing:

- Group member, you must have the Owner role for the group.
- Project member, you must have at least the Maintainer role for the project.

### Use the UI to assign a custom role

1. On the left sidebar, select **Search or go to** and find your group or project.
1. Select **Manage > Members**.
1. Select the **Max role** dropdown list for the member you want to select a custom role for.
1. On the **Change role** dialog, select a different custom role.

### Use the API to assign a custom role

1. Invite a user as a direct member to the root group or any subgroup or project in the root
   group's hierarchy as a Guest. At this point, this Guest user cannot see any
   code on the projects in the group or subgroup.
1. Optional. If you do not know the `id` of the Guest user receiving a custom
   role, find that `id` by making an [API request](../api/member_roles.md).
1. Use the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project) to
   associate the member with the Guest+1 role:

   ```shell
   # to update a project membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": '<member_role_id>', "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

   # to update a group membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": '<member_role_id>', "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
   ```

   Where:

   - `<project_id` and `<group_id>`: The `id` or [URL-encoded path of the project or group](../api/rest/index.md#namespaced-path-encoding) associated with the membership receiving the custom role.
   - `<member_role_id>`: The `id` of the member role created in the previous section.
   - `<user_id>`: The `id` of the user receiving a custom role.

   Now the Guest+1 user can view code on all projects associated with this membership.

## Unassign a custom role from a group or project member

Prerequisites:

If you are unassigning a custom role from a:

- Group member, you must have the Owner role for the group.
- Project member, you must have at least the Maintainer role for the project.

You can remove a custom role from a group or project only if no group or project members have that role. To do this, you can use one of the following methods:

- Remove a member with a custom role from a [group](group/index.md#remove-a-member-from-the-group) or [project](project/members/index.md#remove-a-member-from-a-project).
- [Use the UI to change the user role](#use-the-ui-to-change-user-role).
- [Use the API to change the user role](#use-the-api-to-change-user-role).

### Use the UI to change user role

To remove a custom role from a group member:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Max role** dropdown list for the member you want to remove a custom role from.
1. On the **Change role** dialog, select a default role.

### Use the API to change user role

You can also use the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project) to update or remove a custom role from a group member by passing an empty `member_role_id` value:

```shell
# to update a project membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

# to update a group membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
```

## Inheritance

If a user belongs to a group, they are a _direct member_ of the group
and an [inherited member](project/members/index.md#inherited-membership)
of any subgroups or projects. If a user is assigned a custom role
by the top-level group, the permissions of the role are also inherited by subgroups
and projects.

For example, assume the following structure exists:

- Group A
  - Subgroup B
    - Project 1

If a custom role with Developer + `Manage CI/CD variables` permission is assigned to Group A,
the user also has `Manage CI/CD variables` permission for Subgroup B and Project 1.

## Billing and seat usage

When you enable a custom role for a user with the Guest role, that user has
access to elevated permissions over the base role, and therefore:

- Is considered a [billable user](../subscriptions/self_managed/index.md#billable-users) on self-managed GitLab.
- [Uses a seat](../subscriptions/gitlab_com/index.md#how-seat-usage-is-determined) on GitLab.com.

This does not apply when the user's custom role only has the `read_code` permission
enabled. Guest users with that specific permission only are not considered billable users
and do not use a seat.

## Supported objects

You can assign custom roles and permissions to the following:

| Object       | Version       | Issue                                                  |
| ----         | ----          | ----                                                   |
| Users        | 15.9          | Released                                               |
| Groups       | Not supported | [Issue 443369](https://gitlab.com/gitlab-org/gitlab/-/issues/443369) |
| Tokens       | Not supported | [Issue 434354](https://gitlab.com/gitlab-org/gitlab/-/issues/434354) |

## Supported group links

You can sync users to custom roles with following authentication providers:

- See [Configure SAML Group Links](group/saml_sso/group_sync.md#configure-saml-group-links).
- LDAP Group Links are not supported, but [issue 435229](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)
  proposes to change this.

## Known issues

- If a user with a custom role is shared with a group or project, their custom
  role is not transferred over with them. The user has the regular Guest role in
  the new group or project.
- You cannot use an [Auditor user](../administration/auditor_users.md) as a template for a custom role.
- There can be only 10 custom roles on your instance or namespace. See [issue 450929](https://gitlab.com/gitlab-org/gitlab/-/issues/450929) for more details.
