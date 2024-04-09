---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Manage groups

Use groups to manage one or more related projects at the same time.

NOTE:
For self-managed customers it could be beneficial to create one single top-level group, so you can see an overview of
your entire organization. For more information about efforts to create an
organization view of all groups, [see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
A single top-level group provides insights in your entire organization via a complete
[Security Dashboard and Center](../application_security/security_dashboard/index.md),
[Vulnerability](../application_security/vulnerability_report/index.md#vulnerability-report) and
[Compliance center](../compliance/compliance_center/index.md), and
[Value stream analytics](../group/value_stream_analytics/index.md).

## Add a group README

As a group owner or member, you can use a README to provide more information about your team, and invite users to contribute to your projects.
The README is displayed on the group overview page, and can be changed in the group settings. All group members can edit the README.

Prerequisites:

- To create the README from the group settings, you must have the Owner role for the group.

To add a group README:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. In the **Group README** section, select **Add README**. This action creates a new project `gitlab-profile` that contains the `README.md` file.
1. On the prompt for creating a README, select **Create and add README**. You're redirected to the Web IDE, where a README file is created.
1. In the Web IDE, edit and commit the `README.md` file.

## Change the owner of a group

You can change the owner of a group. Each group must always have at least one
member with the Owner role.

- As an administrator:
  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Manage > Members**.
  1. Give a different member the **Owner** role.
  1. Refresh the page. You can now remove the **Owner** role from the original owner.
- As the current group's owner:
  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Manage > Members**.
  1. Give a different member the **Owner** role.
  1. Have the new owner sign in and remove the **Owner** role from you.

## Change a group's path

Changing a group's path (group URL) can have unintended side effects. Read how redirects behave
[on the project-level](../project/repository/index.md#what-happens-when-a-repository-path-changes)
and [in the API](../../api/rest/index.md#redirects)
before you proceed.

If you are changing the path so it can be claimed by another group or user,
you must rename the group too. Both names and paths must
be unique.

To retain ownership of the original namespace and protect the URL redirects,
create a new group and transfer projects to it instead.

To change your group path (group URL):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. Under **Change group URL**, enter a new name.
1. Select **Change group URL**.

WARNING:
It is not possible to rename a namespace if it contains a
project with [Container Registry](../packages/container_registry/index.md) tags,
because the project cannot be moved.

WARNING:
To ensure that groups with thousands of subgroups get processed correctly, you should test the path change in a test environment.
Consider increasing the [Puma worker timeout](../../administration/operations/puma.md#change-the-worker-timeout) temporarily.
For more information about our solution to mitigate this timeout risk, see [issue 432065](https://gitlab.com/gitlab-org/gitlab/-/issues/432065).

## Change the default branch protection of a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7583) in GitLab 12.9.
> - [Settings moved and renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/340403) in GitLab 14.9.

By default, every group inherits the branch protection set at the global level.

To change this setting for a specific group, see [group level default branch protection](../project/repository/branches/default.md#group-level-default-branch-protection).

To change this setting globally, see [initial default branch protection](../project/repository/branches/default.md#instance-level-default-branch-protection).

NOTE:
In [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), GitLab administrators can choose to [disable group owners from updating the default branch protection](../project/repository/branches/default.md#prevent-overrides-of-default-branch-protection).

## Use a custom name for the initial branch

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43290) in GitLab 13.6.

When you create a new project in GitLab, a default branch is created with the
first push. The group owner can
[customize the initial branch](../project/repository/branches/default.md#group-level-custom-initial-branch-name)
for the group's projects to meet your group's needs.

## Share a group with another group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18328) in GitLab 12.7.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal window [with a flag](../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9. [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

Similar to how you [share a project with a group](../project/members/share_project_with_groups.md),
you can share a group with another group by invitation.
For more information about sharing conditions and behavior, see [Sharing projects and groups](../project/members/sharing_projects_groups.md).

Prerequisites:

- You must be a member of the invited and inviting groups.

To invite a group to your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select **Invite a group**.
1. In the **Select a group to invite** list, select the group you want to invite.
1. Select a [role](../permissions.md) as maximum access level.
1. Select **Invite**.

## Remove an invited group

To remove an invited group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Groups** tab.
1. To the right of the account you want to remove, select **Remove group** (**{remove}**).

When you remove the invited group from your group:

- All direct members of the invited group no longer have access to the inviting group.
- Members of the invited group no longer count towards the billable members of the inviting group.

## Transfer a group

Transferring groups moves them from one place to another in the same GitLab instance. You can:

- Transfer a subgroup to a new parent group.
- Convert a top-level group into a subgroup by transferring it to the desired group.
- Convert a subgroup into a top-level group by transferring it out of its current group.

If you need to copy a group to a different GitLab instance,
[migrate the group by direct transfer](import/index.md).

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

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Remove group** section, select **Transfer group**.
1. Select the group name in the drop down menu.
1. Select **Transfer group**.

## Disable email notifications

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23585) in GitLab 12.2.

You can disable all email notifications related to the group, which includes its subgroups and projects.

To disable email notifications:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Email notifications are disabled**.
1. Select **Save changes**.

## Disable group mentions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21301) in GitLab 12.6.

You can prevent users from being added to a conversation and getting notified when
anyone [mentions a group](../discussions/index.md#mentions)
in which those users are members.

Groups with disabled mentions are visualized accordingly in the autocompletion dropdown list.

This is particularly helpful for groups with a large number of users.

To disable group mentions:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Group mentions are disabled**.
1. Select **Save changes**.

## Export members as CSV

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/287940) in GitLab 14.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/336520) in GitLab 14.5.

You can export a list of members in a group or subgroup as a CSV.

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Select  **Manage > Members**.
1. Select **Export as CSV**.
1. After the CSV file has been generated, it is emailed as an attachment to the user that requested it.

The output lists direct members and members inherited from the ancestor groups.
For members with `Minimal Access` in the selected group, their `Max Role` and `Source` are derived from their membership in subgroups.
[Issue 390358](https://gitlab.com/gitlab-org/gitlab/-/issues/390358) tracks the discussion about the group members CSV export list not matching the UI members list.

## User cap for groups

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330027) in GitLab 14.7 [with a flag](../../administration/feature_flags.md) named `saas_user_caps`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/9263) in GitLab 16.3.

For more information about user caps for GitLab self-managed, see [User cap](../../administration/settings/sign_up_restrictions.md#user-cap).

When the number of billable members reaches the user cap, new users can't be added to the group
without being approved by the group owner.

Groups with the user cap feature enabled have [group sharing](#share-a-group-with-another-group)
disabled for the group and its subgroups.

### Specify a user cap for a group

Prerequisites:

- You must be assigned the Owner role for the group.

To specify a user cap:

1. On the left sidebar, select **Search or go to** and find your group.
   You can set a cap on the top-level group only.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. In the **User cap** box, enter the desired number of users.
1. Select **Save changes**.

If you already have more users in the group than the user cap value, users
are not removed. However, you can't add more without approval.

Increasing the user cap does not approve pending members.

### Remove the user cap for a group

You can remove the user cap, so there is no limit on the number of members you can add to a group.

Prerequisites:

- You must be assigned the Owner role for the group.

To remove the user cap:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. In the **User cap** box, delete the value.
1. Select **Save changes**.

Decreasing the user cap does not approve pending members.

### Approve pending members for a group

When the number of billable users reaches the user cap, any new member is put in a pending state
and must be approved.

Pending members do not count as billable. Members count as billable only after they have been approved and are no longer in a pending state.

Prerequisites:

- You must be assigned the Owner role for the group.

To approve members that are pending because they've exceeded the user cap:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. On the **Seats** tab, under the alert, select **View pending approvals**.
1. For each member you want to approve, select **Approve**.

### Known issues

The user cap cannot be enabled if a group, subgroup, or project is shared externally. If a group, subgroup,
or project is shared externally, it is shared outside of the namespace hierarchy, regardless of its level
in the hierarchy.

To ensure that the user cap applies when groups, subgroups, or projects are shared externally, restrict group sharing only within the top-level namespace. This ensure that groups in the same top-leve namespace can be invited, and prevents the addition of new users (seats) when the group is shared.

On GitLab.com, on the Ultimate tier, there is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441504) where you cannot add new guest users to a group when the amount of billable users exceeds the user cap. For example, suppose you have a user cap of 5, with 3 developers and 2 guests. After you add 2 more developers, you cannot add any more users, even if they are guest users that don't consume a billable seat.

## Group file templates

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Use group file templates to share a set of templates for common file
types with every project in a group. It is analogous to the
[instance template repository](../../administration/settings/instance_template_repository.md).
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

### Enable group file template

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To enable group file templates:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Templates** section.
1. Choose a project to act as the template repository.
1. Select **Save changes**.

## Group merge checks settings

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/372040) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) name `support_group_level_merge_checks_setting`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142708) in GitLab 16.9. Feature flag `support_group_level_merge_checks_setting` removed.

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

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **Pipelines must succeed**.
   This setting also prevents merge requests from being merged if there is no pipeline.
1. Select **Save changes**.

#### Allow merge after skipped pipelines

You can configure [skipped pipelines](../../ci/pipelines/index.md#skip-a-pipeline) from preventing merge requests from being merged.

See also [the project-level setting](../project/merge_requests/merge_when_pipeline_succeeds.md#allow-merge-after-skipped-pipelines).

Prerequisites:

- You must be the owner of the group.

To change this behavior:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**:
   - Select **Pipelines must succeed**.
   - Select **Skipped pipelines are considered successful**.
1. Select **Save changes**.

### Prevent merge unless all threads are resolved

You can prevent merge requests from being merged until all threads are resolved. When this setting is enabled, for all child projects in your group, the
**Unresolved threads** count in a merge request is shown in orange when at least one thread remains unresolved.

Prerequisites:

- You must be the owner of the group.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **All threads must be resolved**.
1. Select **Save changes**.

## Group merge request approval settings

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285458) in GitLab 13.9. [Deployed behind the `group_merge_request_approval_settings_feature_flag` flag](../../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/285410) in GitLab 14.5.
> - [Feature flag `group_merge_request_approval_settings_feature_flag`](https://gitlab.com/gitlab-org/gitlab/-/issues/343872) removed in GitLab 14.9.

Group approval settings manage [project merge request approval settings](../project/merge_requests/approvals/settings.md)
for all projects in a top-level group. These settings [cascade to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

To view the merge request approval settings for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Merge request approvals** section.
1. Select the settings you want.
1. Select **Save changes**.

Approval settings should not be confused with [approval rules](../project/merge_requests/approvals/rules.md). Support
for the ability to set merge request approval rules for groups is tracked in
[epic 4367](https://gitlab.com/groups/gitlab-org/-/epics/4367).

## Enable Experiment and Beta features

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118222) in GitLab 16.0.
> - [Added to GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147833) in GitLab 16.11.

WARNING:
[Experiment and Beta features](../../policy/experiment-beta-support.md) may produce unexpected results
(for example, the results might be low-quality, incomplete, incoherent, offensive, or insensitive,
and might include insecure code or failed pipelines).

You can give all users in a top-level group access to Experiment and Beta features.
This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

To enable Experiment features for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Experiment and Beta features**, select the **Use Experiment and Beta features** checkbox.
1. Select **Save changes**.

## Group activity analytics

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207164) in GitLab 12.10 as a [Beta feature](../../policy/experiment-beta-support.md#beta).

For a group, you can view how many merge requests, issues, and members were created in the last 90 days.

These Group Activity Analytics can be enabled with the `group_activity_analytics` [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development).

![Recent Group Activity](img/group_activity_analytics_v13_10.png)

Changes to [group wikis](../project/wiki/group.md) do not appear in group activity analytics.

### View group activity

You can view the most recent actions taken in a group, either in your browser or in an RSS feed:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Activity**.

To view the activity feed in Atom format, select the
**RSS** (**{rss}**) icon.
