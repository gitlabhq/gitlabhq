---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Groups **(FREE ALL)**

In GitLab, you use groups to manage one or more related projects at the same time.

You can use groups to manage permissions for your projects. If someone has access to
the group, they get access to all the projects in the group.

You can also view all of the issues and merge requests for the projects in the group,
and view analytics that show the group's activity.

You can use groups to communicate with all of the members of the group at once.

For larger organizations, you can also create [subgroups](subgroups/index.md).

For more information about creating and managing your groups, see [Manage groups](manage.md).

NOTE:
For self-managed customers it could be beneficial to create one single top-level group, so you can see an overview of
your entire organization. For more information about efforts to create an
organization view of all groups, [see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
A single top-level group provides insights in your entire organization via a complete
[Security Dashboard and Center](../application_security/security_dashboard/index.md),
[Vulnerability](../application_security/vulnerability_report/index.md#vulnerability-report) and
[Compliance center](../compliance/compliance_center/index.md), and
[Value stream analytics](../group/value_stream_analytics/index.md).

## Group visibility

Like projects, a group can be configured to limit the visibility of it to:

- Anonymous users.
- All authenticated users.
- Only explicit group members.

The restriction for [visibility levels](../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)
on the application setting level also applies to groups. If set to internal, the explore page is
empty for anonymous users. The group page has a visibility level icon.

Administrator users cannot create a subgroup or project with a higher visibility level than that of
the immediate parent group.

## View groups

To explore all public groups:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my groups**.
1. At the top right, select **Explore groups**.

To view groups where you have a direct or indirect membership:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my groups**.

This page shows groups that you are a member of:

- Through membership of a subgroup's parent group.
- Through direct or inherited membership of a project in the group or subgroup.

## View group activity

To view the activity of a project:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Activity**.
1. Optional. To filter activity by contribution type, select a tab:

   - **All**: All contributions by group members in the group and group's projects.
   - **Push events**: Push events in the group's projects.
   - **Merge events**: Accepted merge requests in the group's projects.
   - **Issue events**: Issues opened and closed in the group's projects.
   - **Epic events**: Epics opened and closed in the group.
   - **Comments**: Comments posted by group members in the group's projects.
   - **Wiki**: Updates to wiki pages in the group.
   - **Designs**: Designs added, updated, and removed in the group's projects.
   - **Team**: Group members who joined and left the group's projects.

## Create a group

To create a group:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**.
1. Select **Create group**.
1. Enter a name for the group in **Group name**. For a list of words that cannot be used as group names, see
   [reserved names](../reserved_names.md).
1. Enter a path for the group in **Group URL**, which is used for the [namespace](../namespace/index.md).
1. Choose the [visibility level](../public_access.md).
1. Personalize your GitLab experience by answering the following questions:
   - What is your role?
   - Who is using this group?
   - What are you using this group for?
1. Invite GitLab members or other users to join the group.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For details about groups, watch [GitLab Namespaces (users, groups and subgroups)](https://youtu.be/r0sJgjR2f5A).

## Remove a group

> Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

To remove a group and its contents:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Remove group** section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

A group can also be removed from the groups dashboard:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my groups**.
1. Select (**{ellipsis_v}**) for the group you want to delete.
1. Select **Delete**.
1. In the Remove group section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

This action removes the group. It also adds a background job to delete all projects in the group.

In [GitLab 12.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/33257), on GitLab [Premium](https://about.gitlab.com/pricing/premium/) and [Ultimate](https://about.gitlab.com/pricing/ultimate/), this action adds a background job to mark a group for deletion. By default, the job schedules the deletion seven days in the future. You can modify this retention period through the [instance settings](../../administration/settings/visibility_and_access_controls.md#deletion-protection).

In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/39504), if the user who sets up the deletion is removed from the group before the deletion happens, the job is cancelled, and the group is no longer scheduled for deletion.

## Remove a group immediately **(PREMIUM ALL)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336985) in GitLab 14.2.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

If you don't want to wait, you can remove a group immediately.

Prerequisites:

- You must have the Owner role for a group.
- You have [marked the group for deletion](#remove-a-group).

To immediately remove a group marked for deletion:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the "Permanently remove group" section, select **Remove group**.
1. Confirm the action when asked to.

Your group, its subgroups, projects, and all related resources, including issues and merge requests,
are deleted.

## Restore a group **(PREMIUM ALL)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

To restore a group that is marked for deletion:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. In the Restore group section, select **Restore group**.

## Request access to a group

As a user, you can request to be a member of a group, if an administrator allows it.

1. On the left sidebar, select **Search or go to**.
1. Select **View all my groups**.
1. At the top right side, select **Explore groups**.
1. Search for the group by name.
1. In the search results, select the name of the group.
1. On the group page, under the group name, select **Request Access**.

As many as ten of the most-recently-active group owners receive an email with your request.
Any group owner can approve or decline the request.

If you change your mind before your request is approved, select
**Withdraw Access Request**.

## View group members

To view a group's members:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.

A table displays the member's:

- **Account** name and username
- **Source** of their [membership](../project/members/index.md#membership-types).
   For transparency, GitLab displays all membership sources of group members.
   Members who have multiple membership sources are displayed and counted as separate members.
   For example, if a member has been added to the group both directly and through inheritance,
   the member is displayed twice in the **Members** table, with different sources,
   and is counted as two individual members of the group.
- [**Max role**](../project/members/index.md#which-roles-you-can-assign) in the group
- **Expiration** date of their group membership
- **Activity** related to their account

NOTE:
The display of group members' **Source** might be inconsistent.
For more information, see [issue 414557](https://gitlab.com/gitlab-org/gitlab/-/issues/414557).

## Filter and sort members in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21727) in GitLab 12.6.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/228675) in GitLab 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/289911) in GitLab 13.8.

To find members in a group, you can sort, filter, or search.

### Filter a group

Filter a group to find members. By default, all members in the group and subgroups are displayed.

In lists of group members, entries can display the following badges:

- **SAML**, to indicate the member has a [SAML account](saml_sso/index.md) connected to them.
- **Enterprise**, to indicate that the member is an [enterprise user](../enterprise_user/index.md).

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Above the list of members, in the **Filter members** box, enter filter criteria.
   - To view members in the group only, select **Membership = Direct**.
   - To view members of the group and its subgroups, select **Membership = Inherited**.
   - To view members with two-factor authentication enabled or disabled, select **2FA = Enabled** or **Disabled**.
   - [In GitLab 14.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/349887), to view GitLab users created by [SAML SSO](saml_sso/index.md) or [SCIM provisioning](saml_sso/scim_setup.md) select **Enterprise = true**.

### Search a group

You can search for members by name, username, or [public email](../profile/index.md#set-your-public-email).

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Above the list of members, in the **Filter members** box, enter search criteria.
1. To the right of the **Filter members** box, select the magnifying glass (**{search}**).

### Sort members in a group

You can sort members by **Account**, **Access granted**, **Max role**, or **Last sign-in**.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Above the list of members, in the upper-right corner, from the **Account** list, select
   the criteria to filter by.
1. To switch the sort between ascending and descending, to the right of the **Account** list, select the
   arrow (**{sort-lowest}** or **{sort-highest}**).

## Add users to a group

> Expiring access email notification [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12704) in GitLab 16.2.

You can give a user access to all projects in a group.

Prerequisite:

- You must have the Owner role.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select **Invite members**.
1. Fill in the fields.
   - The role applies to all projects in the group. For more information, see [permissions](../permissions.md).
   - Optional. Select an **Access expiration date**. From that date onward, the
     user can no longer access the project.
1. Select **Invite**.

If you selected an access expiration date, the group member gets an email notification
seven days before their access expires.

Members that are not automatically added are displayed on the **Invited** tab.
Users can be on this tab because they:

- Have not yet accepted the invitation.
- Are waiting for [approval from an administrator](../admin_area/moderate_users.md).
- [Exceed the group user cap](manage.md#user-cap-for-groups).

## Remove a member from the group

Prerequisites:

- You must have the Owner role.
- The member must have direct membership in the group. If
  membership is inherited from a parent group, then the member can be removed
  from the parent group only.

To remove a member from a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Next to the member you want to remove, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Remove member**.
1. Optional. On the **Remove member** confirmation box:
   - To remove direct user membership from subgroups and projects, select the **Also remove direct user membership from subgroups and projects** checkbox.
   - To unassign the user from linked issues and merge requests, select the **Also unassign this user from linked issues and merge requests** checkbox.
1. Select **Remove member**.

## Ensure removed users cannot invite themselves back

Malicious users with the Maintainer or Owner role could exploit a race condition that allows
them to invite themselves back to a group or project that a GitLab administrator has removed them from.

To avoid this problem, GitLab administrators can [ensure removed users cannot invite themselves back](../project/members/index.md#ensure-removed-users-cannot-invite-themselves-back).

## Add projects to a group

There are two different ways to add a new project to a group:

- Select a group, and then select **New project**. You can then continue [creating your project](../../user/project/index.md).
- While you are creating a project, select a group from the dropdown list.

  ![Select group](img/select_group_dropdown_13_10.png)

### Specify who can add projects to a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2534) in GitLab 10.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25975) from GitLab Premium to GitLab Free in 11.10.

By default, users with:

- At least the Developer role can create projects under a group. This default can be changed.
- At least the Maintainer role can fork projects into a group. This default prevents users with the Developer role from forking projects that
  contain protected branches and cannot be changed.

To change the role that can create projects under a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select the desired option in the **Roles allowed to create projects** dropdown list.
1. Select **Save changes**.

To change this setting globally, see [Default project creation protection](../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
