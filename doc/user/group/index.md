---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Groups **(FREE)**

In GitLab, you use groups to manage one or more related projects at the same time.

You can use groups to manage permissions for your projects. If someone has access to
the group, they get access to all the projects in the group.

You can also view all of the issues and merge requests for the projects in the group,
and view analytics that show the group's activity.

You can use groups to communicate with all of the members of the group at once.

For larger organizations, you can also create [subgroups](subgroups/index.md).

## View groups

To view groups:

1. On the top bar, select **Menu > Groups**.
1. Select **Your Groups**. All groups you are a member of are displayed.
1. To view a list of public groups, select **Explore public groups**.

You can also view groups by namespace.

### Group visibility

Like projects, a group can be configured to limit the visibility of it to:

- Anonymous users.
- All signed-in users.
- Only explicit group members.

The restriction for [visibility levels](../admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels)
on the application setting level also applies to groups. If set to internal, the explore page is
empty for anonymous users. The group page has a visibility level icon.

Administrator users cannot create a subgroup or project with a higher visibility level than that of
the immediate parent group.

### Namespaces

In GitLab, a namespace is a unique name for a user, a group, or subgroup under
which a project can be created.

For example, consider a user named Alex:

| GitLab URL | Namespace |
| ---------- | --------- |
| Alex creates an account with the username `alex`: `https://gitlab.example.com/alex`. | The namespace in this case is `alex`. |
| Alex creates a group for their team with the group name `alex-team`. The group and its projects are available at: `https://gitlab.example.com/alex-team`. | The namespace in this case is `alex-team`. |
| Alex creates a subgroup of `alex-team` with the subgroup name `marketing`. The subgroup and its projects are available at: `https://gitlab.example.com/alex-team/marketing`. | The namespace in this case is `alex-team/marketing`. |

## Create a group

To create a group:

1. On the top bar, either:
   - Select **Menu > Groups**, and on the right, select **Create group**.
   - To the left of the search box, select the plus sign and then **New group**.
1. Select **Create group**.
1. Enter a name for the group in **Group name**. For a list of words that cannot be used as group names, see
   [reserved names](../reserved_names.md).
1. Enter a path for the group in **Group URL**, which is used for the [namespace](#namespaces).
1. Choose the [visibility level](../public_access.md).
1. Personalize your GitLab experience by answering the following questions:
   - What is your role?
   - Who will be using this group?
   - What will you use this group for?
1. Invite GitLab members or other users to join the group.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For details about groups, watch [GitLab Namespaces (users, groups and subgroups)](https://youtu.be/r0sJgjR2f5A).

## Add users to a group

You can give a user access to all projects in a group.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Select **Invite members**.
1. Fill in the fields.
   - The role applies to all projects in the group. [Learn more about permissions](../permissions.md).
   - On the **Access expiration date**, the user can no longer access projects in the group.
1. Select **Invite**.

Members that are not automatically added are displayed on the **Invited** tab.
Users can be on this tab because they:

- Have not yet accepted the invitation.
- Are waiting for [approval from an administrator](../admin_area/moderate_users.md).
- [Exceed the group user cap](#user-cap-for-groups).

## Request access to a group

As a user, you can request to be a member of a group, if an administrator allows it.

1. On the top bar, select **Menu > Groups** and find your group.
1. Under the group name, select **Request Access**.

As many as ten of the most-recently-active group owners receive an email with your request.
Any group owner can approve or decline the request.

If you change your mind before your request is approved, select
**Withdraw Access Request**.

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

## Change the owner of a group

You can change the owner of a group. Each group must always have at least one
member with the Owner role.

- As an administrator:
  1. Go to the group and from the left menu, select **Group information > Members**.
  1. Give a different member the **Owner** role.
  1. Refresh the page. You can now remove the **Owner** role from the original owner.
- As the current group's owner:
  1. Go to the group and from the left menu, select **Group information > Members**.
  1. Give a different member the **Owner** role.
  1. Have the new owner sign in and remove the **Owner** role from you.

## Remove a member from the group

Prerequisites:

- You must have the Owner role.
- The member must have direct membership in the group. If
  membership is inherited from a parent group, then the member can be removed
  from the parent group only.

To remove a member from a group:

1. Go to the group.
1. From the left menu, select **Group information > Members**.
1. Next to the member you want to remove, select **Delete**.
1. Optional. On the **Remove member** confirmation box, select the
  **Also unassign this user from linked issues and merge requests** checkbox.
1. Select **Remove member**.

## Filter and sort members in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21727) in GitLab 12.6.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/228675) in GitLab 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/289911) in GitLab 13.8.

To find members in a group, you can sort, filter, or search.

### Filter a group

Filter a group to find members. By default, all members in the group and subgroups are displayed.

1. Go to the group and select **Group information > Members**.
1. Above the list of members, in the **Filter members** box, enter filter criteria.
   - To view members in the group only, select **Membership = Direct**.
   - To view members of the group and its subgroups, select **Membership = Inherited**.
   - To view members with two-factor authentication enabled or disabled, select **2FA = Enabled** or **Disabled**.
   - [In GitLab 14.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/349887), to view GitLab users created by [SAML SSO](saml_sso/index.md) or [SCIM provisioning](saml_sso/scim_setup.md) select **Enterprise = true**.

### Search a group

You can search for members by name, username, or email.

1. Go to the group and select **Group information > Members**.
1. Above the list of members, in the **Filter members** box, enter search criteria.
1. To the right of the **Filter members** box, select the magnifying glass (**{search}**).

### Sort members in a group

You can sort members by **Account**, **Access granted**, **Max role**, or **Last sign-in**.

1. Go to the group and select **Group information > Members**.
1. Above the list of members, on the top right, from the **Account** list, select
   the criteria to filter by.
1. To switch the sort between ascending and descending, to the right of the **Account** list, select the
   arrow (**{sort-lowest}** or **{sort-highest}**).

## Mention a group in an issue or merge request

When you mention a group in a comment, every member of the group gets a to-do item
added to their To-do list.

1. Open the MR or issue.
1. In a comment, type `@` followed by the user, group, or subgroup namespace.
   For example, `@alex`, `@alex-team`, or `@alex-team/marketing`.
1. Select **Comment**.

A to-do item is created for all the group and subgroup members.

## Change the default branch protection of a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7583) in GitLab 12.9.
> - [Settings moved and renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/340403) in GitLab 14.9.

By default, every group inherits the branch protection set at the global level.

To change this setting for a specific group, see [group level default branch protection](../project/repository/branches/default.md#group-level-default-branch-protection).

To change this setting globally, see [initial default branch protection](../project/repository/branches/default.md#instance-level-default-branch-protection).

NOTE:
In [GitLab Premium or higher](https://about.gitlab.com/pricing/), GitLab administrators can choose to [disable group owners from updating the default branch protection](../project/repository/branches/default.md#prevent-overrides-of-default-branch-protection).

## Add projects to a group

There are two different ways to add a new project to a group:

- Select a group, and then select **New project**. You can then continue [creating your project](../../user/project/working_with_projects.md#create-a-project).
- While you are creating a project, select a group from the dropdown list.

  ![Select group](img/select_group_dropdown_13_10.png)

### Specify who can add projects to a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2534) in GitLab 10.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25975) from GitLab Premium to GitLab Free in 11.10.

By default, users with at least the Developer role can create projects under a group.

To change this setting for a specific group:

1. On the top bar, select **Menu > Groups**.
1. Select **Your Groups**.
1. Find the group and select it.
1. From the left menu, select **Settings > General**.
1. Expand the **Permissions and group features** section.
1. Select the desired option in the **Roles allowed to create projects** dropdown list.
1. Select **Save changes**.

To change this setting globally, see [Default project creation protection](../admin_area/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).

## Group activity analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207164) in GitLab 12.10 as a [Beta feature](../../policy/alpha-beta-support.md#beta-features).

For a group, you can view how many merge requests, issues, and members were created in the last 90 days.

These Group Activity Analytics can be enabled with the `group_activity_analytics` [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development).

![Recent Group Activity](img/group_activity_analytics_v13_10.png)

Changes to [group wikis](../project/wiki/group.md) do not appear in group activity analytics.

### View group activity

You can view the most recent actions taken in a group, either in your browser or in an RSS feed:

1. On the top bar, select **Menu > Groups**.
1. Select **Your Groups**.
1. Find the group and select it.
1. On the left sidebar, select **Group information > Activity**.

To view the activity feed in Atom format, select the
**RSS** (**{rss}**) icon.

## Share a group with another group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18328) in GitLab 12.7.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal window [with a flag](../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9.
    [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

Similar to how you [share a project with a group](../project/members/share_project_with_groups.md),
you can share a group with another group. To invite a group, you must be a member of it. Members get direct access
to the shared group. This includes members who inherited group membership from a parent group.

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
- All members of the `Engineering` group have access to the `Frontend` group. The same access levels of the members apply up to the maximum access level selected when sharing the group.

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

## Transfer a group

You can transfer groups in the following ways:

- Transfer a subgroup to a new parent group.
- Convert a top-level group into a subgroup by transferring it to the desired group.
- Convert a subgroup into a top-level group by transferring it out of its current group.

When transferring groups, note:

- Changing a group's parent can have unintended side effects. See [what happens when a repository path changes](../project/repository/index.md#what-happens-when-a-repository-path-changes).
- You can only transfer groups to groups you manage.
- You must update your local repositories to point to the new location.
- If the immediate parent group's visibility is lower than the group's current visibility, visibility levels for subgroups and projects change to match the new parent group's visibility.
- Only explicit group membership is transferred, not inherited membership. If the group's owners have only inherited membership, this leaves the group without an owner. In this case, the user transferring the group becomes the group's owner.
- Transfers fail if [packages](../packages/index.md) exist in any of the projects in the group, or in any of its subgroups.

## Change a group's path

Changing a group's path (group URL) can have unintended side effects. Read
[how redirects behave](../project/repository/index.md#what-happens-when-a-repository-path-changes)
before you proceed.

If you are changing the path so it can be claimed by another group or user,
you must rename the group too. Both names and paths must
be unique.

To retain ownership of the original namespace and protect the URL redirects,
create a new group and transfer projects to it instead.

To change your group path (group URL):

1. Go to your group's **Settings > General** page.
1. Expand the **Advanced** section.
1. Under **Change group URL**, enter a new name.
1. Select **Change group URL**.

WARNING:
It is not possible to rename a namespace if it contains a
project with [Container Registry](../packages/container_registry/index.md) tags,
because the project cannot be moved.

## Use a custom name for the initial branch

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43290) in GitLab 13.6.

When you create a new project in GitLab, a default branch is created with the
first push. The group owner can
[customize the initial branch](../project/repository/branches/default.md#group-level-custom-initial-branch-name)
for the group's projects to meet your group's needs.

## Remove a group

To remove a group and its contents:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Remove group** section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

A group can also be removed from the groups dashboard:

1. On the top bar, select **Menu > Groups**.
1. Select **Your Groups**.
1. Select (**{ellipsis_v}**) for the group you want to delete.
1. Select **Delete**.
1. In the Remove group section, select **Remove group**.
1. Type the group name.
1. Select **Confirm**.

This action removes the group. It also adds a background job to delete all projects in the group.

Specifically:

- In [GitLab 12.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/33257), on [GitLab Premium](https://about.gitlab.com/pricing/premium/) or higher tiers, this action adds a background job to mark a group for deletion. By default, the job schedules the deletion 7 days in the future. You can modify this waiting period through the [instance settings](../admin_area/settings/visibility_and_access_controls.md#deletion-protection).
- In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/39504), if the user who sets up the deletion is removed from the group before the
deletion happens, the job is cancelled, and the group is no longer scheduled for deletion.

## Remove a group immediately **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336985) in GitLab 14.2.

If you don't want to wait, you can remove a group immediately.

Prerequisites:

- You must have at least the Owner role for a group.
- You have [marked the group for deletion](#remove-a-group).

To immediately remove a group marked for deletion:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the "Permanently remove group" section, select **Remove group**.
1. Confirm the action when asked to.

Your group, its subgroups, projects, and all related resources, including issues and merge requests,
are deleted.

## Restore a group **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

To restore a group that is marked for deletion:

1. Go to your group's **Settings > General** page.
1. Expand the **Path, transfer, remove** section.
1. In the Restore group section, select **Restore group**.

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
1. Select **Members cannot invite groups outside of `<group_name>` and its subgroups**.
1. Select **Save changes**.

## Prevent a project from being shared with groups

Prevent projects in a group from [sharing
a project with another group](../project/members/share_project_with_groups.md) to enable tighter control over project access.

To prevent a project from being shared with other groups:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Select **Projects in `<group_name>` cannot be shared with other groups**.
1. Select **Save changes**.

This setting applies to all subgroups unless overridden by a group owner. Groups already
added to a project lose access when the setting is enabled.

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

- You must be assigned the Owner role) for the group.

To specify a user cap:

1. On the top bar, select **Menu > Groups** and find your group.
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

1. On the top bar, select **Menu > Groups** and find your group.
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

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. On the **Seats** tab, under the alert, select **View pending approvals**.
1. For each member you want to approve, select **Approve**.

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
1. Under **Membership**, select **Users cannot be added to projects in this group**.
1. Select **Save changes**.

All users who previously had permissions can no longer add members to a group.
API requests to add a new user to a project are not possible.

## Export members as CSV **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/287940) in GitLab 14.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/336520) in GitLab 14.5.

You can export a list of members in a group or subgroup as a CSV.

1. Go to your group or subgroup and select either **Group information > Members** or **Subgroup information > Members**.
1. Select **Export as CSV**.
1. After the CSV file has been generated, it is emailed as an attachment to the user that requested it.

## Group access restriction by IP address **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1985) in GitLab 12.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/215410) from GitLab Ultimate to GitLab Premium in 13.1.

To ensure only people from your organization can access particular
resources, you can restrict access to groups by IP address. This group-level setting
applies to:

- The GitLab UI, including subgroups, projects, issues, and pages.
- [In GitLab 12.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/12874), the API.
- Using Git over SSH on GitLab.com.

### Security implications

You should consider some security implications before configuring IP address restrictions.

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
- IP access restrictions for Git operations via SSH are supported only on GitLab SaaS.
  IP access restrictions applied to self-managed instances block SSH completely.

### Restrict group access by IP address

To restrict group access by IP address:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. In the **Restrict access by IP address** field, enter IPv4 or IPv6 address ranges in CIDR notation.
1. Select **Save changes**.

In self-managed installations of GitLab 15.1 and later, you can also configure
[globally-allowed IP address ranges](../admin_area/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)
at the group level.

## Restrict group access by domain **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7297) in GitLab 12.2.
> - Support for specifying multiple email domains [added](https://gitlab.com/gitlab-org/gitlab/-/issues/33143) in GitLab 13.1.
> - Support for restricting access to projects in the group [added](https://gitlab.com/gitlab-org/gitlab/-/issues/14004) in GitLab 14.1.2.
> - Support for restricting group memberships to groups with a subset of the allowed email domains [added](https://gitlab.com/gitlab-org/gitlab/-/issues/354791) in GitLab 15.0.1

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

When you share a group, both the source and target namespaces must allow the domains of the members' email addresses.

## Restrict Git access protocols

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/365601) in GitLab 15.1 [with a flag](../../administration/feature_flags.md) named `group_level_git_protocol_control`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to
[enable the feature flag](../../administration/feature_flags.md) named `group_level_git_protocol_control`. On GitLab.com,
this feature is available.

You can set the permitted protocols used to access a group's repositories to either SSH, HTTPS, or both. This setting
is disabled when the [instance setting](../admin_area/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols) is
configured by an administrator.

To change the permitted Git access protocols for a group:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Choose the permitted protocols from **Enabled Git access protocols**.
1. Select **Save changes**.

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
in a subgroup has access to the templates for that subgroup, as well as
any immediate parent groups.

To learn how to create templates for issues and merge requests, see
[Description templates](../project/description_templates.md).

Define project templates at a group level by setting a group as the template source.
[Learn more about group-level project templates](custom_project_templates.md).

### Enable group file template **(PREMIUM)**

To enable group file templates:

1. Go to the group's **Settings > General** page.
1. Expand the **Templates** section.
1. Choose a project to act as the template repository.
1. Select **Save changes**.

## Disable email notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23585) in GitLab 12.2.

You can disable all email notifications related to the group, which includes its subgroups and projects.

To disable email notifications:

1. Go to the group's **Settings > General** page.
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

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Select **Group mentions are disabled**.
1. Select **Save changes**.

## Enable delayed project deletion **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.
> - [Inheritance and enforcement added](https://gitlab.com/gitlab-org/gitlab/-/issues/321724) in GitLab 13.11.
> - [Instance setting to enable by default added](https://gitlab.com/gitlab-org/gitlab/-/issues/255449) in GitLab 14.2.
> - [Instance setting is inherited and enforced when disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.
> - [User interface changed](https://gitlab.com/gitlab-org/gitlab/-/issues/352961) in GitLab 15.1.

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

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions and group features** section.
1. Scroll to:
   - (GitLab 15.1 and later) **Deletion protection** and select **Keep deleted projects**.
   - (GitLab 15.0 and earlier) **Enable delayed project deletion** and tick the checkbox.
1. Optional. To prevent subgroups from changing this setting, select:
   - (GitLab 15.1 and later), **Enforce deletion protection for all subgroups**
   - (GitLab 15.0 and earlier), **Enforce for all subgroups**.
1. Select **Save changes**.

NOTE:
In GitLab 13.11 and above the group setting for delayed project deletion is inherited by subgroups. As discussed in [Cascading settings](../../development/cascading_settings.md) inheritance can be overridden, unless enforced by an ancestor.

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

## Group merge request approval settings **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285458) in GitLab 13.9. [Deployed behind the `group_merge_request_approval_settings_feature_flag` flag](../../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/285410) in GitLab 14.5.
> - [Feature flag `group_merge_request_approval_settings_feature_flag`](https://gitlab.com/gitlab-org/gitlab/-/issues/343872) removed in GitLab 14.9.

Group approval settings manage [project merge request approval settings](../project/merge_requests/approvals/settings.md)
at the top-level group level. These settings [cascade to all projects](../project/merge_requests/approvals/settings.md#settings-cascading)
that belong to the group.

To view the merge request approval settings for a group:

1. Go to the top-level group's **Settings > General** page.
1. Expand the **Merge request approvals** section.
1. Select the settings you want.
1. Select **Save changes**.

Support for group-level settings for merge request approval rules is tracked in this [epic](https://gitlab.com/groups/gitlab-org/-/epics/4367).

## Related topics

- [Group wikis](../project/wiki/index.md)
- [Maximum artifacts size](../admin_area/settings/continuous_integration.md#maximum-artifacts-size).
- [Repositories analytics](repositories_analytics/index.md): View overall activity of all projects with code coverage.
- [Contribution analytics](contribution_analytics/index.md): View the contributions (pushes, merge requests,
  and issues) of group members.
- [Issue analytics](issues_analytics/index.md): View a bar chart of your group's number of issues per month.
- Use GitLab as a [dependency proxy](../packages/dependency_proxy/index.md) for upstream Docker images.
- [Epics](epics/index.md): Track groups of issues that share a theme.
- [Security Dashboard](../application_security/security_dashboard/index.md): View the vulnerabilities of all
  the projects in a group and its subgroups.
- [Insights](insights/index.md): Configure insights like triage hygiene, issues created/closed per a given period, and
  average time for merge requests to be merged.
- [Webhooks](../project/integrations/webhooks.md).
- [Kubernetes cluster integration](clusters/index.md).
- [Audit Events](../../administration/audit_events.md#group-events).
- [CI/CD minutes quota](../../ci/pipelines/cicd_minutes.md): Keep track of the CI/CD minute quota for the group.
- [Integrations](../admin_area/settings/project_integration_management.md).
- [Transfer a project into a group](../project/settings/index.md#transfer-a-project-to-another-namespace).
- [Share a project with a group](../project/members/share_project_with_groups.md): Give all group members access to the project at once.
- [Lock the sharing with group feature](#prevent-a-project-from-being-shared-with-groups).
- [Enforce two-factor authentication (2FA)](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group): Enforce 2FA
  for all group members.
- Namespaces [API](../../api/namespaces.md) and [Rake tasks](../../raketasks/index.md).
- [Control access and visibility](../admin_area/settings/visibility_and_access_controls.md).

## Troubleshooting

### Verify if access is blocked by IP restriction

If a user sees a 404 when they would normally expect access, and the problem is limited to a specific group, search the `auth.log` rails log for one or more of the following:

- `json.message`: `'Attempting to access IP restricted group'`
- `json.allowed`: `false`

In viewing the log entries, compare the `remote.ip` with the list of
[allowed IPs](#group-access-restriction-by-ip-address) for the group.

### Validation errors on namespaces and groups

[GitLab 14.4 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70365) performs
the following checks when creating or updating namespaces or groups:

- Namespaces must not have parents.
- Group parents must be groups and not namespaces.

In the unlikely event that you see these errors in your GitLab installation,
[contact Support](https://about.gitlab.com/support/) so that we can improve this validation.
