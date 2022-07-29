---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group access and permissions

Configure your groups to control group permissions and access.

## Group push rules **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34370) in GitLab 12.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/224129) in GitLab 13.4.

Group push rules allow group maintainers to set
[push rules](../project/repository/push_rules.md) for newly created projects in the specific group.

To configure push rules for a group:

1. Go to the groups's **Push Rules** page.
1. Select the settings you want.
1. Select **Save Push Rules**.

The group's new subgroups have push rules set for them based on either:

- The closest parent group with push rules defined.
- Push rules set at the instance level, if no parent groups have push rules defined.

## Restrict group access by IP address **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1985) in GitLab 12.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/215410) from GitLab Ultimate to GitLab Premium in 13.1.

To ensure only people from your organization can access particular
resources, you can restrict access to groups by IP address. This group-level setting
applies to:

- The GitLab UI, including subgroups, projects, and issues.
- [In GitLab 12.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/12874), the API.

### Security implications

You should consider some security implications before configuring IP address restrictions.

- Restricting HTTP traffic on GitLab.com with IP address restrictions causes SSH requests (including Git operations over
  SSH) to fail. For more information, see [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/271673).
- Administrators and group owners can access group settings from any IP address, regardless of IP restriction. However:
  - Groups owners cannot access projects belonging to the group when accessing from a disallowed IP address.
  - Administrators can access projects belonging to the group when accessing from a disallowed IP address.
    Access to projects includes cloning code from them.
  - Users can still see group and project names and hierarchies. Only the following are restricted:
    - [Groups](../../api/groups.md), including all [group resources](../../api/api_resources.md#group-resources).
    - [Project](../../api/projects.md), including all [project resources](../../api/api_resources.md#project-resources).
- When you register a runner, it is not bound by the IP restrictions. When the runner requests a new job or an update to
  a job's state, it is also not bound by the IP restrictions. But when the running CI/CD job sends Git requests from a
  restricted IP address, the IP restriction prevents code from being cloned.
- Users may still see some events from the IP restricted groups and projects on their dashboard. Activity may include
  push, merge, issue, or comment events.

### Restrict group access by IP address

To restrict group access by IP address:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. In the **Allow access to the following IP addresses** field, enter IPv4 or IPv6 address ranges in CIDR notation.
1. Select **Save changes**.

In self-managed installations of GitLab 15.1 and later, you can also configure
[globally-allowed IP address ranges](../admin_area/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)
at the group level.

## Restrict group access by domain **(PREMIUM)**

> - Support for specifying multiple email domains [added](https://gitlab.com/gitlab-org/gitlab/-/issues/33143) in GitLab 13.1.
> - Support for restricting access to projects in the group [added](https://gitlab.com/gitlab-org/gitlab/-/issues/14004) in GitLab 14.1.2.

You can prevent users with email addresses in specific domains from being added to a group and its projects.

To restrict group access by domain:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. In the **Restrict membership by email** field, enter the domain names.
1. Select **Save changes**.

Any time you attempt to add a new user, the user's [primary email](../profile/index.md#change-your-primary-email) is compared against this list.
Only users with a [primary email](../profile/index.md#change-your-primary-email) that matches any of the configured email domain restrictions
can be added to the group.

The most popular public email domains cannot be restricted, such as:

- `gmail.com`, `yahoo.com`, `aol.com`, `icloud.com`
- `hotmail.com`, `hotmail.co.uk`, `hotmail.fr`
- `msn.com`, `live.com`, `outlook.com`

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

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Select **Prevent members from sending invitations to groups outside of `<group_name>` and its subgroups**.
1. Select **Save changes**.

## Prevent a project from being shared with groups

Prevent projects in a group from [sharing
a project with another group](../project/members/share_project_with_groups.md) to enable tighter control over project access.

To prevent a project from being shared with other groups:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Select **Prevent sharing a project in `<group_name>` with other groups**.
1. Select **Save changes**.

This setting applies to all subgroups unless overridden by a group owner. Groups already
added to a project lose access when the setting is enabled.

## Prevent users from requesting access to a group

As a group owner, you can prevent non-members from requesting access to
your group.

1. On the top bar, select **Menu > Groups**.
1. Select **Your Groups**.
1. Find the group and select it.
1. From the left menu, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Clear the **Allow users to request access** checkbox.
1. Select **Save changes**.

## Prevent project forking outside group **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216987) in GitLab 13.3.

By default, projects in a group can be forked.
Optionally, on [GitLab Premium](https://about.gitlab.com/pricing/) or higher tiers,
you can prevent the projects in a group from being forked outside of the current top-level group.

This setting will be removed from the SAML setting page, and migrated to the
group settings page. In the interim period, both of these settings are taken into consideration.
If even one is set to `true`, then the group does not allow outside forks.

To prevent projects from being forked outside the group:

1. Go to the top-level group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Check **Prevent project forking outside current group**.
1. Select **Save changes**.

Existing forks are not removed.

## Prevent members from being added to projects in a group **(PREMIUM)**

As a group owner, you can prevent any new project membership for all
projects in a group, allowing tighter control over project membership.

For example, if you want to lock the group for an [Audit Event](../../administration/audit_events.md),
you can guarantee that project membership cannot be modified during the audit.

You can still invite groups or to add members to groups, implicitly giving members access to projects in the **locked** group.

The setting does not cascade. Projects in subgroups observe the subgroup configuration, ignoring the parent group.

To prevent members from being added to projects in a group:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Under **Membership**, select **Prevent adding new members to projects within this group**.
1. Select **Save changes**.

All users who previously had permissions can no longer add members to a group.
API requests to add a new user to a project are not possible.

## Manage group memberships via LDAP **(PREMIUM SELF)**

Group syncing allows LDAP groups to be mapped to GitLab groups. This provides more control over per-group user management. To configure group syncing, edit the `group_base` **DN** (`'OU=Global Groups,OU=GitLab INT,DC=GitLab,DC=org'`). This **OU** contains all groups that are associated with GitLab groups.

Group links can be created by using either a CN or a filter. To create these group links, go to the group's **Settings > LDAP Synchronization** page. After configuring the link, it may take more than an hour for the users to sync with the GitLab group.

For more information on the administration of LDAP and group sync, refer to the [main LDAP documentation](../../administration/auth/ldap/ldap_synchronization.md#group-sync).

NOTE:
When you add LDAP synchronization, if an LDAP user is a group member and they are not part of the LDAP group, they are removed from the group.

### Create group links via CN **(PREMIUM SELF)**

To create group links via CN:

<!-- vale gitlab.Spelling = NO -->

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP Group cn`.
1. In the **LDAP Group cn** field, begin typing the CN of the group. There is a dropdown list with matching CNs in the configured `group_base`. Select your CN from this list.
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Select **Add Synchronization**.

<!-- vale gitlab.Spelling = YES -->

### Create group links via filter **(PREMIUM SELF)**

To create group links via filter:

1. Select the **LDAP Server** for the link.
1. As the **Sync method**, select `LDAP user filter`.
1. Input your filter in the **LDAP User filter** box. Follow the [documentation on user filters](../../administration/auth/ldap/index.md#set-up-ldap-user-filter).
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Select **Add Synchronization**.

### Override user permissions **(PREMIUM SELF)**

LDAP user permissions can be manually overridden by an administrator. To override a user's permissions:

1. Go to your group's **Group information > Members** page.
1. In the row for the user you are editing, select the pencil (**{pencil}**) icon.
1. Select **Edit permissions** in the modal.

Now you can edit the user's permissions from the **Members** page.

## Troubleshooting

### Verify if access is blocked by IP restriction

If a user sees a 404 when they would normally expect access, and the problem is limited to a specific group, search the `auth.log` rails log for one or more of the following:

- `json.message`: `'Attempting to access IP restricted group'`
- `json.allowed`: `false`

In viewing the log entries, compare the `remote.ip` with the list of
[allowed IPs](#restrict-group-access-by-ip-address) for the group.
