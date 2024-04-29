---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Share a project with a group

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Similar to how you [share a group with another group](../../group/manage.md#share-a-group-with-another-group),
you can share a project with a group by inviting that group to the project.

Prerequisites:

- You must be at least one of the following:
  - Explicitly defined as a [member](index.md) of the project.
  - Explicitly defined as a member of a group or subgroup that has access to the project.
  - An administrator.
- You must be a member of the invited group or subgroup.

To invite a group to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. Select **Invite a group**.
1. **Select a group** you want to add to the project.
1. **Select a role** you want to assign to the group.
1. Optional. Select an **Access expiration date**.
1. Select **Invite**.

## Maximum role

When you invite a group to a project, the maximum role is the highest level of access the invited group members are allowed to have in the project.

When multiple groups contain the same members, and the groups
have access to the same project, the group members are
given the highest access level of the two for the project.

The member's **Max role** is the more restrictive of:

- The role the user is assigned for the group.
- The role you chose when you invited the group to the project.

NOTE:
The Max role does not elevate the privileges of users.
For example, if a group member has the role of Developer, and the group is invited to a project with a Max role of Maintainer, the member's role is not elevated to Maintainer.

### Which roles you can assign

In GitLab [16.7](https://gitlab.com/gitlab-org/gitlab/-/issues/233408) and later, the maximum role you can assign depends on whether you have the Owner or Maintainer role for the project. The maximum role you can set is:

- Owner (`50`), if you have the Owner role for the project.
- Maintainer (`40`), if you have the Maintainer role for the project.

In GitLab 16.6 and earlier, the maximum role you can assign to an invited group is Maintainer (`40`).

### View the member's Max role

To view the maximum role assigned to a member:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. In the **Max role** column, view the user's maximum assigned role.

## View a group's shared projects

In a group, a shared project is a project to which the group members gained access through the [**Invite group**](#share-a-project-with-a-group) action.

To view a group's shared projects:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the group page, select the **Shared projects** tab.

A list of shared projects is displayed.

## Related topics

- [Sharing projects and groups](sharing_projects_groups.md)
- [Prevent a project from being shared with groups](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).
- [Prevent group sharing outside the group hierarchy](../../group/access_and_permissions.md#prevent-group-sharing-outside-the-group-hierarchy).
