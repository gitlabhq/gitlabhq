---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group access and permissions

Configure your groups to control group permissions and access.

## Group push rules

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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
- Push rules set at the instance level, if no parent groups have push rules defined.

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
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To ensure only people from your organization can access particular resources, you can restrict access to groups by IP
address. This top-level group setting applies to:

- The GitLab UI, including subgroups, projects, and issues. It does not apply to GitLab Pages.
- The API.
- In self-managed installations of GitLab 15.1 and later, you can also configure
  [globally-allowed IP address ranges](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)
  at the group level.

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
- IP access restrictions for Git operations via SSH are supported on GitLab SaaS.
  IP access restrictions applied to self-managed instances are possible with [`gitlab-sshd`](../../administration/operations/gitlab_sshd.md)
  with [PROXY protocol](../../administration/operations/gitlab_sshd.md#proxy-protocol-support) enabled.
- IP restriction is not applicable to shared resources belonging to a group. Any shared resource is accessible to a user even if that user is not able to access the group.
- While IP restrictions apply to public projects, they aren't a complete firewall and cached files for a project may still be accessible to users not in the IP block

### GitLab.com access restrictions

On GitLab.com instance runners are added to the [global allowlist](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges), so that they are available regardless of IP restrictions.

Artifact and Registry downloading from runners is sourced from any Google or, in the case of MacOS runners, Amazon IP address in that region.
The download is therefore not added to the global allowlist.
To allow runner downloading, add the [outbound runner CIDR ranges](../gitlab_com/index.md#ip-range) to your group allowlist.

## Restrict group access by domain

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Support for restricting group memberships to groups with a subset of the allowed email domains [added](https://gitlab.com/gitlab-org/gitlab/-/issues/354791) in GitLab 15.1.1

To ensure only users with email addresses in specific domains are added to a group and its projects, define an email domain allowlist at the top-level namespace. Subgroups do not offer the ability to define an alternative allowlist.

To restrict group access by domain:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. In the **Restrict membership by email** field, enter the domain names.
1. Select **Save changes**.

Any time you attempt to add a new user, the user's [primary email](../profile/index.md#change-your-primary-email) is compared against this list.
Only users with a [primary email](../profile/index.md#change-your-primary-email) that matches any of the configured email domain restrictions
can be added to the group.

The most popular public email domains cannot be restricted, such as:

- `aol.com`, `gmail.com`, `hotmail.co.uk`, `hotmail.com`,
- `hotmail.fr`, `icloud.com`, `live.com`, `mail.com`,
- `me.com`, `msn.com`, `outlook.com`,
- `proton.me`, `protonmail.com`, `tutanota.com`,
- `yahoo.com`, `yandex.com`, `zohomail.com`

When you share a group, both the source and target namespaces must allow the domains of the members' email addresses.

NOTE:
Removing a domain from the **Restrict membership by email** list does not remove the users with this email domain from the groups and projects under this group.
Also, if you share a group or project with another group, the target group can add more email domains to its list that are not in the list of the source group.
Hence, this feature does not ensure that the current members always conform to the **Restrict membership by email** list.

## Prevent group sharing outside the group hierarchy

You can configure a top-level group so its subgroups and projects
cannot invite other groups outside of the top-level group's hierarchy.
This option is only available for top-level groups.

For example, in the following group and project hierarchy:

- **Animals > Dogs > Dog Project**
- **Animals > Cats**
- **Plants > Trees**

If you prevent group sharing outside the hierarchy for the **Animals** group:

- **Dogs** can invite the group **Cats**.
- **Dogs** cannot invite the group **Trees**.
- **Dog Project** can invite the group **Cats**.
- **Dog Project** cannot invite the group **Trees**.

To prevent sharing outside of the group's hierarchy:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Select **Members cannot invite groups outside of `<group_name>` and its subgroups**.
1. Select **Save changes**.

## Prevent a project from being shared with groups

[Sharing a project with another group](../project/members/share_project_with_groups.md)
increases the number of users who can invite yet more members to the project.
Each (sub)group can be an additional source of access permissions,
which can be confusing and difficult to control.

To restrict the permission to invite project members to a single source,
prevent a project from being shared with other groups:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select **Projects in `<group_name>` cannot be shared with other groups**.
1. Select **Save changes**.

This setting, when enabled, applies to all subgroups unless overridden by a group Owner. Groups already
added to a project lose access when the setting is enabled.

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
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

By default, projects in a group can be forked.
In [GitLab Premium and Ultimate tiers](https://about.gitlab.com/pricing/),
you can prevent the projects in a group from being forked outside of the current top-level group.

NOTE:
Whenever possible, you should prevent forking outside the top-level group. This setting reduces the number of avenues that bad actors can potentially use. However, if you expect a lot of collaboration from outside the top-level group, you might not want to prevent forking outside the top-level group.

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
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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

## Manage group memberships via LDAP

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Group syncing allows LDAP groups to be mapped to GitLab groups. This provides more control over per-group user management. To configure group syncing, edit the `group_base` **DN** (`'OU=Global Groups,OU=GitLab INT,DC=GitLab,DC=org'`). This **OU** contains all groups that are associated with GitLab groups.

Group links can be created by using either a CN or a filter. To create these group links, go to the group's **Settings > LDAP Synchronization** page. After configuring the link, it may take more than an hour for the users to sync with the GitLab group. After you have configured the link:

- In GitLab 16.7 and earlier, group Owners cannot add members to or remove members from the group. The LDAP server is considered the single source of truth for group membership for all users who have signed in with LDAP credentials.
- In GitLab 16.8 and later, group Owners can use the [member roles API](../../api/member_roles.md) to add a service account user to or remove a service account user from the group, even when LDAP synchronization is enabled for the group. Group Owners cannot add or remove non-service account users.

If a user is a member of two configured LDAP groups for the same GitLab group, they are granted the higher of the roles associated with the two LDAP groups.
For example:

- User is a member of LDAP groups `Owner` and `Dev`.
- The GitLab Group is configured with these two LDAP groups.
- When group sync is completed, the user is granted the Owner role as this is the higher of the two LDAP group roles.

For more information on the administration of LDAP and group sync, refer to the [main LDAP documentation](../../administration/auth/ldap/ldap_synchronization.md#group-sync).

NOTE:
When you add LDAP synchronization, if an LDAP user is a group member and they are not part of the LDAP group, they are removed from the group.

You can use a workaround to [manage project access through LDAP groups](../project/working_with_projects.md#manage-project-access-through-ldap-groups).

### Create group links via CN

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

To create group links via CN:

<!-- vale gitlab.Spelling = NO -->

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP Group cn`.
1. In the **LDAP Group cn** field, begin typing the CN of the group. There is a dropdown list with matching CNs in the configured `group_base`. Select your CN from this list.
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Select **Add Synchronization**.

<!-- vale gitlab.Spelling = YES -->

### Create group links via filter

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

To create group links via filter:

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP user filter`.
1. Input your filter in the **LDAP User filter** box. Follow the [documentation on user filters](../../administration/auth/ldap/index.md#set-up-ldap-user-filter).
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Select **Add Synchronization**.

### Override user permissions

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

LDAP user permissions can be manually overridden by an administrator. To override a user's permissions:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**. If LDAP synchronization
   has granted a user a role with:
   - More permissions than the parent group membership, that user is displayed as having
     [direct membership](../project/members/index.md#display-direct-members) of the group.
   - The same or fewer permissions than the parent group membership, that user is displayed as having
     [inherited membership](../project/members/index.md#display-inherited-members) of the group.
1. Optional. If the user you want to edit is displayed as having inherited membership,
   [filter the subgroup to show direct members](index.md#filter-a-group) before
   overriding LDAP user permissions.
1. In the row for the user you are editing, select the pencil (**{pencil}**) icon.
1. Select **Edit permissions** in the modal.

Now you can edit the user's permissions from the **Members** page.

## Troubleshooting

### Verify if access is blocked by IP restriction

If a user sees a 404 when they would usually expect access, and the problem is limited to a specific group, search the `auth.log` rails log for one or more of the following:

- `json.message`: `'Attempting to access IP restricted group'`
- `json.allowed`: `false`

In viewing the log entries, compare `remote.ip` with the list of [allowed IP addresses](#restrict-group-access-by-ip-address) for the group.

### Cannot update permissions for a group member

If a group Owner cannot update permissions for a group member, check which memberships
are listed. Group Owners can only update direct memberships.

If a parent group membership has the same or higher role than a subgroup, the
[inherited membership](../project/members/index.md#inherited-membership) is
listed on the subgroup members page, even if a [direct membership](../project/members/index.md#membership-types)
on the group exists.

To view and update direct memberships, [filter the group to show direct members](index.md#filter-a-group).

The need to filter members by type through a redesigned members page that lists both direct and inherited memberships is proposed in [issue 337539](https://gitlab.com/gitlab-org/gitlab/-/issues/337539#note_1277786161).
