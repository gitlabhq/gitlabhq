---
stage: Manage
group: Organization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Share a project with a group **(FREE)**

When you want a group to have access to your project,
you can invite [a group](../../group/index.md) to the project.
The group's members get access to the project, which becomes a *shared project*.

## Example

For a project that was created by `Group 1`:

- The members of `Group 1` have access to the project.
- The owner of `Group 1` can invite `Group 2` to the project.
This way, members of both `Group 1` and `Group 2` have access to the shared project.

## Prerequisites

To invite a group to a project, you must be at least one of the following:

- Explicitly defined as a [member](index.md) of the project.
- Explicitly defined as a member of a group or subgroup that has access to the project.
- An administrator.

In addition:

- The group you're inviting must have a more restrictive
 [visibility level](../../public_access.md#project-and-group-visibility)
  than the project. For example, you can invite:
  - A private group to a public project.
  - An internal group to a public project.
  - A private group to an internal project.

- The group or subgroup must be in the project's [namespace](../../namespace/index.md).
  For example, a project in the namespace `group/subgroup01/project`:
  - Can be shared with `group/subgroup02` or `group/subgroup01/subgroup03`.
  - Cannot be shared with `group`.

## Share a project with a group

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal
    window [with a flag](../../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208)
    in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9.
    [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

You can share a project with a group by inviting that group to the project.

To invite a group to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Project information > Members**.
1. Select **Invite a group**.
1. **Select a group** you want to add to the project.
1. **Select a role** you want to assign to the group.
1. Optional. Select an **Access expiration date**.
1. Select **Invite**.

All group members, members of subgroups, and members of other projects the group has access to
are given access to the project. In addition:

- On the group's page, the project is listed on the **Shared projects** tab.
- On the project's **Members** page, the group is listed on the **Groups** tab.
- Each user is assigned a maximum role.

## Maximum role

When multiple groups contain the same members, and the groups
have access to the same project, the group members are
given the most restrictive role for the project.

This most restrictive role is called the *maximum role*, or **Max role**.

The member's **Max role** is the more restrictive of:

- The role the user is assigned for the group.
- The role you chose when you invited the group to the project.

### View the member's Max role

To view the maximum role assigned to a member:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Project information > Members**.
1. In the **Max role** column, view the user's maximum assigned role.

## View a group's shared projects

In a group, a shared project is a project to which the group members gained access through the [**Invite group**](#share-a-project-with-a-group) action.

To view a group's shared projects:

1. On the top bar, select **Main menu > Group** and find your group.
1. On the group page, select the **Shared projects** tab.

A list of shared projects is displayed.

## Related topics

- [Prevent a project from being shared with groups](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).
