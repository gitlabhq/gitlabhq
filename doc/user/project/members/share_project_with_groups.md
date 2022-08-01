---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Share projects with other groups **(FREE)**

You can share projects with other [groups](../../group/index.md). This makes it
possible to add a group of users to a project with a single action.

## Groups as collections of users

Groups are used primarily to [create collections of projects](../../group/index.md), but you can also
take advantage of the fact that groups define collections of _users_, namely the group
members.

## Share a project with a group of users

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11 from a form to a modal
    window [with a flag](../../feature_flags.md). Disabled by default.
> - Modal window [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/247208)
    in GitLab 14.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) in GitLab 14.9.
    [Feature flag `invite_members_group_modal`](https://gitlab.com/gitlab-org/gitlab/-/issues/352526) removed.

You can share a project only with:

- Groups for which you have an explicitly defined [membership](index.md).
- Groups that contain a nested subgroup or project for which you have an explicitly defined role.

Administrators can share projects with any group in the instance.

The primary mechanism to give a group of users, say 'Engineering', access to a project,
say 'Project Acme', in GitLab is to make the 'Engineering' group the owner of 'Project
Acme'. But what if 'Project Acme' already belongs to another group, say 'Open Source'?
This is where the group sharing feature can be of use.

To share 'Project Acme' with the 'Engineering' group:

1. For 'Project Acme' use the left navigation menu to go to **Project information > Members**.
1. Select **Invite a group**.
1. Add the 'Engineering' group with the maximum access level of your choice.
1. Optional. Select an **Access expiration date**.
1. Select **Invite**.

After sharing 'Project Acme' with 'Engineering':

- The group is listed in the **Groups** tab.
- The project is listed on the group dashboard.

When you share a project, be aware of the following restrictions and outcomes:

- [Maximum access level](#maximum-access-level)
- [Sharing projects with groups of a higher restrictive visibility level](#sharing-projects-with-groups-of-a-higher-restrictive-visibility-level)
- [Sharing project with group lock](#share-project-with-group-lock)

## Maximum access level

In the example above, the maximum access level of 'Developer' for members from 'Engineering' means that users with higher access levels in 'Engineering' ('Maintainer' or 'Owner') only have 'Developer' access to 'Project Acme'.

### Share a project with a subgroup

You can't share a project with a group that's an ancestor of a [subgroup](../../group/subgroups/index.md) the project is
in. That means you can only share down the hierarchy. For example, `group/subgroup01/project`:

- Can not be shared with `group`.
- Can be shared with `group/subgroup02` or  `group/subgroup01/subgroup03`.

## Sharing projects with groups of a higher restrictive visibility level

There are several outcomes you must be aware of when you share a project with a group that has a more restrictive [visibility level](../../public_access.md#project-and-group-visibility) than the project. For example, when you:

- Share a public project with a private group.
- Share a public project with an internal group.
- Share an internal project with a private group.

The following outcomes occur:

- The group name is visible to all users that can view the project members page.
- Owners of the project have access to members of the group when they mention them in issues or merge requests.
- Project members who are direct or indirect members of the group can see group members listed in addition to members of the project.

## Share project with group lock

It is possible to prevent projects in a group from [sharing
a project with another group](../members/share_project_with_groups.md).
This allows for tighter control over project access.

Learn more about [Share with group lock](../../group/access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).
