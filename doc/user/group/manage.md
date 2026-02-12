---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage groups
---

Use groups to manage one or more related projects at the same time.

> [!note]
> On GitLab Self-Managed, if you want to see an overview of your entire organization, you should create one top-level group.
> For more information about efforts to create an organization view of all groups,
> [see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
> A top-level group offers insights in your entire organization through a complete
> [Security Dashboard and Center](../application_security/security_dashboard/_index.md),
> [Vulnerability report](../application_security/vulnerability_report/_index.md),
> [compliance center](../compliance/compliance_center/_index.md), and
> [value stream analytics](value_stream_analytics/_index.md).

## Add a group README

You can add a README file to provide information about your team and invite users to contribute to your projects.
The README displays on the group overview page. All group members can view and edit the README.

Prerequisites:

- To create the README from the group settings, you must have the Owner role for the group.

To add a group README:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. In the **Group README** section, select **Add README**. This action creates a new project `gitlab-profile` that contains the `README.md` file.
1. On the prompt for creating a README, select **Create and add README**. You're redirected to the Web IDE, where a README file is created.
1. In the Web IDE, edit and commit the `README.md` file.

## Change the Owner of a group

You can change the Owner of a group. Each group must always have at least one
human member with the Owner role. Internal users ("bots") and service accounts cannot be the only Owner of a group.

- As an administrator:
  1. On the top bar, select **Search or go to** and find your group.
  1. Select **Manage** > **Members**.
  1. Give a different member the Owner role.
  1. Refresh the page. You can now remove the Owner role from the original Owner.
- As the current group's Owner:
  1. On the top bar, select **Search or go to** and find your group.
  1. Select **Manage** > **Members**.
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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Advanced** section.
1. Under **Change group URL**, enter a new name.
1. Select **Change group URL**.

> [!warning]
> It is not possible to rename a namespace if it contains a
> project with [Container Registry](../packages/container_registry/_index.md) tags,
> because the project cannot be moved.
>
> To ensure that groups with thousands of subgroups get processed correctly, you should test the path change in a test environment.
> Consider increasing the [Puma worker timeout](../../administration/operations/puma.md#change-the-worker-timeout) temporarily.
> For more information about our solution to mitigate this timeout risk, see [issue 432065](https://gitlab.com/gitlab-org/gitlab/-/issues/432065).

## Change the default branch protection of a group

The administrator of a GitLab instance can configure default branch protections for
[all projects in an instance](../project/repository/branches/default.md#for-all-projects-in-an-instance).
Groups in that instance inherit the branch protection set at the global level. Group owners can
[override the instance settings](../project/repository/branches/default.md#for-all-projects-in-a-group)
for projects in a group. In [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), the administrator
of the instance can disable this privilege.

## Use a custom name for the initial branch

When you create a new project in GitLab, a default branch is created with the
first push. The group Owner can
[customize the initial branch](../project/repository/branches/default.md#change-the-default-branch-name-for-new-projects-in-a-group)
for the group's projects to meet your group's needs.

## Archive a group

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15019) in GitLab 18.3 [with a flag](../../administration/feature_flags/_index.md) named `archive_group`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/526771) in GitLab 18.9. Feature flag `archive_group` removed.

{{< /history >}}

Archive a group and all of its subgroups and projects. When archived, a group and its contents become read-only, and group data is preserved for future reference.

Additionally, archived groups:

- Display an `Archived` badge on the group page
- Appear in the **Inactive** tab on the **Your work** page, and **Explore** page
- Cannot be transferred to another namespace

### Known limitations

Issues from archived groups will continue to appear on issue boards until [issue 585677](https://gitlab.com/gitlab-org/gitlab/-/work_items/585677) is resolved.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To archive a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Archive group** section, select **Archive**.

> [!note]
> Archiving a group automatically archives all its subgroups and projects. Individual subgroups or projects within an archived group cannot be unarchived separately.

To archive a group from the **Your work** list view directly:

1. On the top bar, select **Search or go to**.
1. Select **View all my groups**.
1. In the **Member** tab, find the group you want to archive and select ({{< icon name="ellipsis_v" >}}).
1. Select **Archive**.

This action is also available on other list pages.

### Unarchive a group

Unarchive a group and all of its subgroups and projects. When you unarchive a group:

- Read-only restrictions are removed from the group and its contents.
- The group and its subgroups and projects return to the **Active** or **Member** tabs in group lists.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To unarchive a group:

1. Find the archived group.
   1. On the top bar, select **Search or go to**.
   1. Select **View all my groups**.
   1. In the **Inactive** tab, select your group.
1. On the left sidebar, select **Settings** > **General**.
1. Under **Advanced**, select **Expand**.
1. In the **Unarchive group** section, select **Unarchive**.

To unarchive a group from the **Your work** list view directly:

1. On the top bar, select **Search or go to**.
1. Select **View all my groups**.
1. In the **Inactive** tab, find the group you want to unarchive and select ({{< icon name="ellipsis_v" >}}).
1. Select **Unarchive**.

This action is also available on other list pages.

## Transfer a group

Transfer a group to move it from one location to another in the same GitLab instance. You can:

- Transfer a subgroup to a different parent group.
- Convert a top-level group into a subgroup.
- Convert a subgroup into a top-level group.

Prerequisites:

- The Owner role for the source and target groups.
- Enable subgroup creation in the target group (if applicable).

> [!note]
> You cannot transfer a group if it's archived or pending deletion.

To transfer a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Advanced** section.
1. Select **Transfer group**.
1. From the dropdown list, select the group.
1. Select **Transfer group**.

After you transfer a group, make sure you:

- Update local repository remotes to new URLs.
- Verify group member access and permissions.
- Update package configurations if necessary.
- Test CI/CD pipelines and integrations.

If you need to copy a group to a different GitLab instance,
[migrate the group by direct transfer](import/_index.md).

### What data gets transferred

A group transfer includes:

- All subgroups and projects with the group
- Explicit group memberships and roles
- Group settings and configurations

### Known issues

When transferring a group, keep the
following restrictions in mind.

Membership restrictions:

- Inherited memberships are lost. Only direct group members are transferred.
- If a group Owner has an inherited membership, the user that transfers the group
becomes the new Owner.

Visibility and access restrictions:

- If a target parent group has lower visibility, the visibility settings of all subgroups and projects
are adjusted to match the visibility of the target parent group.
- Repository URLs change. You must update your local repositories to point to the new location. For more information, see [Repository page changes](../project/repository/_index.md#repository-path-changes).

Package and container registry restrictions:

- Transfers fail if the target group is a top-level group where npm packages that follow the [npm naming convention](../packages/npm_registry/_index.md#naming-convention) exist in any of the projects in the group, or in any of its subgroups.
- Existing packages that use a group endpoint must be updated per the package's steps for setting up the group-level endpoint.
- Existing package names must be updated if the package uses an instance-level endpoint and the group was moved to another top-level group.

Subscription restrictions:

- Top-level groups that have a subscription on GitLab.com cannot be transferred. To make the transfer possible, the top-level group's subscription must be removed first. Then, the top-level group can be transferred as a subgroup to another top-level group.

## Disable email notifications

You can disable all email notifications related to the group, which includes its subgroups and projects.

To disable email notifications:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Clear the **Enable email notifications** checkbox.

### Disable diff previews in email notifications

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24733) in GitLab 15.6 [with a flag](../../administration/feature_flags/_index.md) named `diff_preview_in_email`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/382055) in GitLab 17.1. Feature flag `diff_preview_in_email` removed.

{{< /history >}}

When you comment on code in a merge request, GitLab
includes a few lines of the diff in the email notification to participants.
Some organizational policies treat email as a less secure system, or might not
control their own infrastructure for email. This can present risks to IP or
access control of source code.

Prerequisites:

- You must have the Owner role for the group.

To disable diff previews for all projects in a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Clear **Include diff previews**.
1. Select **Save changes**.

## Expiry emails for group and project access tokens

{{< history >}}

- Notifications to inherited group members [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `pat_expiry_inherited_members_notification`. Disabled by default.
- Feature flag `pat_expiry_inherited_members_notification` [enabled by default in GitLab 17.10](https://gitlab.com/gitlab-org/gitlab/-/issues/393772).
- Feature flag `pat_expiry_inherited_members_notification` removed in GitLab `17.11`

{{< /history >}}

The following group and project members receive notification emails about access tokens that are expiring soon:

- For group access tokens:
  - Members with the Owner role.
  - In GitLab 17.7 and later, members who inherit the Owner role for the group, if that group or its parent group has the appropriate setting configured.
- For project access tokens:
  - Members of the project with at least the Maintainer role.
  - In GitLab 17.7 and later, project members who have inherited the Owner or Maintainer role due to the project belonging to a group, if that group or its parent group has the appropriate setting configured.

You can enable notifications to inherited members of a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Expiry notification emails about group and project access tokens within this group should be sent to:**, select **All direct and inherited members of the group or project**.
1. Optional. Check the **Enforce for all subgroups** checkbox.
1. Select **Save changes**.

For more information, see:

- For groups, the [group access tokens documentation](settings/group_access_tokens.md#group-access-token-expiry-emails).
- For projects, the [project access tokens documentation](../project/settings/project_access_tokens.md#project-access-token-expiry-emails).

## Add additional webhook triggers for group access token expiration

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/499732) 60- and 30-day triggers to project and group access token webhooks in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `extended_expiry_webhook_execution_setting`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/513684) in GitLab 17.10. Feature flag `extended_expiry_webhook_execution_setting` removed.

{{< /history >}}

GitLab sends multiple [expiry emails](settings/group_access_tokens.md#group-access-token-expiry-emails)
and triggers a related [webhook](../project/integrations/webhook_events.md#project-and-group-access-token-events)
before a group token expires. By default, these webhooks trigger 7 days before a token expires.

To configure these webhooks to also trigger 60 days and 30 days before a token expires:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Select the **Add additional webhook triggers for group access token expiration** checkbox.
1. Select **Save changes**.

## Disable group mentions

You can prevent users from being added to a conversation and getting notified when
anyone [mentions a group](../discussions/_index.md#mentions)
in which those users are members.

Groups with disabled mentions are visualized accordingly in the autocompletion dropdown list.

These visual cues are particularly helpful for groups with many users.

To disable group mentions:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Select **Group mentions are disabled**.
1. Select **Save changes**.

## Restrict personal snippets for enterprise users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200575) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `allow_personal_snippets_setting`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

You can prevent [enterprise users](../enterprise_user/_index.md) in your group from creating
[snippets](../snippets.md) in their personal namespace. When disabled, enterprise users
can still create project snippets.

Prerequisites:

- You must have the Owner role for the group.

To restrict personal snippets for enterprise users:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Clear the **Allow personal snippets** checkbox.
1. Select **Save changes**.

## Prevent invitations to a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189898) in GitLab 18.0. Disabled by default.

{{< /history >}}

On GitLab.com, you can remove the ability for users to invite new members to subgroups or projects in a top-level
group. This also stops group Owners from sending invites. You must disable this setting before you
can invite users again.

On GitLab Self-Managed and GitLab Dedicated instances, you can prevent user invitations for the entire instance.
For more information, see [prevent invitations to a groups and projects](../../administration/settings/visibility_and_access_controls.md#prevent-invitations-to-groups-and-projects).

> [!note]
> Features such as [sharing](../project/members/sharing_projects_groups.md) or [migrations](../import/_index.md) can still allow access to these subgroups and projects.

Prerequisites:

- You must have the Owner role for the group.

To prevent invitations to a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Select **Disable Group/Project members invitation**.
1. Select **Save changes**.

## Export members as CSV

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can export a list of members in a group or subgroup as a CSV.

1. On the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Manage** > **Members**.
1. Select **Export as CSV**.
1. After the CSV file has been generated, it is emailed as an attachment to the user that requested it.

The output lists direct members and members inherited from the ancestor groups.
For members with `Minimal Access` in the selected group, their `Max Role` and `Source` are derived from their membership in subgroups.
[Issue 390358](https://gitlab.com/gitlab-org/gitlab/-/issues/390358) tracks the discussion about the group members CSV export list not matching the UI members list.

## Restricted access

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442718) in GitLab 17.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/523468) in GitLab 18.0.
- Group sharing settings [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/488451) in GitLab 18.7.

{{< /history >}}

Use restricted access to prevent overage fees.
Overage fees occur when you exceed the number of seats in your subscription,
and must be paid at the next [quarterly reconciliation](../../subscriptions/quarterly_reconciliation.md).

When you turn on restricted access, groups cannot add new billable users when there are no seats
left in the subscription.

> [!note]
> If [user cap](#user-cap-for-groups) is enabled for a group that has pending members, when you enable restricted access all pending members are automatically removed from the group.

### Turn on restricted access

Prerequisites:

- You must have the Owner role for the group.
- The group or one of its subgroups or projects must not be shared externally.

To turn on restricted access:

1. On the left sidebar, select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Seat control**, select **Restricted access**.

When you turn on restricted access, the setting to
[prevent inviting groups outside the group hierarchy](../project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy)
is automatically turned on.

You can still independently configure [project sharing for the group and its subgroups](../project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) as needed.

### Provisioning behavior with SAML, SCIM, and LDAP

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) in GitLab 18.6 [with a flag](../../administration/feature_flags/_index.md) named `bso_minimal_access_fallback`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

When restricted access is enabled and no subscription seats are available, users provisioned through SAML, SCIM, or LDAP are assigned the Minimal Access role instead of their configured access level.
This behavior ensures that synchronization can continue without consuming billable seats on GitLab.com and Self-Managed Ultimate.

Users with the Minimal Access role can authenticate and access the group, but have [limited permissions](../../user/permissions.md#users-with-minimal-access).
When seats become available, they can be promoted to their intended access level.
Existing users with billable roles are not affected by this behavior.

You can [view seat usage](../../subscriptions/manage_users_and_seats.md#view-seat-usage) and manage users with Minimal Access.

### Known issues

When you turn on restricted access, the following known issues might occur and result in overages:

- The number of seats can still be exceeded if:
  - You use SAML, SCIM, or LDAP to add new members, and have exceeded the number of seats in the subscription. When the [Minimal Access fallback](#provisioning-behavior-with-saml-scim-and-ldap) feature is enabled, users are assigned Minimal Access instead of being blocked.
  - Multiple users with the Owner role add members simultaneously.
  - New billable members delay accepting an invitation. When you invite a user, they don't consume a billable seat until they accept the invitation. If an invited user delays accepting, you can invite and add other users during that time. When the delayed user finally accepts, they consume a billable seat, which might cause an overage if you've already reached your seat limit.
- If you renew your subscription through the GitLab Sales Team for fewer users than your current
  subscription, you will incur an overage fee. To avoid this fee, remove additional users before your
  renewal starts. For example, if you have 20 users and renew your subscription for 15 users,
  you will be charged overages for the five additional users.

Additionally, restricted access might block the standard non-overage flows:

- Service bots that are updated or added to a billable role are incorrectly blocked.
- Inviting or updating existing billable users through email is blocked unexpectedly.

## User cap for groups

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/9263) in GitLab 16.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/421693) in GitLab 17.1 Feature flag `saas_user_caps` removed.

{{< /history >}}

For more information about user caps for GitLab Self-Managed, see [User cap](../../administration/settings/sign_up_restrictions.md#user-cap).

When the number of billable members reaches the user cap, the group Owner must approve new members.

Groups with the user cap feature enabled have [group sharing](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)
disabled for the group and its subgroups.

> [!warning]
> When you specify a user cap, any members added through group sharing lose access to the group.

### Set a user cap for a group

Prerequisites:

- You must be assigned the Owner role for the group.

To set a user cap:

1. On the top bar, select **Search or go to** and find your group.
   You can set a cap on the top-level group only.
1. Select **Settings** > **General**.
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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Usage quotas**.
1. On the **Seats** tab, under the alert, select **View pending approvals**.
1. For each member you want to approve, select **Approve**.

### Known issues

The user cap cannot be enabled if a group, subgroup, or project is shared externally. If a group, subgroup,
or project is shared externally, it is shared outside of the namespace hierarchy, regardless of its level
in the hierarchy.

To ensure that the user cap applies when groups, subgroups, or projects are shared externally,
[restrict group sharing only in the top-level namespace](../../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy).
A top-level namespace restriction allows invitations in the same namespace and prevents new user (seat) additions from external shares.

GitLab.com Ultimate has a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441504) where you cannot add guest users to a group when billable users exceed the user cap. For example, suppose you have a user cap of 5, with 3 developers, and 2 guests. After you add 2 more developers, you cannot add any more users, even if they are guest users that don't consume a billable seat.

## Changing from user cap to restricted access

When you change from user cap to restricted access, all pending members (both members awaiting approval and invited members) are automatically removed.
To ensure users are approved as members, you must approve or remove pending members before enabling restricted access.

## Group file templates

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

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

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To enable group file templates:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Templates** section.
1. Choose a project to act as the template repository.
1. Select **Save changes**.

## Group merge checks settings

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/372040) in GitLab 15.9 [with a flag](../../administration/feature_flags/_index.md) name `support_group_level_merge_checks_setting`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142708) in GitLab 16.9. Feature flag `support_group_level_merge_checks_setting` removed.

{{< /history >}}

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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Merge requests**.
1. Under **Merge checks**:
   - Select **Pipelines must succeed**.
   - Select **Skipped pipelines are considered successful**.
1. Select **Save changes**.

### Prevent merge unless all threads are resolved

You can prevent merge requests from being merged until all threads are resolved. When this setting is enabled, child projects in your group display open thread counts in orange on merge requests with at least one open thread.

Prerequisites:

- You must be the Owner of the group.

To enable this setting:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Merge requests**.
1. Under **Merge checks**, select **All threads must be resolved**.
1. Select **Save changes**.

## Group merge request approval settings

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Group approval settings manage [project merge request approval settings](../project/merge_requests/approvals/settings.md)
for all projects in a top-level group. These settings [cascade to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

To view the merge request approval settings for a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Merge request approvals** section.
1. Select the settings you want.
1. Select **Save changes**.

Approval settings should not be confused with [approval rules](../project/merge_requests/approvals/rules.md). Support
for the ability to set merge request approval rules for groups is tracked in
[epic 4367](https://gitlab.com/groups/gitlab-org/-/epics/4367).

## Group activity analytics

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

For a group, you can view how many merge requests, issues, and members were created in the last 90 days.

Changes to [group wikis](../project/wiki/group.md) do not appear in group activity analytics.

### View group activity

You can view the most recent actions taken in a group, either in your browser or in an RSS feed:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Manage** > **Activity**.

To view the activity feed in Atom format, select the
**RSS** ({{< icon name="rss" >}}) icon.

## Display GitLab Credits user data

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Namespace setting to allow the display of user data
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215371) in GitLab 18.7
  [with a flag](../../administration/feature_flags/_index.md) named `usage_billing_dev`. [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215714).

{{< /history >}}

Prerequisites:

- You must be a group Owner.
- The group you are viewing data for must be a top-level group.

To display user data on the [GitLab Credits dashboard](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard):

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. For the **GitLab Credits dashboard**, select the **Display user data** checkbox.
1. Select **Save changes**.
