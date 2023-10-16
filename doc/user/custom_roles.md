---
stage: Govern
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom roles **(ULTIMATE ALL)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `customizable_roles`.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.
> - The ability for a custom role to view a vulnerability report [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10160) in GitLab 16.1 [with a flag](../administration/feature_flags.md) named `custom_roles_vulnerability`.
> - Ability to view a vulnerability report [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123835) in GitLab 16.1.
> - [Feature flag `custom_roles_vulnerability` removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124049) in GitLab 16.2.
> - Ability to create and remove a custom role with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393235) in GitLab 16.4.
> - Ability to manage group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17364) in GitLab 16.5 under `admin_group_member` Feature flag.
> - Ability to manage project access tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421778) in GitLab 16.5 under `manage_project_access_tokens` Feature flag.

Custom roles allow group members who are assigned the Owner role to create roles
specific to the needs of their organization.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).

The following granular permissions are available. You can add these permissions to any base role, and add them in combination with each other to create a customized role:

- The Guest+1 role, which allows users with the Guest role to view code.
- In GitLab 16.1 and later, you can create a custom role that can view vulnerability reports and change the status of the vulnerabilities.
- In GitLab 16.3 and later, you can create a custom role that can view the dependency list.
- In GitLab 16.4 and later, you can create a custom role that can approve merge requests.
- In GitLab 16.5 and later, you can create a custom role that can manage group members.

You can discuss individual custom role and permission requests in [issue 391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760).

When you enable a custom role for a user with the Guest role, that user has
access to elevated permissions, and therefore:

- Is considered a [billable user](../subscriptions/self_managed/index.md#billable-users) on self-managed GitLab.
- [Uses a seat](../subscriptions/gitlab_com/index.md#how-seat-usage-is-determined) on GitLab.com.

This does not apply to Guest+1, a Guest custom role that only enables the `read_code`
permission. Users with that specific custom role are not considered billable users
and do not use a seat.

## Create a custom role

Prerequisites:

- You must be an administrator for the self-managed instance, or have the Owner
  role in the group you are creating the custom role in.
- The group must be in the Ultimate tier.
- You must have:
  - At least one private project so that you can see the effect of giving a
    user with the Guest role a custom role. The project can be in the group itself
    or one of that group's subgroups.
  - A [personal access token with the API scope](profile/personal_access_tokens.md#create-a-personal-access-token).

### GitLab SaaS

Prerequisite:

- You must have the Owner role in the group you are creating the custom role in.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Roles and Permissions**.
1. Select **Add new role**.
1. In **Base role to use as template**, select **Guest**.
1. In **Role name**, enter the custom role's title.
1. Select the **Permissions** for the new custom role.
1. Select **Create new role**.

### Self Managed GitLab Instances

Prerequisite:

- You must be an administrator for the self-managed instance you are creating the custom role in.

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Settings > Roles and Permissions**.
1. From the top dropdown list, select the group you want to create a custom role in.
1. Select **Add new role**.
1. In **Base role to use as template**, select **Guest**.
1. In **Role name**, enter the custom role's title.
1. Select the **Permissions** for the new custom role.
1. Select **Create new role**.

To create a custom role, you can also [use the API](../api/member_roles.md#add-a-member-role-to-a-group).

### Custom role requirements

For every ability, a minimal access level is defined. To be able to create a custom role which enables a certain ability, the `member_roles` table record has to have the associated minimal access level. For all abilities, the minimal access level is Guest. Only users who have at least the Guest role can be assigned to a custom role.

Some roles and abilities require having other abilities enabled. For example, a custom role can only have administration of vulnerabilities (`admin_vulnerability`) enabled if reading vulnerabilities (`read_vulnerability`) is also enabled.

You can see the abilities requirements in the following table.

| Ability  | Required ability |
| -- | -- |
| `read_code` | - |
| `read_dependency` | - |
| `read_vulnerability` | - |
| `admin_merge_request` | - |
| `admin_vulnerability` | `read_vulnerability` |
| `admin_group_member` | - |
| `manage_project_access_tokens` | - |

## Associate a custom role with an existing group member

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

Prerequisite:

- You must be an administrator or have the Owner role in the group you are removing the custom role from.

You can remove a custom role from a group only if no group members have that role.

To do this, you can either remove the custom role from all group members with that custom role, or remove those members from the group.

### Remove a custom role from a group member

To remove a custom role from a group member, use the [Group and Project Members API endpoint](../api/members.md#edit-a-member-of-a-group-or-project)
and pass an empty `member_role_id` value.

```shell
# to update a project membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": "", "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

# to update a group membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": "", "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
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

1. On the left sidebar, select **Search or go to**.
1. GitLab.com only. Select **Admin Area**.
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
