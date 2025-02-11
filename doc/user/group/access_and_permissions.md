---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group access and permissions
---

Configure your groups to control group permissions and access.
For more information, see also [Sharing projects and groups](../project/members/sharing_projects_groups.md).

## Group push rules

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Moved to Settings/Repository](https://gitlab.com/gitlab-org/gitlab/-/issues/220365) in GitLab 15.4.

Group push rules allow group maintainers to set
[push rules](../project/repository/push_rules.md) for newly created projects in the specific group.

In GitLab 15.4 and later, to configure push rules for a group:

1. On the left sidebar, select **Settings > Repository**.
1. Expand the **Pre-defined push rules** section.
1. Select the settings you want.
1. Select **Save push rules**.

In GitLab 15.3 and earlier, to configure push rules for a group:

1. On the left sidebar, select **Push rules**.
1. Select the settings you want.
1. Select **Save push rules**.

The group's new subgroups have push rules set for them based on either:

- The closest parent group with push rules defined.
- Push rules set for the entire instance, if no parent groups have push rules defined.

## Restrict Git access protocols

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/365601) in GitLab 15.1.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/365357) in GitLab 16.0.

You can set the permitted protocols used to access a group's repositories to either SSH, HTTPS, or both. This setting
is disabled when the [instance setting](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols) is
configured by an administrator.

To change the permitted Git access protocols for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Choose the permitted protocols from **Enabled Git access protocols**.
1. Select **Save changes**.

## Restrict group access by IP address

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To ensure only people from your organization can access particular resources, you can restrict access to groups by IP
address. This top-level group setting applies to:

- The GitLab UI, including subgroups, projects, and issues. It does not apply to GitLab Pages.
- The API.
- On GitLab Self-Managed, in 15.1 and later, you can also configure
  [globally-allowed IP address ranges](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)
  for the group.

Administrators can combine restricted access by IP address with
[globally-allowed IP addresses](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges).

To restrict group access by IP address:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. In the **Restrict access by IP address** text box, enter a list of IPv4 or IPv6
   address ranges in CIDR notation. This list:
   - Has no limit on the number of IP address ranges.
   - Applies to both SSH or HTTP authorized IP address ranges. You cannot split
     this list by type of authorization.
1. Select **Save changes**.

### Security implications

Keep in mind that restricting group access by IP address has the following implications:

- Administrators and group Owners can access group settings from any IP address, regardless of IP restriction. However:
  - Group Owners can access the subgroups, but not the projects belonging to the group or subgroups, when accessing from a disallowed IP address.
  - Administrators can access projects belonging to the group when accessing from a disallowed IP address.
    Access to projects includes cloning code from them.
  - Users can still see group and project names and hierarchies. Only the following are restricted:
    - [Groups](../../api/groups.md), including all [group resources](../../api/api_resources.md#group-resources).
    - [Project](../../api/projects.md), including all [project resources](../../api/api_resources.md#project-resources).
- When you register a runner, it is not bound by the IP restrictions. When the runner requests a new job or an update to
  a job's state, it is also not bound by the IP restrictions. But when the running CI/CD job sends Git requests from a
  restricted IP address, the IP restriction prevents code from being cloned.
- Users might still see some events from the IP-restricted groups and projects on their dashboard. Activity might include
  push, merge, issue, or comment events.
- IP access restrictions do not stop users from using the [reply by email feature](../../administration/reply_by_email.md) to create or edit comments on issues or merge requests.
- IP access restrictions for Git operations through SSH are supported on GitLab SaaS.
  IP access restrictions applied to self-managed instances are possible with [`gitlab-sshd`](../../administration/operations/gitlab_sshd.md)
  with [PROXY protocol](../../administration/operations/gitlab_sshd.md#proxy-protocol-support) enabled.
- IP restriction is not applicable to shared resources belonging to a group. Any shared resource is accessible to a user even if that user is not able to access the group.
- While IP restrictions apply to public projects, they aren't a complete firewall and cached files for a project may still be accessible to users not in the IP block

### GitLab.com access restrictions

On GitLab.com instance runners are added to the [global allowlist](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges), so that they are available regardless of IP restrictions.

Artifact and Registry downloading from runners is sourced from any Google or, in the case of MacOS runners, Amazon IP address in that region.
The download is therefore not added to the global allowlist.
To allow runner downloading, add the [outbound runner CIDR ranges](../gitlab_com/_index.md#ip-range) to your group allowlist.

## Restrict group access by domain

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Support for restricting group memberships to groups with a subset of the allowed email domains [added](https://gitlab.com/gitlab-org/gitlab/-/issues/354791) in GitLab 15.1.1

You can define an email domain allowlist at the top-level namespace to restrict which users can
access a group and its projects. A user's primary email domain must match an entry in the allowlist
to access that group. Subgroups inherit the same allowlist.

To restrict group access by domain:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. In the **Restrict membership by email** field, enter the domain names to allow.
1. Select **Save changes**.

The next time you attempt to add a user to the group, their [primary email](../profile/_index.md#change-your-primary-email)
must match one of the allowed domains.

You cannot restrict the most popular public email domains, such as:

- `aol.com`, `gmail.com`, `hotmail.co.uk`, `hotmail.com`,
- `hotmail.fr`, `icloud.com`, `live.com`, `mail.com`,
- `me.com`, `msn.com`, `outlook.com`,
- `proton.me`, `protonmail.com`, `tutanota.com`,
- `yahoo.com`, `yandex.com`, `zohomail.com`

When you share a group, both the source and target namespaces must allow the domains of the members' email addresses.

NOTE:
Removing a domain from the **Restrict membership by email** list does not remove existing users with that domain from the group or its projects.
Also, if you share a group or project with another group, the target group can add more email domains to its list that are not in the list of the source group.
Hence, this feature does not ensure that the current members always conform to the **Restrict membership by email** list.

## Prevent users from requesting access to a group

As a group Owner, you can prevent non-members from requesting access to
your group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Clear the **Allow users to request access** checkbox.
1. Select **Save changes**.

## Prevent project forking outside group

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

By default, projects in a group can be forked.
However, you can prevent the projects in a group from being forked outside of the current top-level group.

NOTE:
Prevent forking outside the top-level group when possible to reduce potential avenues for bad actors.
However, if you expect a lot of external collaboration, allowing forks outside the top-level group might be unavoidable.

Prerequisites:

- This setting is enabled on the top-level group only.
- All subgroups inherit this setting from the top-level group, and it cannot be
  changed at the subgroup level.

To prevent projects from being forked outside the group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Check **Prevent project forking outside current group**.
1. Select **Save changes**.

Existing forks are not removed.

## Prevent members from being added to projects in a group

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

As a group Owner, you can prevent any new project membership for all
projects in a group, allowing tighter control over project membership.

For example, if you want to lock the group for an [audit event](../../administration/audit_event_reports.md),
you can guarantee that project membership cannot be modified during the audit.

If group membership lock is enabled, the group Owner can still:

- Invite groups or add members to groups to give them access to projects in the **locked** group.
- Change the role of group members.

The setting does not cascade. Projects in subgroups observe the subgroup configuration, ignoring the parent group.

To prevent members from being added to projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Under **Membership**, select **Users cannot be added to projects in this group**.
1. Select **Save changes**.

After you lock the membership for a group:

- All users who previously had permissions can no longer add members to a group.
- API requests to add a new user to a project are not possible.

## Manage group memberships with LDAP

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - Support for custom roles for users synced in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435229) in GitLab 17.2.

Group syncing allows LDAP groups to be mapped to GitLab groups. This provides more control over per-group user management. To configure group syncing, edit the `group_base` **DN** (`'OU=Global Groups,OU=GitLab INT,DC=GitLab,DC=org'`). This **OU** contains all groups that are associated with GitLab groups.

Group links can be created by using either a CN or a filter. To create these group links, go to the group's **Settings > LDAP Synchronization** page. After configuring the link, it may take more than an hour for the users to sync with the GitLab group. After you have configured the link:

- In GitLab 16.7 and earlier, group Owners cannot add members to or remove members from the group. The LDAP server is considered the single source of truth for group membership for all users who have signed in with LDAP credentials.
- In GitLab 16.8 and later, group Owners can use the [member roles API](../../api/member_roles.md) or [group members API](../../api/members.md#add-a-member-to-a-group-or-project) to add a service account user to or remove a service account user from the group, even when LDAP synchronization is enabled for the group. Group Owners cannot add or remove non-service account users.

When a user belongs to two LDAP groups configured for the same GitLab group, GitLab assigns them the
higher of the two associated roles.
For example:

- User is a member of LDAP groups `Owner` and `Dev`.
- The GitLab Group is configured with these two LDAP groups.
- When group sync is completed, the user is granted the Owner role as this is the higher of the two LDAP group roles.

For more information on the administration of LDAP and group sync, refer to the [main LDAP documentation](../../administration/auth/ldap/ldap_synchronization.md#group-sync).

NOTE:
When you add LDAP group syncing, if an LDAP user is a group member and they are not part of the LDAP group, they are removed from the group.

You can use a workaround to [manage project access through LDAP groups](../project/working_with_projects.md#manage-project-access-through-ldap-groups).

### Create group links with a CN

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

To create group links with LDAP group CN:

<!-- vale gitlab_base.Spelling = NO -->

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP Group cn`.
1. In the **LDAP Group cn** field, begin typing the CN of the group. There is a dropdown list with matching CNs in the configured `group_base`. Select your CN from this list.
1. In the **LDAP Access** section, choose a [default role](../permissions.md) or [custom role](../custom_roles.md) for users synced in this group.
1. Select **Add Synchronization**.

<!-- vale gitlab_base.Spelling = YES -->

### Create group links with a filter

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

To create group links with an LDAP user filter:

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP user filter`.
1. Input your filter in the **LDAP User filter** box. Follow the [documentation on user filters](../../administration/auth/ldap/_index.md#set-up-ldap-user-filter).
1. In the **LDAP Access** section, choose a [default role](../permissions.md) or [custom role](../custom_roles.md) for users synced in this group.
1. Select **Add Synchronization**.

### Override user permissions

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

LDAP user permissions can be manually overridden by an administrator. To override a user's permissions:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**. If LDAP synchronization
   has granted a user a role with:
   - More permissions than the parent group membership, that user is displayed as having
     [direct membership](../project/members/_index.md#display-direct-members) of the group.
   - The same or fewer permissions than the parent group membership, that user is displayed as having
     [inherited membership](../project/members/_index.md#membership-types) of the group.
1. Optional. If the user you want to edit is displayed as having inherited membership,
   [filter the subgroup to show direct members](_index.md#filter-a-group) before
   overriding LDAP user permissions.
1. In the row for the user you are editing, select the pencil (**{pencil}**) icon.
1. Select **Edit permissions** in the dialog.

Now you can edit the user's permissions from the **Members** page.

## Troubleshooting

### Verify if access is blocked by IP restriction

If a user sees a 404 error when they try to access a specific group,
their access might be blocked by an IP restriction.

Search the `auth.log` rails log for one or more of the following entries:

- `json.message`: `'Attempting to access IP restricted group'`
- `json.allowed`: `false`

In viewing the log entries, compare `remote.ip` with the list of [allowed IP addresses](#restrict-group-access-by-ip-address) for the group.

### Cannot update permissions for a group member

If a group Owner cannot update permissions for a group member, check which memberships
are listed. Group Owners can only update direct memberships.

Members added directly to a subgroup are still considered [inherited members](../project/members/_index.md#membership-types)
if they have the same or a higher role in the parent group.

To view and update direct memberships, [filter the group to show direct members](_index.md#filter-a-group).

[Issue 337539](https://gitlab.com/gitlab-org/gitlab/-/issues/337539#note_1277786161) proposes a redesigned members page that lists both direct and indirect memberships with the ability to filter by type.

### Cannot clone or pull using SSH after enabling IP restrictions

If you have issues with Git SSH operations after adding IP address restrictions,
check if your connection defaults to IPv6.

Some operating systems prioritize IPv6 over IPv4 when both are available,
which might not be obvious from the Git terminal feedback.

If your connection uses IPv6, you can resolve this issue by adding the IPv6 address to the allowlist.
