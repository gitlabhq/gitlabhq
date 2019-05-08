# Groups

With GitLab Groups you can assemble related projects together
and grant members access to several projects at once.

Groups can also be nested in [subgroups](subgroups/index.md).

Find your groups by clicking **Groups** in the top navigation.

![GitLab Groups](img/groups.png)

> The groups dropdown in the top navigation was [introduced][ce-36234] in [GitLab 11.1](https://about.gitlab.com/2018/07/22/gitlab-11-1-released/#groups-dropdown-in-navigation).

The Groups page displays all groups you are a member of, how many projects it holds,
how many members it has, the group visibility, and, if you have enough permissions,
a link to the group settings. By clicking the last button you can leave that group.

## Use cases

You can create groups for numerous reasons. To name a few:

- Organize related projects under the same [namespace](#namespaces), add members to that
  group and grant access to all their projects at once
- Create a group, include members of your team, and make it easier to
  `@mention` all the team at once in issues and merge requests
  - Create a group for your company members, and create [subgroups](subgroups/index.md)
    for each individual team. Let's say you create a group called `company-team`, and among others,
    you created subgroups in this group for each individual team `backend-team`,
    `frontend-team`, and `production-team`:
     1. When you start a new implementation from an issue, you add a comment:
        _"`@company-team`, let's do it! `@company-team/backend-team` you're good to go!"_
     1. When your backend team needs help from frontend, they add a comment:
        _"`@company-team/frontend-team` could you help us here please?"_
     1. When the frontend team completes their implementation, they comment:
        _"`@company-team/backend-team`, it's done! Let's ship it `@company-team/production-team`!"_

## Namespaces

In GitLab, a namespace is a unique name to be used as a user name, a group name, or a subgroup name.

- `http://gitlab.example.com/username`
- `http://gitlab.example.com/groupname`
- `http://gitlab.example.com/groupname/subgroup_name`

For example, consider a user named Alex:

1. Alex creates an account on GitLab.com with the username `alex`;
   their profile will be accessed under `https://gitlab.example.com/alex`
1. Alex creates a group for their team with the group name `alex-team`;
   the group and its projects will be accessed under `https://gitlab.example.com/alex-team`
1. Alex creates a subgroup of `alex-team` with the subgroup name `marketing`;
   this subgroup and its projects will be accessed under `https://gitlab.example.com/alex-team/marketing`

By doing so:

- Any team member mentions Alex with `@alex`
- Alex mentions everyone from their team with `@alex-team`
- Alex mentions only the marketing team with `@alex-team/marketing`

## Issues and merge requests within a group

Issues and merge requests are part of projects. For a given group, view all the
[issues](../project/issues/index.md#issues-list) and [merge requests](../project/merge_requests/index.md#merge-requests-per-group) across all the projects in that group,
together in a single list view.

## Create a new group

> For a list of words that are not allowed to be used as group names see the
> [reserved names](../reserved_names.md).

You can create a group in GitLab from:

1. The Groups page: from the top menu, click **Groups**, and click the green button **New group**:

    ![new group from groups page](img/new_group_from_groups.png)

1. Elsewhere: expand the `plus` sign button on the top navbar and choose **New group**:

    ![new group from elsewhere](img/new_group_from_other_pages.png)

Add the following information:

![new group info](img/create_new_group_info.png)

1. The **Group name** will populate the URL automatically. Optionally, you can change it.
   This is the name that is displayed in the group views.
   The name can contain only:
     - Alphanumeric characters.
     - Underscores.
     - Dashes and dots.
     - Spaces.
1. The **Group URL**, which will be the namespace under which your projects will be hosted.
   The URL can contain only:
     - Alphanumeric characters.
     - Underscores.
     - Dashes and dots. It cannot start with dashes or end in dot.
1. Optionally, you can add a brief description to tell others
   what this group is about.
1. Optionally, choose an avatar for your group.
1. Choose the [visibility level](../../public_access/public_access.md).

## Add users to a group

Add members to a group by navigating to the group's dashboard, and clicking **Members**:

![add members to group](img/add_new_members.png)

Select the [permission level](../permissions.md#permissions) and add the new member. You can also set the expiring
date for that user, from which they will no longer have access to your group.

One of the benefits of putting multiple projects in one group is that you can
give a user to access to all projects in the group with one action.

Consider we have a group with two projects:

- On the **Group Members** page we can now add a new user to the group.
- Now because this user is a **Developer** member of the group, he automatically
  gets **Developer** access to **all projects** within that group.

If necessary, you can increase the access level of an individual user for a specific project,
by adding them again as a new member to the project with the new permission levels.

## Request access to a group

As a group owner you can enable or disable non members to request access to
your group. Go to the group settings and click on **Allow users to request access**.

As a user, you can request to be a member of a group. Go to the group you'd
like to be a member of, and click the **Request Access** button on the right
side of your screen.

![Request access button](img/request_access_button.png)

---

Group owners and maintainers will be notified of your request and will be able to approve or
decline it on the members page.

![Manage access requests](img/access_requests_management.png)

---

If you change your mind before your request is approved, just click the
**Withdraw Access Request** button.

![Withdraw access request button](img/withdraw_access_request_button.png)

## Add projects to a group

There are two different ways to add a new project to a group:

- Select a group and then click on the **New project** button.

    ![New project](img/create_new_project_from_group.png)

    You can then continue on [creating a project](../../gitlab-basics/create-project.md).

- While you are creating a project, select a group namespace
  you've already created from the dropdown menu.

    ![Select group](img/select_group_dropdown.png)

### Default project creation level

> [Introduced][ee-2534] in [GitLab Premium][ee] 10.5.
> Brought to [GitLab Starter][ee] in 10.7.
> [Moved](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/25975) to [GitLab Core](https://about.gitlab.com/pricing/) in 11.10.

Group owners or administrators can allow users with the
Developer role to create projects under groups.

By default, [Developers and Maintainers](../permissions.md#group-members-permissions) can create projects under a group, but this can be changed either within the group settings for a group, or
be set globally by a GitLab administrator in the Admin area
at **Settings > General > Visibility and access controls**.

Available settings are `No one`, `Maintainers`, or `Developers + Maintainers`.

## Transfer projects into groups

Learn how to [transfer a project into a group](../project/settings/index.md#transferring-an-existing-project-into-another-namespace).

## Sharing a project with a group

You can [share your projects with a group](../project/members/share_project_with_groups.md)
and give your group members access to the project all at once.

Alternatively, you can [lock the sharing with group feature](#share-with-group-lock).

## Manage group memberships via LDAP

In GitLab Enterprise Edition it is possible to manage GitLab group memberships using LDAP groups.
See [the GitLab Enterprise Edition documentation](../../integration/ldap.md) for more information.

## Epics **[ULTIMATE]**

> Introduced in [GitLab Ultimate][ee] 10.2.

Epics let you manage your portfolio of projects more efficiently and with less
effort by tracking groups of issues that share a theme, across projects and
milestones.

[Learn more about Epics.](epics/index.md)

## Group Security Dashboard **[ULTIMATE]**

Get an overview of the vulnerabilities of all the projects in a group and its subgroups.

[Learn more about the Group Security Dashboard.](security_dashboard/index.md)

## Insights **[ULTIMATE]**

> Introduced in [GitLab Ultimate][ee] 11.9 behind the `insights` feature flag.

Configure the Insights that matter for your groups or projects to explore data
such as triage hygiene, issues created/closed per a given period, average time
for merge requests to be merged and much more.

[Learn more about Insights](insights/index.md).

## Transferring groups

From GitLab 10.5, groups can be transferred in the following ways:

- Top-level groups can be transferred to a group, converting them into subgroups.
- Subgroups can be transferred to a new parent group.
- Subgroups can be transferred out from a parent group, converting them into top-level groups.

When transferring groups, note:

- Changing a group's parent can have unintended side effects. See [Redirects when changing repository paths](../project/index.md#redirects-when-changing-repository-paths).
- You can only transfer groups to groups you manage.
- You will need to update your local repositories to point to the new location.
- If the parent group's visibility is lower than the group's current visibility, visibility levels for subgroups and projects will be changed to match the new parent group's visibility.
- Only explicit group membership is transferred, not inherited membership. If the group's owners have only inherited membership, this would leave the group without an owner. In this case, the user transferring the group becomes the group's owner.

## Group settings

Once you have created a group, you can manage its settings by navigating to
the group's dashboard, and clicking **Settings**.

![group settings](img/group_settings.png)

### General settings

Besides giving you the option to edit any settings you've previously
set when [creating the group](#create-a-new-group), you can also
access further configurations for your group.

#### Changing a group's path

Changing a group's path can have unintended side effects. Read
[how redirects will behave](../project/index.md#redirects-when-changing-repository-paths)
before proceeding.

If you are vacating the path so it can be claimed by another group or user,
you may need to rename the group name as well since both names and paths must
be unique.

To change your group path:

1. Navigate to your group's **Settings > General**.
1. Enter a new name under "Group path".
1. Hit **Save group**.

CAUTION: **Caution:**
It is currently not possible to rename a namespace if it contains a
project with [Container Registry](../project/container_registry.md) tags,
because the project cannot be moved.

TIP: **TIP:**
If you want to retain ownership over the original namespace and
protect the URL redirects, then instead of changing a group's path or renaming a
username, you can create a new group and transfer projects to it.

#### Enforce 2FA to group members

Add a security layer to your group by
[enforcing two-factor authentication (2FA)](../../security/two_factor_authentication.md#enforcing-2fa-for-all-users-in-a-group)
to all group members.

#### Share with group lock

Prevent projects in a group from [sharing
a project with another group](../project/members/share_project_with_groups.md).
This allows for tighter control over project access.

For example, consider you have two distinct teams (Group A and Group B)
working together in a project.
To inherit the group membership, you share the project between the
two groups A and B. **Share with group lock** prevents any project within
the group from being shared with another group. By doing so, you
guarantee only the right group members have access to those projects.

To enable this feature, navigate to the group settings page. Select
**Share with group lock** and **Save the group**.

![Checkbox for share with group lock](img/share_with_group_lock.png)

#### Member Lock **[STARTER]**

With Member lock, it is possible to lock membership in a project to the
level of members in the group.

Member lock lets a group owner lock down any new project membership to all the
projects within the group, allowing tighter control over project membership.

For instance, if you want to lock the group for an [Audit Event](https://docs.gitlab.com/ee/administration/audit_events.html),
you enable Member lock to guarantee that membership of a project cannot be modified during that audit.

To enable this feature:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section and select **Member lock**.
1. Click the **Save changes** button.

![Checkbox for membership lock](img/member_lock.png)

This will disable the option for all users who previously had permissions to
operate project memberships so no new users can be added. Furthermore, any
request to add a new user to a project through API will not be possible.

#### Group file templates **[PREMIUM]**

Group file templates allow you to share a set of templates for common file
types with every project in a group. It is analogous to the
[instance template repository](https://docs.gitlab.com/ee/user/admin_area/settings/instance_template_repository.html)
feature, and the selected project should follow the same naming conventions as
are documented on that page.

Only projects that are in the group may be chosen as the source of templates.
This includes projects shared with the group, but **excludes** projects in
subgroups or parent groups of the group being configured.

This feature may be configured for subgroups as well as parent groups. A project
in a subgroup will have access to the templates for that subgroup, as well as
any parent groups.

![Group file template dropdown](img/group_file_template_dropdown.png)

To enable this feature, navigate to the group settings page, expand the
**Templates** section, choose a project to act as the template repository, and
**Save group**.

![Group file template settings](img/group_file_template_settings.png)

#### Group-level project templates **[PREMIUM]**

Define project templates at a group-level by setting a group as a template source.
[Learn more about group-level project templates](custom_project_templates.md).

### Advanced settings

- **Projects**: view all projects within that group, add members to each project,
  access each project's settings, and remove any project from the same screen.
- **Webhooks**: configure [webhooks](../project/integrations/webhooks.md) to your group.
- **Kubernetes cluster integration**: connect your GitLab group with [Kubernetes clusters](clusters/index.md).
- **Audit Events**: view [Audit Events](https://docs.gitlab.com/ee/administration/audit_events.html)
  for the group. **[STARTER ONLY]**
- **Pipelines quota**: keep track of the [pipeline quota](../admin_area/settings/continuous_integration.md) for the group.

## User contribution analysis **[STARTER]**

With [GitLab Contribution Analytics](contribution_analytics/index.md)
you have an overview of the contributions (pushes, merge requests,
and issues) performed by your group members.

## Issues analytics **[PREMIUM]**

With [GitLab Issues Analytics](issues_analytics/index.md), in groups, you can see a bar chart of the number of issues created each month.

[ee]: https://about.gitlab.com/pricing/
[ee-2534]: https://gitlab.com/gitlab-org/gitlab-ee/issues/2534
