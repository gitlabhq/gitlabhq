---
stage: Govern
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom roles **(ULTIMATE ALL)**

> - [Custom roles feature introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `customizable_roles`.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.
> - Ability to create and remove a custom role with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393235) in GitLab 16.4.
> - Ability to use the UI to add a user to your group with a custom role, change a user's custom role, or remove a custom role from a group member [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393239) in GitLab 16.7.

Custom roles allow group Owners or instance administrators to create roles
specific to the needs of their organization.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).

You can discuss individual custom role and permission requests in [issue 391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760).

## Available permissions

For more information on available permissions, see [custom permissions](custom_roles/abilities.md).

## Create a custom role

Prerequisites:

- You must be an administrator for the self-managed instance, or have the Owner
  role in the group you are creating the custom role in.
- The group must be in the Ultimate tier.
- You must have:
  - At least one private project so that you can see the effect of giving a
    user a custom role. The project can be in the group itself
    or one of that group's subgroups.
  - If you are using the API to create the custom role, a [personal access token with the API scope](profile/personal_access_tokens.md#create-a-personal-access-token).

You create a custom role by selecting [permissions](#available-permissions) to add
to a base role.

You can select any number of permissions. For example, you can create a custom role
with the permission to:

- View vulnerability reports.
- Change the status of vulnerabilities.
- Approve merge requests.

### GitLab SaaS

Prerequisites:

- You must have the Owner role in the group you are creating the custom role in.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Roles and Permissions**.
1. Select **Add new role**.
1. In **Base role to use as template**, select an existing non-custom role.
1. In **Role name**, enter the custom role's title.
1. Optional. In **Description**, enter a description for the custom role.
1. Select the **Permissions** for the new custom role.
1. Select **Create new role**.

In **Settings > Roles and Permissions**, the list of all custom roles displays the:

- Custom role name.
- Role ID.
- Base role that the custom role uses as a template.
- Permissions.

### Self Managed GitLab Instances

Prerequisites:

- You must be an administrator for the self-managed instance you are creating the custom role in.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Roles and Permissions**.
1. From the top dropdown list, select the group you want to create a custom role in.
1. Select **Add new role**.
1. In **Base role to use as template**, select an existing non-custom role.
1. In **Role name**, enter the custom role's title.
1. Optional. In **Description**, enter a description for the custom role.
1. Select the **Permissions** for the new custom role.
1. Select **Create new role**.

In **Settings > Roles and Permissions**, the list of all custom roles displays the:

- Custom role name.
- Role ID.
- Base role that the custom role uses as a template.
- Permissions.

To create a custom role, you can also [use the API](../api/member_roles.md#add-a-member-role-to-a-group).

## Billing and seat usage

When you enable a custom role for a user with the Guest role, that user has
access to elevated permissions over the base role, and therefore:

- Is considered a [billable user](../subscriptions/self_managed/index.md#billable-users) on self-managed GitLab.
- [Uses a seat](../subscriptions/gitlab_com/index.md#how-seat-usage-is-determined) on GitLab.com.

This does not apply when the user's custom role only has the `read_code` permission
enabled. Guest users with that specific permission only are not considered billable users
and do not use a seat.

## Add a user to your group with a custom role

Prerequisites:

- You must be an administrator, or have the Owner role in the group you are creating the custom role in.

To add a user to your group with a custom role:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select **Invite members**.
1. In **Username or email address**, if the user:
   - Has a GitLab account, enter their username.
   - Does not have a GitLab account, enter their email address.
1. In **Select a role**, select a static or custom role.
1. Optional. In **Access expiration date (optional)**, enter or select a date.
   From that date onward, the user can no longer access the group.
1. Select **Invite**. If you invite the user by their:
   - GitLab username, the user is added to the member list.
   - Email address, the user receives an email invitation and is prompted to create an account.
     If the invitation is not accepted, GitLab sends reminder emails two, five, and ten days later.
     Unaccepted invites are automatically deleted after 90 days.

The new member with custom role and custom permissions appears on the [group's members list](group/index.md#view-group-members).

NOTE:
Most custom roles are considered [billable users that use a seat](#billing-and-seat-usage). When you add a user to your group with a custom role, a warning is displayed if you are about to incur additional charges for having more seats than are included in your subscription.

### Change a member's custom role

To change a group member's custom role:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Max role** dropdown list for the member you want to select a custom role for.
1. On the **Change role** dialog, select a different custom role.

### Associate a custom role with an existing group member

You can use the API to associate a custom role with an existing group member.

Prerequisites:

- You must have the Owner role for the group.

To associate a custom role with an existing group member, a group member with
the Owner role:

1. Invites a user as a direct member to the root group or any subgroup or project in the root
   group's hierarchy as a Guest. At this point, this Guest user cannot see any
   code on the projects in the group or subgroup.
1. Optional. If the Owner does not know the `id` of the Guest user receiving a custom
   role, finds that `id` by making an [API request](../api/member_roles.md#list-all-member-roles-of-a-group).

1. Associates the member with the Guest+1 role using the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project)

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

## Remove a custom role

Prerequisites:

- You must be an administrator, or have the Owner role in the group you are removing the custom role from.

You can remove a custom role from a group only if no group members have that role.

To do this, you can either remove the custom role from all group members with that custom role, or remove those members from the group.

### Remove a custom role from a group member

To remove a custom role from a group member:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Max role** dropdown list for the member you want to remove a custom role from.
1. On the **Change role** dialog, select a static role.

You can also use the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project)
to update or remove a custom role from a group member by passing an empty `member_role_id` value:

```shell
# to update a project membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

# to update a group membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
```

### Remove a group member with a custom role from the group

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. On the member row you want to remove, select the vertical ellipsis
   (**{ellipsis_v}**) and select **Remove member**.
1. In the **Remove member** confirmation dialog, do not select any checkboxes.
1. Select **Remove member**.

### Delete the custom role

After you have made sure no group members have that custom role, delete the
custom role.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Roles and Permissions**.
1. Select **Custom Roles**.
1. In the **Actions** column, select **Delete role** (**{remove}**) and confirm.

To delete a custom role, you can also [use the API](../api/member_roles.md#remove-member-role-of-a-group).
To use the API, you must know the `id` of the custom role. If you do not know this
`id`, find it by making an [API request](../api/member_roles.md#list-all-member-roles-of-a-group).

## Known issues

- If a user with a custom role is shared with a group or project, their custom
  role is not transferred over with them. The user has the regular Guest role in
  the new group or project.
- You cannot use an [Auditor user](../administration/auditor_users.md) as a template for a custom role.
