---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Share projects with other groups

You can share projects with other [groups](../../group/index.md). This makes it
possible to add a group of users to a project with a single action.

## Groups as collections of users

Groups are used primarily to [create collections of projects](../../group/index.md), but you can also
take advantage of the fact that groups define collections of _users_, namely the group
members.

## Sharing a project with a group of users

NOTE:
In GitLab 13.11, you can [replace this form with a modal window](#share-a-project-modal-window).

The primary mechanism to give a group of users, say 'Engineering', access to a project,
say 'Project Acme', in GitLab is to make the 'Engineering' group the owner of 'Project
Acme'. But what if 'Project Acme' already belongs to another group, say 'Open Source'?
This is where the group sharing feature can be of use.

To share 'Project Acme' with the 'Engineering' group:

1. For 'Project Acme' use the left navigation menu to go to **Project information > Members**.
1. Select the **Invite group** tab.
1. Add the 'Engineering' group with the maximum access level of your choice.
1. Optionally, select an expiring date.
1. Click **Invite**.
1. After sharing 'Project Acme' with 'Engineering':
   - The group is listed in the **Groups** tab.
   - The project is listed on the group dashboard.

Note that you can only share a project with:

- groups for which you have an explicitly defined membership
- groups that contain a nested subgroup or project for which you have an explicitly defined role

Administrators are able to share projects with any group in the system.

### Share a project modal window

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/247208) in GitLab 13.11.
> - [Deployed behind a feature flag](../../feature_flags.md), disabled by default.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - Replaces the existing form with buttons to open a modal window.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-modal-window). **(FREE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

In GitLab 13.11, you can optionally replace the sharing form with a modal window.
To share a project after enabling this feature:

1. Go to your project's page.
1. In the left sidebar, go to **Project information > Members**, and then select **Invite a group**.
1. Select a group, and select a **Max role**.
1. (Optional) Select an **Access expiration date**.
1. Select **Invite**.

### Enable or disable modal window **(FREE SELF)**

The modal window for sharing a project is under development and is ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:invite_members_group_modal)
```

To disable it:

```ruby
Feature.disable(:invite_members_group_modal)
```

## Maximum access level

In the example above, the maximum access level of 'Developer' for members from 'Engineering' means that users with higher access levels in 'Engineering' ('Maintainer' or 'Owner') only have 'Developer' access to 'Project Acme'.

## Sharing public project with private group

When sharing a public project with a private group, owners and maintainers of the project see the name of the group in the `members` page. Owners also have the possibility to see members of the private group they don't have access to when mentioning them in the issue or merge request.

## Share project with group lock

It is possible to prevent projects in a group from [sharing
a project with another group](../members/share_project_with_groups.md).
This allows for tighter control over project access.

Learn more about [Share with group lock](../../group/index.md#prevent-a-project-from-being-shared-with-groups).
