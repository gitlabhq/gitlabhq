---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Share projects with other groups **(FREE)**

You can share projects with other [groups](../../group/index.md). This makes it
possible to add a group of users to a project with a single action.

For example, if `Project A` belongs to `Group 1`, the members of `Group 1` have access to the project.
If `Project A` already belongs to another `Group 2`, the owner of `Group 2` can share `Project A`
with `Group 1`, so that both members of `Group 1` and `Group 2` have access to the project.

When a project is shared with a group:

- All group members, including members of subgroups or projects that belong to the group,
  are assigned the same role in the project.
  Each member's role is displayed in **Project information > Members**, in the **Max role** column.
  When sharing a project with a group, a user's assigned **Max role** is the lowest
  of either:

  - The role assigned in the group membership.
  - The maximum role selected when sharing the project with the group.

  Assigning a higher maximum role to the group doesn't give group users higher roles than
  the roles already assigned to them in the group.
- The group is listed in the **Groups** tab.
- The project is listed on the group dashboard.

Be aware of the restrictions that apply when you share projects with:

- [Groups with a more restrictive visibility level](#share-projects-with-groups-with-a-more-restrictive-visibility-level).
- [Restricted sharing](#prevent-project-sharing).

## Share projects with groups with a more restrictive visibility level

You can share projects only down the group's organization structure.
This means you can share a project with a group that has a more restrictive
[visibility level](../../public_access.md#project-and-group-visibility) than the project,
but not with a group that has a less restrictive visibility level.

For example, you can share:

- A public project with a private group.
- A public project with an internal group.
- An internal project with a private group.

This restriction applies to subgroups as well. For example, `group/subgroup01/project`:

- Can't be shared with `group`.
- Can be shared with `group/subgroup02` or `group/subgroup01/subgroup03`.

When you share a project with a group that has a more restrictive visibility level than the project:

- The group name is visible to all users that can view the project members page.
- Owners of the project have access to members of the group when they mention them in issues or merge requests.
- Project members who are direct or indirect members of the group can see
group members listed in addition to members of the project.

## Share a project with a group

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal
    window [with a flag](../../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208)
    in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9.
    [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

You can share a project only with groups:

- Where you have an explicitly defined [membership](index.md).
- That contain a nested subgroup or project you have an explicitly defined role for.
- You are an administrator of.

To share a project with a group:

1. On the top bar, select **Main menu > Projects** and find your project.
1. In the left navigation menu, select **Project information > Members**.
1. Select **Invite a group**.
1. **Select a group** you want to add to the project.
1. **Select a role** you want to assign to the group.
1. Optional. Select an **Access expiration date**.
1. Select **Invite**.

## Prevent project sharing

For more information, see [Prevent a project from being shared with groups](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).
