---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom roles
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Custom roles feature introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../../administration/feature_flags.md) named `customizable_roles`.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.
- Ability to create and remove a custom role with the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393235) in GitLab 16.4.
- Ability to use the UI to add a user to your group with a custom role, change a user's custom role, or remove a custom role from a group member [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393239) in GitLab 16.7.
- Ability to create and remove an instance-wide custom role on GitLab Self-Managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562) in GitLab 16.9.

{{< /history >}}

Custom roles allow you to create roles with only the specific [custom permissions](abilities.md)
required by your organization. Each custom role is based on an existing default role. For example,
you might create a custom role based on the Guest role, but also include permission to view code
in a project repository.

When you assign a custom role to a user:

- They gain the same permissions for any subgroups or projects within the group they belong to. For more information, see [membership types](../../user/project/members/_index.md#membership-types).
- They [use a seat](../../subscriptions/gitlab_com/_index.md#how-seat-usage-is-determined) or become a [billable user](../../subscriptions/self_managed/_index.md#billable-users).
  - Custom Guest roles that include only the `read_code` permission do not use a seat.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the custom roles feature, see [[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps).
<!-- Video published on 2023-02-13 -->

{{< alert type="warning" >}}

Custom roles can allow users to perform actions usually restricted to the Maintainer role or higher.
For example, if a custom role includes permission to manage CI/CD variables, users with the role
could also manage CI/CD variables added by other Maintainers or Owners for the group or project.

{{< /alert >}}

## Create a custom role

To create a custom role, add [permissions](abilities.md) to a base role. Each custom role can
have one or more permissions. For example, you might base a custom role on the Reporter role,
but also include permission to view vulnerability reports, change the status of vulnerabilities,
and approve merge requests.

Custom roles are available to groups and projects:

- On GitLab.com, under the top-level group where the custom role was created.
- On GitLab Self-Managed and GitLab Dedicated, in the entire instance.

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To create a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**.
1. Select **Settings > Roles and permissions**.
1. Select **New role**.
1. Enter a name and description for the custom role.
1. From the **Base role** dropdown list, select a default role.
1. Select any permissions for the custom role.
1. Select **Create role**.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberrolecreate) to create a custom role.

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
   - For GitLab.com, select **Search or go to** and find your group.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**.
1. Select **Settings > Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit role**.
1. Modify the role.
1. Select **Save role**.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberroleupdate) to edit a custom role.

## View details of a custom role

The **Roles and permissions** page lists basic information about all available default and custom roles. This
includes information like the name, description, and number of users assigned each custom role. Custom roles
are labeled with a `Custom member role` badge.

You can also view more detailed information about a custom role including the role ID,
base role, and specific permissions.

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To view details of a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**.
1. Select **Settings > Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **View details**.

## Delete a custom role

You cannot delete custom roles currently assigned to a user. See [assign a custom role to a user](#assign-a-custom-role-to-a-user).

Prerequisites:

- For GitLab.com, you must have the Owner role for the group.
- For GitLab Self-Managed and GitLab Dedicated, you must have administrator access to the instance.

To delete a custom role:

1. On the left sidebar:
   - For GitLab.com, select **Search or go to** and find your group.
   - For GitLab Self-Managed and GitLab Dedicated, at the bottom, select **Admin**.
1. Select **Settings > Roles and permissions**.
1. Next to a custom role, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete role**.
1. On the confirmation dialog, select **Delete role**.

You can also [use the API](../../api/graphql/reference/_index.md#mutationmemberroledelete) to delete a custom role.

## Assign a custom role to a user

You can assign or modify roles for members of your groups and projects. This can be done for existing
users or when you add a user to the
[group](../group/_index.md#add-users-to-a-group) or
[project](../project/members/_index.md#add-users-to-a-project).

Prerequisites:

- For groups, you must have the Owner role for the group.
- For projects, you must have at least the Maintainer role for the project.

To assign a role to an existing user:

1. On the left sidebar, select **Search or go to** and find your group or project.
1. Select **Manage > Members**.
1. In the **Role** column, select the role for an existing member. The **Role details** drawer opens.
1. From the **Role** dropdown list, select a role to assign to the member.
1. Select **Update role** to assign the role.

You can also use the [group and project members API](../../api/members.md#edit-a-member-of-a-group-or-project) to assign or modify role assignments.

## Assign a custom role to an invited group

{{< history >}}

- Support for custom roles for invited groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443369) in GitLab 17.4 behind a feature flag named `assign_custom_roles_to_group_links_sm`. Disabled by default.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/471999) in GitLab 17.4.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

When a group is invited to another group with a custom role, the following rules determine each user's custom permissions in the new group:

- When a user has a custom permission in one group with a base access level that is the same or higher than the default role in the other group, the user's maximum role is the default role. That is, the user is granted the lower of the two access levels.
- When a user is invited with a custom permission with the same base access level as their original group, the user is always granted the custom permission from their original group.

For example, consider Group A with 5 users assigned the following roles:

- User A: Guest role
- User B: Guest role + `read_code` custom permission
- User C: Guest role + `read_vulnerability` custom permission
- User D: Developer role
- User E: Developer + `admin_vulnerability` custom permission

Group B invites Group A. The following table shows the maximum role that each the users in Group A will have in Group B:

| Scenario                                                       | User A | User B              | User C                       | User D                       | User E                            |
|----------------------------------------------------------------|--------|---------------------|------------------------------|------------------------------|-----------------------------------|
| Group B invites Group A with Guest                             | Guest  | Guest               | Guest                        | Guest                        | Guest                             |
| Group B invites Group A with Guest + `read_code`               | Guest  | Guest + `read_code` | Guest + `read_vulnerability` | Guest + `read_code`          | Guest + `read_code`               |
| Group B invites Group A with Guest + `read_vulnerability`      | Guest  | Guest + `read_code` | Guest + `read_vulnerability` | Guest + `read_vulnerability` | Guest + `read_vulnerability`      |
| Group B invites Group A with Developer                         | Guest  | Guest + `read_code` | Guest + `read_vulnerability` | Developer                    | Developer                         |
| Group B invites Group A with Developer + `admin_vulnerability` | Guest  | Guest + `read_code` | Guest + `read_vulnerability` | Developer                    | Developer + `admin_vulnerability` |

When User C is invited to Group B with the same default role (Guest), but different custom permissions with the same base access level (`read_code` and `read_vulnerability`), User C retains the custom permission from Group A (`read_vulnerability`).
The ability to assign a custom role when sharing a group to a project can be tracked in [issue 468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329).

## Supported objects

You can assign custom roles and permissions to the following:

| Object       | Version       | Issue                                                  |
| ----         | ----          | ----                                                   |
| Users        | 15.9          | Released                                               |
| Groups       | 17.7          | Partially supported. Further support for group assignment in projects is proposed in [Issue 468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329)  |
| Tokens       | Not supported | [Issue 434354](https://gitlab.com/gitlab-org/gitlab/-/issues/434354) |

## Sync users to custom roles

If you use tools like SAML or LDAP to manage your group membership, you can automatically sync your
users to custom roles. For more information, see:

- [Configure SAML Group Links](../group/saml_sso/group_sync.md#configure-saml-group-links).
- [Manage group memberships via LDAP](../group/access_and_permissions.md#manage-group-memberships-with-ldap).

## Custom admin roles

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15854) as an [experiment](../../policy/development_stages_support.md) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `custom_ability_read_admin_dashboard`.

{{< /history >}}

Prerequisites:

- You must be an administrator for the GitLab Self-Managed instance.

You can use the API to [create](../../api/graphql/reference/_index.md#mutationmemberroleadmincreate) and [assign](../../api/graphql/reference/_index.md#mutationmemberroletouserassign) custom admin roles. These roles allow you to grant limited access to administrator resources.

For information on available permissions, see [custom permissions](abilities.md).

## Contribute new permissions

If a permission does not exist, you can:

- Discuss individual custom role and permission requests in [issue 391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760).
- Create an issue to request the permission with the [permission proposal issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Permission%2520Proposal).
- Contribute to GitLab and add the permission.

## Known issues

- If a user with a custom role is shared with a group or project, their custom
  role is not transferred over with them. The user has the regular Guest role in
  the new group or project.
- You cannot use an [Auditor user](../../administration/auditor_users.md) as a template for a custom role.
- There can be only 10 custom roles on your instance or namespace. See [issue 450929](https://gitlab.com/gitlab-org/gitlab/-/issues/450929) for more details.
