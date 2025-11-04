---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom roles
description: Create custom roles with tailored permissions to meet specific organizational needs.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Ability to create and remove a custom role with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393235) in GitLab 16.4.
- Ability to use the UI to add a user to your group with a custom role, change a user's custom role, or remove a custom role from a group member [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393239) in GitLab 16.7.
- Ability to create and remove an instance-wide custom role on GitLab Self-Managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562) in GitLab 16.9.
- Custom admin roles [introduced](https://gitlab.com/groups/gitlab-org/-/epics/15854) as an [experiment](../../policy/development_stages_support.md) in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `custom_ability_read_admin_dashboard`.
- Ability to manage custom admin roles with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181346) in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `custom_admin_roles`. Disabled by default.
- Custom admin roles [generally available](https://gitlab.com/groups/gitlab-org/-/epics/15957) in GitLab 18.3. Feature flag `custom_admin_roles` enabled by default.

{{< /history >}}

Custom roles allow you to create roles with only the specific [custom permissions](abilities.md)
required by your organization. Each custom role is based on an existing default role. For example,
you might create a custom role based on the Guest role, but also include permission to view code
in a project repository.

There are two types of custom roles:

- Custom member roles:
  - Can be assigned to members of a group or project.
  - Gains the same permissions in any subgroups or projects. For more information, see [membership types](../../user/project/members/_index.md#membership-types).
  - [Uses a seat](../../subscriptions/manage_users_and_seats.md#gitlabcom-billing-and-usage) and becomes a [billable user](../../subscriptions/manage_users_and_seats.md#billable-users).
    - A custom Guest member role that includes only the `read_code` permission does not use a seat.
- Custom admin roles:
  - Can be assigned to any user on the instance.
  - Gains permissions to perform specific admin actions.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).
<!-- Video published on 2023-02-13 -->

## Create a custom member role

To create a custom member role, you select a default GitLab role and add additional [permissions](abilities.md).
The base role defines the minimum permissions available to the custom role. You cannot use
[auditor](../../administration/auditor_users.md) as a base role.

Custom permissions can allow actions typically restricted to the Maintainer or Owner role. For
example, a custom role with permission to manage CI/CD variables also allows management of CI/CD
variables added by other Maintainers or Owners.

Custom member roles are available to groups and projects:

- On GitLab.com, under the top-level group where the custom role was created.
- On GitLab Self-Managed and GitLab Dedicated, in the entire instance.

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.
- You must have fewer than 10 custom roles.

To create a custom member role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. Select **New role**.
1. GitLab Self-Managed and GitLab Dedicated instances only. Select **Member role**.
1. Enter a name and description for the custom role.
1. From the **Base role** dropdown list, select a default role.
1. Select any permissions for the custom role.
1. Select **Create role**.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberrolecreate) to create a custom role.

## Create a custom admin role

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To create a custom admin role, you add [permissions](abilities.md) that allow actions typically
limited to administrators. Each custom admin role can have one or more permissions.

Prerequisites:

- You must have administrator access to the instance.
- You must have fewer than 10 custom roles.

To create a custom admin role:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. Select **New role**.
1. Select **Admin role**.
1. Enter a name and description for the custom role.
1. Select any permissions for the custom role.
1. Select **Create role**.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberroleadmincreate) to create a custom role.

## Edit a custom role

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/437590) in GitLab 17.0.

{{< /history >}}

You can edit the name, description, and permissions of a custom role, but you cannot edit the
base role. If you need to change the base role, you must create a new custom role.

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To edit a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit role**.
1. Modify the role.
1. Select **Save role**.

You can also use the API to edit a [custom member role](../../api/graphql/reference/_index.md#mutationmemberroleupdate) or a [custom admin role](../../api/graphql/reference/_index.md#mutationmemberroleadminupdate).

## View details of a custom role

The **Roles and permissions** page lists basic information about all available default and custom roles. This
includes information like the name, description, and number of users assigned each custom role. Each custom role
includes either a `Custom member role` or `Custom admin role` badge.

You can also view more detailed information about a custom role including the role ID,
base role, and specific permissions.

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To view details of a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **View details**.

## Delete a custom role

You cannot delete custom roles that are still assigned to a user. See [assign a custom role to a user](#assign-a-custom-member-role).

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To delete a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete role**.
1. On the confirmation dialog, select **Delete role**.

You can also use the API to delete a [custom member role](../../api/graphql/reference/_index.md#mutationmemberroledelete) or a [custom admin role](../../api/graphql/reference/_index.md#mutationmemberroleadmindelete).

## Assign a custom member role

You can assign or modify roles for members of your groups and projects. You can do this for existing users or when you add a user to a
[group](../group/_index.md#add-users-to-a-group),
[project](../project/members/_index.md#add-users-to-a-project),
or [instance](../profile/account/create_accounts.md).

Prerequisites:

- For groups, you must have the Owner role for the group.
- For projects, you must have at least the Maintainer role for the project.

To assign a custom member role to an existing user:

1. On the left sidebar, select **Search or go to** and find your group or project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Manage** > **Members**.
1. In the **Role** column, select the role for an existing member. The **Role details** drawer opens.
1. From the **Role** dropdown list, select a role to assign to the member.
1. Select **Update role** to assign the role.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberroletouserassign) to assign or modify custom role assignments.

## Assign a custom admin role

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can assign or modify admin roles to users in your instance. You can do this for existing users or when you add a user to the [instance](../profile/account/create_accounts.md).

Prerequisites:

- You must be an administrator for the GitLab instance.

To assign a custom admin role to an existing user:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Overview** > **Users**.
1. Select **Edit** for a user.
1. In the **Access** section, set the access level to either **Regular** or **Auditor**.
1. From the **Admin area** dropdown list, select a custom admin role.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberroletouserassign) to assign or modify custom role assignments.

## Assign a custom role to an invited group

{{< history >}}

- Support for custom roles for invited groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443369) in GitLab 17.4 behind a feature flag named `assign_custom_roles_to_group_links_sm`. Disabled by default.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/471999) in GitLab 17.4.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

When you [invite a group to a group](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)
you can assign a custom role to every user in the group.

The assigned role is compared to user roles and permissions in their original group. Generally,
users are assigned the role with the smallest access level. However, if users
have a custom role in their original group:

- Only the base role is used for access level comparisons. Custom permissions are not compared.
- If the custom roles both have the same base role, users keep their custom role from the original group.

The following table provides examples of the maximum role available to users invited to a group:

| Scenario                                                | User with Guest role | User with Guest role + `read_code` | User with Guest role + `read_vulnerability` | User with Developer role     | User with Developer role + `admin_vulnerability` |
| ------------------------------------------------------- | -------------------- | ---------------------------------- | ------------------------------------------- | ---------------------------- | ------------------------------------------------ |
| **Invited with Guest role**                             | Guest                | Guest                            | Guest                                     | Guest                        | Guest                                          |
| **Invited with Guest role + `read_code`**               | Guest                | Guest + `read_code`              | Guest + `read_vulnerability`              | Guest + `read_code`          | Guest + `read_code`                            |
| **Invited with Guest role + `read_vulnerability`**      | Guest                | Guest + `read_code`              | Guest + `read_vulnerability`              | Guest + `read_vulnerability` | Guest + `read_vulnerability`                   |
| **Invited with Developer role**                         | Guest                | Guest + `read_code`              | Guest + `read_vulnerability`              | Developer                    | Developer                                      |
| **Invited with Developer role + `admin_vulnerability`** | Guest                | Guest + `read_code`              | Guest + `read_vulnerability`              | Developer                    | Developer + `admin_vulnerability`              |

You can only assign custom roles when you invite a group to another group. [Issue 468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329) proposes to assign a custom role when inviting a group to a project.

## Supported objects

You can assign custom roles and permissions to the following:

| Object | Version       | Issue |
|--------|---------------|-------|
| Users  | 15.9          | Released |
| Groups | 17.7          | Partially supported. Further support for group assignment in projects is proposed in [Issue 468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329) |
| Tokens | Not supported | [Issue 434354](https://gitlab.com/gitlab-org/gitlab/-/issues/434354) |

## Sync users to custom roles

If you use tools like SAML or LDAP to manage your group membership, you can automatically sync your
users to custom roles. For more information, see:

- [Configure SAML Group Links](../group/saml_sso/group_sync.md#configure-saml-group-links).
- [Manage group memberships via LDAP](../group/access_and_permissions.md#manage-group-memberships-with-ldap).

## Sync LDAP groups to admin roles

You can link a custom admin role to an LDAP group. This link assigns the custom admin role to all users in the group.

If a user belongs to multiple LDAP groups with different assigned custom admin roles, GitLab assigns the role associated with whichever LDAP link was created earlier. For example, if a user is a member of the LDAP groups `owner` and `dev`. If the `owner` group was linked to a custom admin role before the `dev` group, the user would be assigned the role associated with the `owner` group.

For more information on the administration of LDAP and group sync, see [LDAP synchronization](../../administration/auth/ldap/ldap_synchronization.md#group-sync).

{{< alert type="note" >}}

If an LDAP user with a custom admin role is removed from the LDAP group after configuring a sync, the custom role is not removed until the next sync.

{{< /alert >}}

### Link a custom admin role with an LDAP CN

Prerequisites:

- You must have integrated an LDAP server with your instance.

To link a custom admin role with an LDAP CN:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. On the **LDAP Synchronization** tab, select an **LDAP Server**.
1. In the **Sync method** field, select `Group cn`.
1. In the **Group cn** field, begin typing the CN of the group. A dropdown list appears with matching CNs in the configured `group_base`.
1. From the dropdown list, select your CN.
1. In the **Custom admin role** field, select a custom admin role.
1. Select **Add**.

GitLab begins linking the role to any matching LDAP users. This process may take over an hour to complete.

### Link a custom admin role with an LDAP filter

Prerequisites:

- You must have integrated an LDAP server with your instance.

To link a custom admin role with an LDAP filter:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Roles and permissions**.
1. On the **LDAP Synchronization** tab, select an **LDAP Server**.
1. In the **Sync method** field, select `User filter`.
1. In **User filter** box, enter a filter. For details, see [Set up LDAP user filter](../../administration/auth/ldap/_index.md#set-up-ldap-user-filter).
1. In the **Custom admin role** field, select a custom admin role.
1. Select **Add**.

GitLab begins linking the role to any matching LDAP users. This process may take over an hour to complete.

## Contribute new permissions

If a permission does not exist, you can:

- Discuss individual custom role and permission requests in [issue 391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760).
- Create an issue to request the permission with the [permission proposal issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Permission%20Proposal).
- Contribute to GitLab and add the permission.
