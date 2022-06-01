---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Subgroups **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/2772) in GitLab 9.0.

You can organize GitLab [groups](../index.md) into subgroups. You can use subgroups to:

- Separate internal and external organizations. Because every subgroup can have its own
  [visibility level](../../../development/permissions.md#general-permissions), you can host groups for different
  purposes under the same parent group.
- Organize large projects. You can use subgroups to give different access to parts of
  the source code.
- Manage people and control visibility. Give a user a different
  [role](../../permissions.md#group-members-permissions) for each group they're [a member of](#subgroup-membership).

Subgroups can:

- Belong to one immediate parent group.
- Have many subgroups.
- Be nested up to 20 levels.
- Use [runners](../../../ci/runners/index.md) registered to parent groups:
  - Secrets configured for the parent group are available to subgroup jobs.
  - Users with the Maintainer role in projects that belong to subgroups can see the details of runners registered to
    parent groups.

For example:

```mermaid
graph TD
    subgraph "Parent group"
      subgraph "Subgroup A"
        subgraph "Subgroup A1"
          G["Project E"]
        end
        C["Project A"]
        D["Project B"]
        E["Project C"]
      end
      subgraph "Subgroup B"
        F["Project D"]
      end
    end
```

## Create a subgroup

Prerequisites:

- You must either:
  - Have at least the Maintainer role for a group to create subgroups for it.
  - Have the [role determined by a setting](#change-who-can-create-subgroups). These users can create
    subgroups even if group creation is
    [disabled by an Administrator](../../admin_area/index.md#prevent-a-user-from-creating-groups) in the user's settings.

NOTE:
You cannot host a GitLab Pages subgroup website with a top-level domain name. For example, `subgroupname.example.io`.

To create a subgroup:

1. On the top bar, select **Menu > Groups** and find and select the parent group to add a subgroup to.
1. On the parent group's overview page, in the top right, select **New subgroup**.
1. Select **Create group**.
1. Fill in the fields. View a list of [reserved names](../../reserved_names.md) that cannot be used as group names.
1. Select **Create group**.

### Change who can create subgroups

To create a subgroup, you must have at least the Maintainer role on the group, depending on the group's setting. By
default:

- In GitLab 12.2 or later, users with at least the Maintainer role can create subgroups.
- In GitLab 12.1 or earlier, only users with the Owner role can create subgroups.

To change who can create subgroups on a group:

- As a user with the Owner role on the group:
  1. On the top bar, select **Menu > Groups** and find the group.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Permissions and group features**.
  1. Select a role from the **Allowed to create subgroups** dropdown.
- As an administrator:
  1. On the top bar, select **Menu > Admin**.
  1. On the left sidebar, select **Overview > Groups**.
  1. Select the group, and select **Edit**.
  1. Select a role from the **Allowed to create subgroups** dropdown.

For more information, view the [permissions table](../../permissions.md#group-members-permissions).

## Subgroup membership

NOTE:
There is a bug that causes some pages in the parent group to be accessible by subgroup members. For more details, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/340421).

When you add a member to a group, that member is also added to all subgroups. The user's permissions are inherited from
the group's parent.

Subgroup members can:

1. Be [direct members](../../project/members/index.md#add-users-to-a-project) of the subgroup.
1. [Inherit membership](../../project/members/index.md#inherited-membership) of the subgroup from the subgroup's parent group.
1. Be a member of a group that was [shared with the subgroup's top-level group](../index.md#share-a-group-with-another-group).

```mermaid
flowchart RL
  subgraph Group A
    A(Direct member)
    B{{Shared member}}
    subgraph Subgroup A
      H(1. Direct member)
      C{{2. Inherited member}}
      D{{Inherited member}}
      E{{3. Shared member}}
    end
    A-->|Direct membership of Group A\nInherited membership of Subgroup A|C
  end
  subgraph Group C
    G(Direct member)
  end
  subgraph Group B
    F(Direct member)
  end
  F-->|Group B\nshared with\nGroup A|B
  B-->|Inherited membership of Subgroup A|D
  G-->|Group C shared with Subgroup A|E
```

Group permissions for a member can be changed only by:

- Users with the Owner role on the group.
- Changing the configuration of the group the member was added to.

### Determine membership inheritance

To see if a member has inherited the permissions from a parent group:

1. On the top bar, select **Menu > Groups** and find the group.
1. Select **Group information > Members**.

Members list for an example subgroup _Four_:

![Group members page](img/group_members_v14_4.png)

In the screenshot above:

- Five members have access to group _Four_.
- User 0 has the Reporter role on group _Four_, and has inherited their permissions from group _One_:
  - User 0 is a direct member of group _One_.
  - Group _One_ is above group _Four_ in the hierarchy.
- User 1 has the Developer role on group _Four_ and inherited their permissions from group _Two_:
  - User 0 is a direct member of group _Two_, which is a subgroup of group _One_.
  - Groups _One / Two_ are above group _Four_ in the hierarchy.
- User 2 has the Developer role on group _Four_ and has inherited their permissions from group _Three_:
  - User 0 is a direct member of group _Three_, which is a subgroup of group _Two_. Group _Two_ is a subgroup of group
    _One_.
  - Groups _One / Two / Three_ are above group _Four_ the hierarchy.
- User 3 is a direct member of group _Four_. This means they get their Maintainer role directly from group _Four_.
- Administrator has the Owner role on group _Four_ and is a member of all subgroups. For that reason, as with User 3,
  the **Source** column indicates they are a direct member.

Members can be [filtered by inherited or direct membership](../index.md#filter-a-group).

### Override ancestor group membership

Users with the Owner role on a subgroup can add members to it.

You can't give a user a role on a subgroup that's lower than the roles they have on ancestor groups. To override a user's
role on an ancestor group, add the user to the subgroup again with a higher role. For example:

- If User 1 is added to group _Two_ with the Developer role, they inherit that role in every subgroup of group _Two_.
- To give User 1 the Maintainer role on group _Four_ (under _One / Two / Three_), add them again to group _Four_ with
  the Maintainer role.
- If User 1 is removed from group _Four_, their role falls back to their role on group _Two_. They have the Developer
  role on group _Four_ again.

## Mention subgroups

Mentioning subgroups ([`@<subgroup_name>`](../../discussions/index.md#mentions)) in issues, commits, and merge requests
notifies all members of that group. Mentioning works the same as for projects and groups, and you can choose the group
of people to be notified.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
