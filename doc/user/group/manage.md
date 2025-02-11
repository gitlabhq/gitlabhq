---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage groups
---

Use groups to manage one or more related projects at the same time.

NOTE:
On GitLab Self-Managed, if you want to see an overview of your entire organization, you should create one top-level group.
For more information about efforts to create an organization view of all groups,
[see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
A top-level group offers insights in your entire organization through a complete
[Security Dashboard and Center](../application_security/security_dashboard/_index.md),
[Vulnerability Report](../application_security/vulnerability_report/_index.md),
[compliance center](../compliance/compliance_center/_index.md), and
[value stream analytics](value_stream_analytics/_index.md).

## Add a group README

You can add a README file to provide information about your team and invite users to contribute to your projects.
The README displays on the group overview page. All group members can view and edit the README.

Prerequisites:

- To create the README from the group settings, you must have the Owner role for the group.

To add a group README:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. In the **Group README** section, select **Add README**. This action creates a new project `gitlab-profile` that contains the `README.md` file.
1. On the prompt for creating a README, select **Create and add README**. You're redirected to the Web IDE, where a README file is created.
1. In the Web IDE, edit and commit the `README.md` file.

## Change the Owner of a group

You can change the Owner of a group. Each group must always have at least one
member with the Owner role.

- As an administrator:
  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Manage > Members**.
  1. Give a different member the Owner role.
  1. Refresh the page. You can now remove the Owner role from the original Owner.
- As the current group's Owner:
  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Manage > Members**.
  1. Give a different member the Owner role.
  1. Have the new Owner sign in and remove the Owner role from you.

## Change a group's path

Changing a group's path (group URL) can have unintended side effects. Read how redirects behave
for [projects](../project/repository/_index.md#repository-path-changes)
and in the [API](../../api/rest/_index.md#redirects)
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
project with [Container Registry](../packages/container_registry/_index.md) tags,
because the project cannot be moved.

WARNING:
To ensure that groups with thousands of subgroups get processed correctly, you should test the path change in a test environment.
Consider increasing the [Puma worker timeout](../../administration/operations/puma.md#change-the-worker-timeout) temporarily.
For more information about our solution to mitigate this timeout risk, see [issue 432065](https://gitlab.com/gitlab-org/gitlab/-/issues/432065).

## Change the default branch protection of a group

By default, every group inherits the branch protection set at the global level.

To change this setting for a specific group, see [group level default branch protection](../project/repository/branches/default.md#group-level-default-branch-protection).

To change this setting globally, see [initial default branch protection](../project/repository/branches/default.md#instance-level-default-branch-protection).

NOTE:
In [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), GitLab administrators can choose to [disable group Owners from updating the default branch protection](../project/repository/branches/default.md#prevent-overrides-of-default-branch-protection).

## Use a custom name for the initial branch

When you create a new project in GitLab, a default branch is created with the
first push. The group Owner can
[customize the initial branch](../project/repository/branches/default.md#group-level-custom-initial-branch-name)
for the group's projects to meet your group's needs.

## Transfer a group

Transferring groups moves them from one place to another in the same GitLab instance. You can:

- Transfer a subgroup to a new parent group.
- Convert a top-level group into a subgroup by transferring it to the desired group.
- Convert a subgroup into a top-level group by transferring it out of its current group.

If you need to copy a group to a different GitLab instance,
[migrate the group by direct transfer](import/_index.md).

When transferring groups, note:

- Changing a group's parent can have unintended side effects. See [what happens when a repository path changes](../project/repository/_index.md#repository-path-changes).
- You must update your local repositories to point to the new location.
- If the immediate parent group's visibility is lower than the group's current visibility, visibility levels for subgroups and projects change to match the new parent group's visibility.
- Only explicit group membership is transferred, not inherited membership. If the group's Owners have only inherited membership, this leaves the group without an Owner. In this case, the user transferring the group becomes the group's Owner.
- Transfers fail if the group is a top-level group and [npm packages](../packages/npm_registry/_index.md) following the [naming convention](../packages/npm_registry/_index.md#naming-convention) exist in any of the projects in the group, or in any of its subgroups.
- `container_registry` images in the archived projects must be deleted before the transfer. For more information, see the [troubleshooting section](troubleshooting.md#missing-or-insufficient-permission-delete-button-disabled).
- Existing packages that use a group-level endpoint (Maven, NuGet, PyPI, Composer, and Debian) need to be updated per the package's steps for setting up the group-level endpoint.
- Existing package names need to be updated if the package uses an instance-level endpoint ([Maven](../packages/maven_repository/_index.md#naming-convention), [npm](../packages/npm_registry/_index.md#naming-convention), [Conan](../packages/conan_repository/_index.md#package-recipe-naming-convention-for-instance-remotes)) and the group was moved to another top-level group.
- Top-level groups that have a subscription on GitLab.com cannot be transferred. To make the transfer possible, the top-level group's subscription must be removed first. Then the top-level group can be transferred as a subgroup to another top-level group.

Prerequisites:

- You must have the Owner role for the source and target group.

To transfer a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. Select **Transfer group**.
1. Select the group name in the drop down menu.
1. Select **Transfer group**.

## Disable email notifications

You can disable all email notifications related to the group, which includes its subgroups and projects.

To disable email notifications:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Clear the **Enable email notifications** checkbox.

### Disable diff previews in email notifications

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24733) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `diff_preview_in_email`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/382055) in GitLab 17.1. Feature flag `diff_preview_in_email` removed.

When you comment on code in a merge request, GitLab
includes a few lines of the diff in the email notification to participants.
Some organizational policies treat email as a less secure system, or might not
control their own infrastructure for email. This can present risks to IP or
access control of source code.

Prerequisites:

- You must have the Owner role for the group.

To disable diff previews for all projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Clear **Include diff previews**.
1. Select **Save changes**.

## Expiry emails for group and project access tokens

> - Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `pat_expiry_inherited_members_notification`. Disabled by default.

FLAG:
The availability of emails to inherited project and group members is controlled by a feature flag. For more information, see the history.

The following group and project members receive notification emails about access tokens that are expiring soon:

- For group access tokens:
  - Members with the Owner role.
  - In GitLab 17.7 and later, members who inherit the Owner role for the group, if that group or its parent group has the appropriate setting configured.
- For project access tokens:
  - Members of the project with at least the Maintainer role.
  - In GitLab 17.7 and later, project members who have inherited the Owner or Maintainer role due to the project belonging to a group, if that group or its parent group has the appropriate setting configured.

You can enable notifications to inherited members of a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Expiry notification emails about group and project access tokens within this group should be sent to:**, select **All direct and inherited members of the group or project**.
1. Optional. Check the **Enforce for all subgroups** checkbox.
1. Select **Save changes**.

For more information, see:

- For groups, the [group access tokens documentation](settings/group_access_tokens.md#group-access-token-expiry-emails).
- For projects, the [project access tokens documentation](../project/settings/project_access_tokens.md#project-access-token-expiry-emails).

## Disable group mentions

You can prevent users from being added to a conversation and getting notified when
anyone [mentions a group](../discussions/_index.md#mentions)
in which those users are members.

Groups with disabled mentions are visualized accordingly in the autocompletion dropdown list.

These visual cues are particularly helpful for groups with many users.

To disable group mentions:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Group mentions are disabled**.
1. Select **Save changes**.

## Export members as CSV

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can export a list of members in a group or subgroup as a CSV.

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Select **Manage > Members**.
1. Select **Export as CSV**.
1. After the CSV file has been generated, it is emailed as an attachment to the user that requested it.

The output lists direct members and members inherited from the ancestor groups.
For members with `Minimal Access` in the selected group, their `Max Role` and `Source` are derived from their membership in subgroups.
[Issue 390358](https://gitlab.com/gitlab-org/gitlab/-/issues/390358) tracks the discussion about the group members CSV export list not matching the UI members list.

## Turn on restricted access

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442718) in GitLab 17.5.

Use restricted access to prevent overage fees.
Overage fees occur when you exceed the number of seats in your subscription,
and must be paid at the next [quarterly reconciliation](../../subscriptions/quarterly_reconciliation.md).

When you turn on restricted access, groups cannot add new billable users when there are no seats
left in the subscription.

Prerequisites:

- You must have the Owner role for the group.
- The group or one of its subgroups or projects must not be shared externally.

To turn on restricted access:

1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Seat control**, select **Restricted access**.

### Known issues

When you turn on restricted access, the following known issues might occur and result in overages:

- The number of seats can still be exceeded if:
  - You use SAML or SCIM to add new members, and have exceeded the number of seats in the subscription.
  - Multiple users with the Owner role add members simultaneously.
  - New billable members delay accepting an invitation.
  - You change from using the user cap to restricted access, and have members pending approval
    from before you changed to restricted access. In this case, those members remain in a pending state. If
    pending members are approved while using restricted access, you might exceed the number of seats in your subscription.
- If you renew your subscription through the GitLab Sales Team for fewer users than your current
subscription, you will incur an overage fee. To avoid this fee, remove additional users before your
renewal starts. For example, if you have 20 users and renew your subscription for 15 users,
you will be charged overages for the five additional users.

Additionally, restricted access might block the standard non-overage flows:

- Service bots that are updated or added to a billable role are incorrectly blocked.
- Inviting or updating existing billable users through email is blocked unexpectedly.

## User cap for groups

> - [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/9263) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/421693) in GitLab 17.1 Feature flag `saas_user_caps` removed.

For more information about user caps for GitLab Self-Managed, see [User cap](../../administration/settings/sign_up_restrictions.md#user-cap).

When the number of billable members reaches the user cap, the group Owner must approve new members.

Groups with the user cap feature enabled have [group sharing](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)
disabled for the group and its subgroups.

### Specify a user cap for a group

Prerequisites:

- You must be assigned the Owner role for the group.

To specify a user cap:

1. On the left sidebar, select **Search or go to** and find your group.
   You can set a cap on the top-level group only.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. From **Seat control**, select the **Set user cap** checkbox and enter the number of users in the field.
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
1. From **Seat control**, select **Open access**.
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

To ensure that the user cap applies when groups, subgroups, or projects are shared externally, restrict group sharing only in the top-level namespace. A top-level namespace restriction allows invitations in the same namespace and prevents new user (seat) additions from external shares.

GitLab.com Ultimate has a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441504) where you cannot add guest users to a group when billable users exceed the user cap. For example, suppose you have a user cap of 5, with 3 developers, and 2 guests. After you add 2 more developers, you cannot add any more users, even if they are guest users that don't consume a billable seat.

## Group file templates

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To enable group file templates:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Templates** section.
1. Choose a project to act as the template repository.
1. Select **Save changes**.

## Group merge checks settings

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/372040) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) name `support_group_level_merge_checks_setting`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142708) in GitLab 16.9. Feature flag `support_group_level_merge_checks_setting` removed.

Group Owners can set up merge request checks on a top-level group, which apply to all subgroups and projects.

If the settings are inherited by a subgroup or project, they cannot be changed in the subgroup or project
that inherited them.

### Require a successful pipeline for merge

You can configure all child projects in your group to require a complete and successful pipeline before
merge.

See also [the project-level setting](../project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge).

Prerequisites:

- You must be the Owner of the group.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **Pipelines must succeed**.
   This setting also prevents merge requests from being merged if there is no pipeline.
1. Select **Save changes**.

#### Allow merge after skipped pipelines

You can configure [skipped pipelines](../../ci/pipelines/_index.md#skip-a-pipeline) from preventing merge requests from being merged.

See also [the project-level setting](../project/merge_requests/auto_merge.md#allow-merge-after-skipped-pipelines).

Prerequisites:

- You must be the Owner of the group.

To change this behavior:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**:
   - Select **Pipelines must succeed**.
   - Select **Skipped pipelines are considered successful**.
1. Select **Save changes**.

### Prevent merge unless all threads are resolved

You can prevent merge requests from being merged until all threads are resolved. When this setting is enabled, child projects in your group display unresolved thread counts in orange on merge requests with at least one unresolved thread.

Prerequisites:

- You must be the Owner of the group.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **All threads must be resolved**.
1. Select **Save changes**.

## Group merge request approval settings

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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

## Group activity analytics

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

For a group, you can view how many merge requests, issues, and members were created in the last 90 days.

Changes to [group wikis](../project/wiki/group.md) do not appear in group activity analytics.

### View group activity

You can view the most recent actions taken in a group, either in your browser or in an RSS feed:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Activity**.

To view the activity feed in Atom format, select the
**RSS** (**{rss}**) icon.
