---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Manage groups

Use groups to manage one or more related projects at the same time.

NOTE:
Self-managed customers should create a top-level group so you can see an overview of
your organization. For more information about efforts to create an
organization view of all groups, [see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
A top-level group can also have one complete
[Security Dashboard and Center](../application_security/security_dashboard/index.md),
[Vulnerability](../application_security/vulnerability_report/index.md#vulnerability-report) and
[Compliance Report](../compliance/compliance_report/index.md), and
[Value stream analytics](../group/value_stream_analytics/index.md).

## View groups

To view groups, on the top bar, select **Main menu > Groups > View all groups**.

The **Groups** page shows a list of groups, sorted by last updated date.

- To explore all public groups, select **Explore groups**.
- To view groups where you have a direct or indirect membership, select **Your groups**. This tab shows groups that you are a member of:
  - Through membership of a subgroup's parent group.
  - Through direct or inherited membership of a project in the group or subgroup.

## Create a group

To create a group:

1. On the top bar, either:
   - Select **Main menu > Groups > View all groups**, and on the right, select **New group**.
   - To the left of the search box, select the plus sign and then **New group**.
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

To remove a group and its contents:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Remove group** section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

A group can also be removed from the groups dashboard:

1. On the top bar, select **Main menu > Groups > View all groups**.
1. Select **Your Groups**.
1. Select (**{ellipsis_v}**) for the group you want to delete.
1. Select **Delete**.
1. In the Remove group section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

This action removes the group. It also adds a background job to delete all projects in the group.

Specifically:

- In [GitLab 12.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/33257), on [GitLab Premium or Ultimate tiers](https://about.gitlab.com/pricing/premium/), this action adds a background job to mark a group for deletion. By default, the job schedules the deletion 7 days in the future. You can modify this waiting period through the [instance settings](../admin_area/settings/visibility_and_access_controls.md#deletion-protection).

- In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/39504), if the user who sets up the deletion is removed from the group before the
  deletion happens, the job is cancelled, and the group is no longer scheduled for deletion.

## Remove a group immediately **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336985) in GitLab 14.2.

If you don't want to wait, you can remove a group immediately.

Prerequisites:

- You must have the Owner role for a group.
- You have [marked the group for deletion](#remove-a-group).

To immediately remove a group marked for deletion:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the "Permanently remove group" section, select **Remove group**.
1. Confirm the action when asked to.

Your group, its subgroups, projects, and all related resources, including issues and merge requests,
are deleted.

## Restore a group **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

To restore a group that is marked for deletion:

1. On the top bar, select **Main menu > Groups** and find your group.
1. Select **Settings > General**.
1. Expand the **Path, transfer, remove** section.
1. In the Restore group section, select **Restore group**.

## Request access to a group

As a user, you can request to be a member of a group, if an administrator allows it.

1. On the top bar, select **Main menu > Groups** and find your group.
1. Under the group name, select **Request Access**.

As many as ten of the most-recently-active group owners receive an email with your request.
Any group owner can approve or decline the request.

If you change your mind before your request is approved, select
**Withdraw Access Request**.

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

1. On the top bar, select **Main menu > Groups** and find your group.
1. Above the list of members, in the **Filter members** box, enter filter criteria.
   - To view members in the group only, select **Membership = Direct**.
   - To view members of the group and its subgroups, select **Membership = Inherited**.
   - To view members with two-factor authentication enabled or disabled, select **2FA = Enabled** or **Disabled**.
   - [In GitLab 14.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/349887), to view GitLab users created by [SAML SSO](saml_sso/index.md) or [SCIM provisioning](saml_sso/scim_setup.md) select **Enterprise = true**.

### Search a group

You can search for members by name, username, or email.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Above the list of members, in the **Filter members** box, enter search criteria.
1. To the right of the **Filter members** box, select the magnifying glass (**{search}**).

### Sort members in a group

You can sort members by **Account**, **Access granted**, **Max role**, or **Last sign-in**.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Above the list of members, in the upper-right corner, from the **Account** list, select
   the criteria to filter by.
1. To switch the sort between ascending and descending, to the right of the **Account** list, select the
   arrow (**{sort-lowest}** or **{sort-highest}**).

## Add users to a group

You can give a user access to all projects in a group.

Prerequisite:

- You must have the Owner role.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Select **Invite members**.
1. Fill in the fields.
   - The role applies to all projects in the group. For more information, see [permissions](../permissions.md).
   - On the **Access expiration date**, the user can no longer access projects in the group.
1. Select **Invite**.

Members that are not automatically added are displayed on the **Invited** tab.
Users can be on this tab because they:

- Have not yet accepted the invitation.
- Are waiting for [approval from an administrator](../admin_area/moderate_users.md).
- [Exceed the group user cap](#user-cap-for-groups).

## Remove a member from the group

Prerequisites:

- You must have the Owner role.
- The member must have direct membership in the group. If
  membership is inherited from a parent group, then the member can be removed
  from the parent group only.

To remove a member from a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Next to the member you want to remove, select **Remove member**.
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

- Select a group, and then select **New project**. You can then continue [creating your project](../../user/project/index.md#create-a-project).
- While you are creating a project, select a group from the dropdown list.

  ![Select group](img/select_group_dropdown_13_10.png)

### Specify who can add projects to a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2534) in GitLab 10.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25975) from GitLab Premium to GitLab Free in 11.10.

By default, users with at least the Developer role can create projects under a group.

To change this setting for a specific group:

1. On the top bar, select **Main menu > Groups > View all groups**.
1. Select **Your Groups**.
1. Find the group and select it.
1. From the left menu, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select the desired option in the **Roles allowed to create projects** dropdown list.
1. Select **Save changes**.

To change this setting globally, see [Default project creation protection](../admin_area/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).

## Add Group README

As a group owner or member, you can use a README to provide more information about your team, and invite users to contribute to your projects.
The README is displayed on the group overview page, and can be changed in the group settings. All group members can edit the README.

Prerequisite:

- To create the README from the group settings, you must have the Owner role for the group.

To add a group README:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. In the **Group README** section, select **Add README**. This action creates a new project `gitlab-profile` that contains the `README.md` file.
1. On the prompt for creating a README, select **Create and add README**. You're redirected to the Web IDE, where a README file is created.
1. In the Web IDE, edit and commit the `README.md` file.

## Change the owner of a group

You can change the owner of a group. Each group must always have at least one
member with the Owner role.

- As an administrator:
  1. On the top bar, select **Main menu > Groups** and find your group.
  1. On the left sidebar, select **Group information > Members**.
  1. Give a different member the **Owner** role.
  1. Refresh the page. You can now remove the **Owner** role from the original owner.
- As the current group's owner:
  1. On the top bar, select **Main menu > Groups** and find your group.
  1. On the left sidebar, select **Group information > Members**.
  1. Give a different member the **Owner** role.
  1. Have the new owner sign in and remove the **Owner** role from you.

## Change a group's path

Changing a group's path (group URL) can have unintended side effects. Read
[how redirects behave](../project/repository/index.md#what-happens-when-a-repository-path-changes)
before you proceed.

If you are changing the path so it can be claimed by another group or user,
you must rename the group too. Both names and paths must
be unique.

After you change the group path, the new group path is a new namespace and you must update the existing project URL in the following resources:

- [Include statements](../../ci/yaml/includes.md#include-a-single-configuration-file).
- Docker image references in CI files.
- Variables that specify a project or namespace.

To retain ownership of the original namespace and protect the URL redirects,
create a new group and transfer projects to it instead.

To change your group path (group URL):

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General** page.
1. Expand the **Advanced** section.
1. Under **Change group URL**, enter a new name.
1. Select **Change group URL**.

WARNING:
It is not possible to rename a namespace if it contains a
project with [Container Registry](../packages/container_registry/index.md) tags,
because the project cannot be moved.

## Change the default branch protection of a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7583) in GitLab 12.9.
> - [Settings moved and renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/340403) in GitLab 14.9.

By default, every group inherits the branch protection set at the global level.

To change this setting for a specific group, see [group level default branch protection](../project/repository/branches/default.md#group-level-default-branch-protection).

To change this setting globally, see [initial default branch protection](../project/repository/branches/default.md#instance-level-default-branch-protection).

NOTE:
In [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), GitLab administrators can choose to [disable group owners from updating the default branch protection](../project/repository/branches/default.md#prevent-overrides-of-default-branch-protection).

## Use a custom name for the initial branch

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43290) in GitLab 13.6.

When you create a new project in GitLab, a default branch is created with the
first push. The group owner can
[customize the initial branch](../project/repository/branches/default.md#group-level-custom-initial-branch-name)
for the group's projects to meet your group's needs.

## Share a group with another group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18328) in GitLab 12.7.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal window [with a flag](../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9.
    [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

Similar to how you [share a project with a group](../project/members/share_project_with_groups.md),
you can share a group with another group. To invite a group, you must be a member of it.
To share a given group, for example, `Frontend` with another group, for example,
`Engineering`:

1. Go to the `Frontend` group.
1. On the left sidebar, select **Group information > Members**.
1. Select **Invite a group**.
1. In the **Select a group to invite** list, select `Engineering`.
1. Select a [role](../permissions.md) as maximum access level.
1. Select **Invite**.

After sharing the `Frontend` group with the `Engineering` group:

- The **Groups** tab lists the `Engineering` group.
- The **Groups** tab lists a group regardless of whether it is a public or private group.
- All direct members of the `Engineering` group have access to the `Frontend` group. Direct members of `Engineering` that gain access to the `Frontend` group keep their same access level as in `Engineering`, but up to the maximum access level selected when sharing the group. Inherited members of the `Engineering` group do not gain access to the `Frontend` group.

## Transfer a group

Transferring groups moves them from one place to another in the same GitLab instance. You can:

- Transfer a subgroup to a new parent group.
- Convert a top-level group into a subgroup by transferring it to the desired group.
- Convert a subgroup into a top-level group by transferring it out of its current group.

If you need to copy a group to a different GitLab instance,
[migrate the group by direct transfer](import/index.md#migrate-groups-by-direct-transfer-recommended).

When transferring groups, note:

- Changing a group's parent can have unintended side effects. See [what happens when a repository path changes](../project/repository/index.md#what-happens-when-a-repository-path-changes).
- You must have the Owner role in the source and target group.
- You must update your local repositories to point to the new location.
- If the immediate parent group's visibility is lower than the group's current visibility, visibility levels for subgroups and projects change to match the new parent group's visibility.
- Only explicit group membership is transferred, not inherited membership. If the group's owners have only inherited membership, this leaves the group without an owner. In this case, the user transferring the group becomes the group's owner.
- Transfers fail if [npm packages](../packages/npm_registry/index.md) exist in any of the projects in the group, or in any of its subgroups.
- Existing packages that use a group-level endpoint (Maven, NuGet, PyPI, Composer, and Debian) need to be updated per the package's steps for setting up the group level endpoint.
- Existing package names need to be updated if the package uses an instance level endpoint ([Maven](../packages/maven_repository/index.md#naming-convention), [npm](../packages/npm_registry/index.md#naming-convention), [Conan](../packages/conan_repository/index.md#package-recipe-naming-convention-for-instance-remotes)) and the group was moved to another root level namespace.
- [Maven packages](../packages/maven_repository/index.md#naming-convention) follow a naming convention that prevent installing or publishing the respective package from a group level endpoint after group transfer.
- Top-level groups that have a subscription on GitLab.com cannot be transferred. To make the transfer possible, the top-level group's subscription must be removed first. Then the top-level group can be transferred as a subgroup to another top-level group.

To transfer a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Remove group** section, select **Transfer group**.
1. Select the group name in the drop down menu.
1. Select **Transfer group**.

## Enable delayed project deletion **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.
> - [Inheritance and enforcement added](https://gitlab.com/gitlab-org/gitlab/-/issues/321724) in GitLab 13.11.
> - [Instance setting to enable by default added](https://gitlab.com/gitlab-org/gitlab/-/issues/255449) in GitLab 14.2.
> - [Instance setting is inherited and enforced when disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.
> - [User interface changed](https://gitlab.com/gitlab-org/gitlab/-/issues/352961) in GitLab 15.1.
> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `always_perform_delayed_deletion`. Disabled by default.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) on May 08, 2023.
> - Enabled delayed deletion by default and removed the option to delete immediately [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

[Delayed project deletion](../project/settings/index.md#delayed-project-deletion) is locked and disabled unless the instance-level settings for
[deletion protection](../admin_area/settings/visibility_and_access_controls.md#deletion-protection) are enabled for either groups only or groups and projects.
When enabled on groups, projects in the group are deleted after a period of delay. During this period, projects are in a read-only state and can be restored.
The default period is seven days but [is configurable at the instance level](../admin_area/settings/visibility_and_access_controls.md#retention-period).

On self-managed GitLab, projects are deleted immediately by default.
In GitLab 14.2 and later, an administrator can
[change the default setting](../admin_area/settings/visibility_and_access_controls.md#deletion-protection)
for projects in newly-created groups.

On GitLab.com, see the [GitLab.com settings page](../gitlab_com/index.md#delayed-project-deletion) for
the default setting.

To enable delayed deletion of projects in a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Scroll to:
   - (GitLab 15.1 and later) **Deletion protection** and select **Keep deleted projects**.
   - (GitLab 15.0 and earlier) **Enable delayed project deletion** and tick the checkbox.
1. Optional. To prevent subgroups from changing this setting, select:
   - (GitLab 15.1 and later), **Enforce deletion protection for all subgroups**
   - (GitLab 15.0 and earlier), **Enforce for all subgroups**.
1. Select **Save changes**.

In GitLab 13.11 and later, the group setting for delayed project deletion is inherited by subgroups. As discussed in [Cascading settings](../../development/cascading_settings.md), inheritance can be overridden unless enforced by an ancestor.

In GitLab 15.11 with the `always_perform_delayed_deletion` feature flag enabled, this setting is removed
and all projects are deleted after the [retention period defined by the admin](../admin_area/settings/visibility_and_access_controls.md#retention-period). This will be the default behavior in GitLab 16.0 and later.

## Disable email notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23585) in GitLab 12.2.

You can disable all email notifications related to the group, which includes its subgroups and projects.

To disable email notifications:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Email notifications are disabled**.
1. Select **Save changes**.

## Disable group mentions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21301) in GitLab 12.6.

You can prevent users from being added to a conversation and getting notified when
anyone [mentions a group](../discussions/index.md#mentions)
in which those users are members.

Groups with disabled mentions are visualized accordingly in the autocompletion dropdown list.

This is particularly helpful for groups with a large number of users.

To disable group mentions:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Group mentions are disabled**.
1. Select **Save changes**.

## Export members as CSV **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/287940) in GitLab 14.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/336520) in GitLab 14.5.

You can export a list of members in a group or subgroup as a CSV.

1. On the top bar, select **Main menu > Groups** and find your group or subgroup.
1. On the left sidebar, select either **Group information > Members** or **Subgroup information > Members**.
1. Select **Export as CSV**.
1. After the CSV file has been generated, it is emailed as an attachment to the user that requested it.

The output lists direct members and members inherited from the ancestor groups.
For members with `Minimal Access` in the selected group, their `Max Role` and `Source` are derived from their membership in subgroups.
[Issue 390358](https://gitlab.com/gitlab-org/gitlab/-/issues/390358) tracks the discussion about the group members CSV export list not matching the UI members list.

## User cap for groups

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330027) in GitLab 14.7.

FLAG:
On self-managed GitLab, this feature is not available. On GitLab.com, this feature is available for some groups.
This feature is not ready for production use.

When the number of billable members reaches the user cap, new users can't be added to the group
without being approved by the group owner.

Groups with the user cap feature enabled have [group sharing](#share-a-group-with-another-group)
disabled for the group and its subgroups.

### Specify a user cap for a group

Prerequisite:

- You must be assigned the Owner role for the group.

To specify a user cap:

1. On the top bar, select **Main menu > Groups** and find your group.
   You can set a cap on the top-level group only.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. In the **User cap** box, enter the desired number of users.
1. Select **Save changes**.

If you already have more users in the group than the user cap value, users
are not removed. However, you can't add more without approval.

Increasing the user cap does not approve pending members.

### Remove the user cap for a group

You can remove the user cap, so there is no limit on the number of members you can add to a group.

Prerequisite:

- You must be assigned the Owner role) for the group.

To remove the user cap:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. In the **User cap** box, delete the value.
1. Select **Save changes**.

Decreasing the user cap does not approve pending members.

### Approve pending members for a group

When the number of billable users reaches the user cap, any new member is put in a pending state
and must be approved.

Pending members do not count as billable. Members count as billable only after they have been approved and are no longer in a pending state.

Prerequisite:

- You must be assigned the Owner role) for the group.

To approve members that are pending because they've exceeded the user cap:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. On the **Seats** tab, under the alert, select **View pending approvals**.
1. For each member you want to approve, select **Approve**.

## Group file templates **(PREMIUM)**

Use group file templates to share a set of templates for common file
types with every project in a group. It is analogous to the
[instance template repository](../admin_area/settings/instance_template_repository.md).
The selected project should follow the same naming conventions as
are documented on that page.

You can only choose projects in the group as the template source.
This includes projects shared with the group, but it **excludes** projects in
subgroups or parent groups of the group being configured.

You can configure this feature for both subgroups and immediate parent groups. A project
in a subgroup has access to the templates for that subgroup and
any immediate parent groups.

To learn how to create templates for issues and merge requests, see
[description templates](../project/description_templates.md).

Define project templates at a group level by setting a group as the template source.
For more information, see [group-level project templates](custom_project_templates.md).

### Enable group file template **(PREMIUM)**

To enable group file templates:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Templates** section.
1. Choose a project to act as the template repository.
1. Select **Save changes**.

## Group merge checks settings **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/372040) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) name `support_group_level_merge_checks_setting`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to
[enable the feature flag](../../administration/feature_flags.md) named `support_group_level_merge_checks_setting`. On GitLab.com, this feature is not
available.

Group owners can set up merge request checks on a top-level group, which apply to all subgroups and projects.

If the settings are inherited by a subgroup or project, they cannot be changed in the subgroup or project
that inherited them.

### Require a successful pipeline for merge

You can configure all child projects in your group to require a complete and successful pipeline before
merge.

See also [the project-level setting](../project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge).

Prerequisites:

- You must be the owner of the group.

To enable this setting:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **Pipelines must succeed**.
   This setting also prevents merge requests from being merged if there is no pipeline.
1. Select **Save changes**.

#### Allow merge after skipped pipelines

You can configure [skipped pipelines](../../ci/pipelines/index.md#skip-a-pipeline) from preventing merge requests from being merged.

See also [the project-level setting](../project/merge_requests/merge_when_pipeline_succeeds.md#allow-merge-after-skipped-pipelines).

Prerequisite:

- You must be the owner of the group.

To change this behavior:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**:
   - Select **Pipelines must succeed**.
   - Select **Skipped pipelines are considered successful**.
1. Select **Save changes**.

### Prevent merge unless all threads are resolved

You can prevent merge requests from being merged until all threads are resolved. When this setting is enabled, for all child projects in your group, the
**Unresolved threads** count in a merge request is shown in orange when at least one thread remains unresolved.

Prerequisite:

- You must be the owner of the group.

To enable this setting:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **All threads must be resolved**.
1. Select **Save changes**.

## Group merge request approval settings **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285458) in GitLab 13.9. [Deployed behind the `group_merge_request_approval_settings_feature_flag` flag](../../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/285410) in GitLab 14.5.
> - [Feature flag `group_merge_request_approval_settings_feature_flag`](https://gitlab.com/gitlab-org/gitlab/-/issues/343872) removed in GitLab 14.9.

Group approval settings manage [project merge request approval settings](../project/merge_requests/approvals/settings.md)
at the top-level group level. These settings [cascade to all projects](../project/merge_requests/approvals/settings.md#settings-cascading)
that belong to the group.

To view the merge request approval settings for a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Merge request approvals** section.
1. Select the settings you want.
1. Select **Save changes**.

Support for group-level settings for merge request approval rules is tracked in this [epic](https://gitlab.com/groups/gitlab-org/-/epics/4367).

## Group Code Suggestions **(FREE SAAS)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/405126) in GitLab 15.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.

WARNING:
This feature is in [Beta](../../policy/alpha-beta-support.md#beta).
Code Suggestions use generative AI to suggest code while you're developing.
Due to high demand, this feature will have unscheduled downtime and code suggestions in VS Code may be delayed.
Code Suggestions may produce
[low-quality or incomplete suggestions](../project/repository/code_suggestions.md#model-accuracy-and-quality).
Beta users should read about the [known limitations](../project/repository/code_suggestions.md#known-limitations).
We look forward to hearing your feedback.

This setting enables users in the group to access [Code Suggestions](../project/repository/code_suggestions.md).
This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#settings-cascading)
that belong to the group.

To enable Code Suggestions for a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Find the **Code Suggestions** settings.
1. Select **Save changes**.

## Group Experiment features setting **(ULTIMATE SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404856) in GitLab 16.0.

You can give all users in the group access to Experiment features.

WARNING:
[Experiment features](../../policy/alpha-beta-support.md#experiment) may produce unexpected results
(for example, the results might be low-quality, incomplete, incoherent, offensive, or insensitive,
and might include insecure code or failed pipelines).

This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#settings-cascading)
that belong to the group.

To enable Experiment features for a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Find the **Experiment features** settings.
1. Select **Save changes**.

## Group third-party AI features setting **(ULTIMATE SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404856) in GitLab 16.0.

WARNING:
These Artifical Intelligence (AI) features use [third-party services](../ai_features.md#data-usage)
and require transmission of data, including personal data.

You can give all users in the group access to third-party AI features.
This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#settings-cascading)
that belong to the group.

To enable third-party AI features for a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Find the **Third-party Artificial Intelligence (AI) features** settings.
1. Select **Save changes**.

## Group activity analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207164) in GitLab 12.10 as a [Beta feature](../../policy/alpha-beta-support.md#beta).

For a group, you can view how many merge requests, issues, and members were created in the last 90 days.

These Group Activity Analytics can be enabled with the `group_activity_analytics` [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development).

![Recent Group Activity](img/group_activity_analytics_v13_10.png)

Changes to [group wikis](../project/wiki/group.md) do not appear in group activity analytics.

### View group activity

You can view the most recent actions taken in a group, either in your browser or in an RSS feed:

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Group information > Activity**.

To view the activity feed in Atom format, select the
**RSS** (**{rss}**) icon.

## Troubleshooting

### Validation errors on namespaces and groups

[GitLab 14.4 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70365) performs
the following checks when creating or updating namespaces or groups:

- Namespaces must not have parents.
- Group parents must be groups and not namespaces.

In the unlikely event that you see these errors in your GitLab installation,
[contact Support](https://about.gitlab.com/support/) so that we can improve this validation.

### Find groups using an SQL query

To find and store an array of groups based on an SQL query in the [rails console](../../administration/operations/rails_console.md):

```ruby
# Finds groups and subgroups that end with '%oup'
Group.find_by_sql("SELECT * FROM namespaces WHERE name LIKE '%oup'")
=> [#<Group id:3 @test-group>, #<Group id:4 @template-group/template-subgroup>]
```

### Transfer subgroup to another location using Rails console

If transferring a group doesn't work through the UI or API, you may want to attempt the transfer in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
user = User.find_by_username('<username>')
group = Group.find_by_name("<group_name>")
## Set parent_group = nil to make the subgroup a top-level group
parent_group = Group.find_by(id: "<group_id>")
service = ::Groups::TransferService.new(group, user)
service.execute(parent_group)
```

### Find groups pending deletion using Rails console

If you need to find all the groups that are pending deletion, you can use the following command in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
Group.all.each do |g|
 if g.marked_for_deletion?
    puts "Group ID: #{g.id}"
    puts "Group name: #{g.name}"
    puts "Group path: #{g.full_path}"
 end
end
```

### Delete a group using Rails console

At times, a group deletion may get stuck. If needed, in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can attempt to delete a group using the following command:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
GroupDestroyWorker.new.perform(group_id, user_id)
```

### Find a user's maximum permissions for a group or project

Administrators can find a user's maximum permissions for a group or project.

1. Start a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the following commands:

   ```ruby
   user = User.find_by_username 'username'
   project = Project.find_by_full_path 'group/project'
   user.max_member_access_for_project project.id
   ```

   ```ruby
   user = User.find_by_username 'username'
   group = Group.find_by_full_path 'group'
   user.max_member_access_for_group group.id
   ```

### Unable to remove billable members with badge `Project Invite/Group Invite`

```plaintext
Members who were invited via a group invitation cannot be removed. You can either remove the entire group, or ask an Owner of the invited group to remove the member.
```

This error typically occurs when the user you're trying to remove is part of an external group that has been [shared with one or more of your projects](../project/members/share_project_with_groups.md) or [groups](#share-a-group-with-another-group). To remove the user as a billable member, follow one of the options:

- Remove the invited group membership from your project or group members page.
- Recommended. Remove the user directly from the invited group, if you have access to the group.

The feature request to **Update billable_members endpoint to include invited group** is currently being worked on. For more information, see [issue 386583](https://gitlab.com/gitlab-org/gitlab/-/issues/386583)
