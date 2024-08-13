---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Members of a project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Members are the users and groups who have access to your project.

Each member gets a role, which determines what they can do in the project.

## Membership types

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to display invited group members on the Members tab of the Members page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
> - Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is available.

Users can become members of a group or project directly or indirectly.
Indirect membership can be inherited, shared, or inherited shared.

| Membership type                               | Membership process |
| --------------------------------------------- | ------------------ |
| [Direct](#add-users-to-a-project)             | The user is added directly to the current group or project. |
| [Indirect](#indirect-membership)  | The user is not added directly to the current group or project. Instead, the user becomes a member by inheriting from a parent group, or inviting the current group or project to another group. |
| [Inherited](#inherited-membership)            | The user is a member of a parent group that contains the current group or project. |
| [Shared](share_project_with_groups.md) | The user is a member of a group or project invited to the current group or project or one of its ancestors. |
| [Inherited shared](../../group/manage.md#share-a-group-with-another-group) | The user is a member of a parent of a group or project invited to the current group or project. |

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart RL
  accTitle: Membership types
  accDescr: Describes membership types and their inheritance

  subgraph Group A
    A(Direct member)
    B{{Shared member}}
    subgraph Project X
      H(Direct member)
      C{{Inherited member}}
      D{{Inherited shared member}}
      E{{Shared member}}
    end
    A-->|Inherited membership in Project X\nDirect membership in Group A|C
  end
  subgraph Group C
    G(Direct member)
  end
  subgraph Group B
    F(Direct member)
  end
  F-->|Group B\ninvited to\nGroup A|B
  B-->|Inherited membership in Project X\nIndirect membership in Group A|D
  G-->|Group C invited to Project X|E
```

## Add users to a project

> - Expiring access email notification [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12704) in GitLab 16.2.

Add users to a project so they become direct members and have permission
to perform actions.

Prerequisites:

- You must have the Owner or Maintainer role.
- [Group membership lock](../../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group) must be disabled.
- If [sign-up is disabled](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups), an administrator must add the user by email first.

To add a user to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Select **Invite members**.
1. If the user:

   - Has a GitLab account, enter their username.
   - Doesn't have a GitLab account, enter their email address.

1. Select a [default role](../../permissions.md) or [custom role](../../custom_roles.md).
1. Optional. Select an **Access expiration date**.
   From that date onward, the user can no longer access the project.

   If you selected an access expiration date, the project member gets an email notification
   seven days before their access expires.

   WARNING:
   If you give a member the Maintainer role and select an expiration date, that member
   has full permissions for the time they are in the role. This includes the ability
   to extend their own time in the Maintainer role.

1. Select **Invite**.
   If you invited the user using their:

   - GitLab username, they are added to the members list.
   - Email address, an invitation is sent to their email address, and they are prompted to create an account.
     If the invitation is not accepted, GitLab sends reminder emails two, five, and ten days later.
     Unaccepted invites are automatically deleted after 90 days.

### Which roles you can assign

The maximum role you can assign depends on whether you have the Owner or Maintainer
role for the group. For example, the maximum role you can set is:

- Owner (`50`), if you have the Owner role for the project.
- Maintainer (`40`), if you have the Maintainer role on the project.

The Owner [role](../../permissions.md#project-members-permissions) can be added for the group only.

## Inherited membership

When your project belongs to a group, project members inherit their role
from the group.

![Project members page](img/project_members_v14_4.png)

In this example:

- Three members have access to the project.
- **User 0** is a Reporter and has inherited their role in the project from the **demo** group,
  which contains the project.
- **User 1** has been added directly to the project. In the **Source** column, they are listed
  as a **Direct member**.
- **Administrator** is the [Owner](../../permissions.md) and member of all groups.
  They have inherited their role in the project from the **demo** group.

If a user is:

- A direct member of a project, the **Expiration** and **Max role** fields can be updated directly on the project.
- An inherited member from a parent group, the **Expiration** and **Max role** fields must be updated on the parent group that the member originates from.

## Indirect membership

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/444476) in GitLab 16.10 [with a flag](../../feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
> - Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is available.

If your project belongs to a group, the users gain membership to the project through either inheritance from a parent group or through sharing the project or the project's parent group with another group.

![Project members page](img/project_members_v16_10.png)

In this example:

- Three members have access to the project.
- **User 0** and **User 1** have the Guest role in the project. They have indirect membership through **Twitter** group, which contains the project.
- **Administrator** is the [Owner](../../permissions.md) of the group.

If a user is:

- A direct member of a project, the **Expiration** and **Max role** fields can be updated directly in the project.
- An indirect member from a parent group or shared group, the **Expiration** and **Max role** fields must be updated in the group that the member originates from.

## Add groups to a project

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to display invited group members on the Members tab of the Members page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
> - Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is available.

When you add a group to a project, every group member (direct or inherited) gets access to the project.
Each member's access is based on the:

- Role they're assigned in the group.
- Maximum role you choose when you invite the group.

If a group member has a role in the group with fewer permissions than the maximum project role, the member keeps the permissions of their group role.
For example, if you add a member with the Guest role to a project with a maximum role of Maintainer, the member has only the permissions of the Guest role in the project.

Prerequisites:

- You must have the Maintainer or Owner role.
- Sharing the project with other groups must not be [prevented](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).

To add a group to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Select **Invite a group**.
1. Select a group.
1. Select the highest [role](../../permissions.md) for users in the group.
1. Optional. Select an **Access expiration date**.
   From that date onward, the group can no longer access the project.
1. Select **Invite**.

The invited group is displayed on the **Groups** tab.
Private groups are masked from unauthorized users.
Private groups are displayed in project settings for protected branches, protected tags, and protected environments.
The members of the invited group are not displayed on the **Members** tab, but are displayed if the `webui_members_inherited_users` feature flag is enabled.
The **Members** tab shows:

- Members who were directly added to the project.
- Inherited members of the group [namespace](../../namespace/index.md) that the project was added to.

## Share a project with a group

Instead of adding users one by one, you can [share a project with an entire group](share_project_with_groups.md).

## Import members from another project

You can import another project's direct members to your own project.
Imported project members retain the same permissions as the project you import them from.

NOTE:
Only direct members of a project are imported. Inherited or shared members of a project are not imported.

Prerequisites:

- You must have the Maintainer or Owner role.

If the importing member's role in the target project is:

- Maintainer, then members with the Owner role in the source project are imported with the Maintainer role.
- Owner, then members with the Owner role in the source project are imported with the Owner role.

To import a project's members:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Select **Import from a project**.
1. Select the project. You can view only the projects for which you're a maintainer.
1. Select **Import project members**.

If the import is successful, a success message is displayed.
To view the imported members on the **Members** tab, refresh the page.

## Remove a member from a project

If a user is:

- A direct member of a project, you can remove them directly from the project.
- An inherited member from a parent group, you can only remove them from the parent group itself.

Prerequisites:

- To remove direct members that have the:
  - Maintainer, Developer, Reporter, or Guest role, you must have the Maintainer role.
  - Owner role, you must have the Owner role.
- Optional. Unassign the member from all issues and merge requests that
  are assigned to them.

To remove a member from a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Next to the project member you want to remove, select **Remove member**.
1. Optional. On the confirmation dialog, select the
   **Also unassign this user from related issues and merge requests** checkbox.
1. To prevent leaks of sensitive information from private projects, verify the
   member has not forked the private repository or created webhooks. Existing forks continue to receive
   changes from the upstream project, and webhooks continue to receive updates. You may also want to configure your project
   to prevent projects in a group
   [from being forked outside their group](../../group/access_and_permissions.md#prevent-project-forking-outside-group).
1. Select **Remove member**.

## Ensure removed users cannot invite themselves back

Malicious users with the Maintainer or Owner role could exploit a race condition that allows
them to invite themselves back to a group or project that a GitLab administrator has removed them from.

To avoid this problem, GitLab administrators can:

- Remove the malicious user session from the [GitLab Rails console](../../../administration/operations/rails_console.md).
- Impersonate the malicious user to:
  - Remove the user from the project.
  - Log the user out of GitLab.
- Block the malicious user account.
- Remove the malicious user account.
- Change the password for the malicious user account.

## Filter and sort project members

You can filter and sort members in a project.

### Display direct members

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. In the **Filter members** box, select `Membership` `=` `Direct`.
1. Press <kbd>Enter</kbd>.

### Display inherited members

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. In the **Filter members** box, select `Membership` `=` `Inherited`.
1. Press <kbd>Enter</kbd>.

### Search for members in a project

To search for a project member:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. In the search box, enter the member's name, username, or email.
1. Press <kbd>Enter</kbd>.

### Sort members in a project

You can sort members in ascending or descending order by:

- **Account** name
- **Access granted** date
- **Max role** the members have in the group
- **User created** date
- **Last activity** date
- **Last sign-in** date

To sort members:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. At the top of the member list, from the dropdown list, select the item you want to sort by.

## Request access to a project

GitLab users can request to become a member of a project.

1. On the left sidebar, select **Search or go to** and find the project you want to be a member of.
1. In the top right, select the vertical ellipsis (**{ellipsis_v}**) and select **Request Access**.

An email is sent to the most recently active project Maintainers or Owners.
Up to ten project Maintainers or Owners are notified.
Any project Owner or Maintainer can approve or decline the request.
Project Maintainers cannot approve Owner role access requests.

If a project does not have any direct Owners or Maintainers, the notification is sent to the
most recently active Owners of the project's parent group.

### Withdraw an access request to a project

You can withdraw an access request to a project before the request is approved.
To withdraw the access request:

1. On the left sidebar, select **Search or go to** and find the project you requested access to.
1. Next to the project name, select **Withdraw Access Request**.

## Prevent users from requesting access to a project

You can prevent users from requesting access to a project.

Prerequisites:

- You must have the Owner role for the project.
- The project must be public.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Project visibility**, ensure the **Users can request access** checkbox is not selected.
1. Select **Save changes**.

## Membership and visibility rights

Depending on their membership type, members of groups or projects are granted different [visibility levels](../../../user/public_access.md)
and rights into the group or project.

The following table lists the membership and visibility rights of project members.

| Action | Direct project member | Inherited project member | Direct shared project member | Inherited shared project member |
| --- | ------------------- | ---------------------- | -------------------------- | ----------------------------- |
| Generate boards | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View issues of parent groups <sup>1</sup> | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View labels of parent groups | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View milestones of parent groups | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Be shared into other groups | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |  **{dotted-circle}** No |
| Be imported into other projects | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | **{dotted-circle}** No |
| Share the project with other members | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

**Footnotes:**

1. Users can view only issues of projects they have access to.

The following table lists the membership and visibility rights of group members.

| Action | Direct group member | Inherited group member | Direct shared group member | Inherited shared group member |
| --- | ------------------- | ---------------------- | -------------------------- | ----------------------------- |
| Generate boards | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View issues of parent groups | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View labels of parent groups | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| View milestones of parent groups | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

In the following example, `User` is a:

- Direct member of `subgroup`.
- Inherited member of `subsubgroup`.
- Indirect member of `subgroup-2` and `subgroup-3`.
- Indirect inherited member of `subsubgroup-2` and `subsubgroup-3`.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
  accTitle: Diagram of group inheritance
  accDescr: User inheritance, both direct and indirect through subgroups
  classDef user stroke:green,color:green;

  root --> subgroup --> subsubgroup
  root-2 --> subgroup-2 --> subsubgroup-2
  root-3 --> subgroup-3 --> subsubgroup-3
  subgroup -. shared .-> subgroup-2 -. shared .-> subgroup-3

  User-. member .- subgroup

  class User user
```
