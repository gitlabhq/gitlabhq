---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage projects
description: Settings, configuration, project activity, and project deletion.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Most work in GitLab is done in a [project](_index.md). Files and
code are saved in projects, and most features are in the scope of projects.

## Project overview

{{< history >}}

- Project creation date [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19452) in GitLab 16.10.

{{< /history >}}

When you select a project, the **Project overview** page shows the project contents:

- Files in the repository
- Project information (description)
- Topics
- Badges
- Number of stars, forks, commits, branches, tags, releases, and environments in the project
- Project storage size
- Optional files and configurations
- `README` or index file
  - Wiki page
  - License
  - Changelog
  - Contributing guidelines
  - Kubernetes cluster
  - CI/CD configuration
  - Integrations
  - GitLab Pages
- Creation date

For public projects, and members of internal and private projects
with [permissions to view the project's code](../permissions.md#project-members-permissions),
the project overview page shows:

- A [`README` or index file](repository/files/_index.md#readme-and-index-files).
- A list of directories in the project's repository.

For users without permission to view the project's code, the overview page shows:

- The wiki homepage.
- The list of issues in the project.

You can access a project by using its ID instead of its name at `https://gitlab.example.com/projects/<id>`.
For example, if in your personal namespace `alex` you have a project `my-project` with the ID `123456`,
you can access the project either at `https://gitlab.example.com/alex/my-project` or `https://gitlab.example.com/projects/123456`.

{{< alert type="note" >}}

In GitLab 17.5 and later, you can also use `https://gitlab.example.com/-/p/<id>` for this endpoint.

{{< /alert >}}

## Find the Project ID

You might need the project ID if you want to interact with the project using the [GitLab API](../../api/_index.md).

To find the project ID:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the project overview page, in the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}).
1. Select **Copy project ID**.

## View projects

Use the **Projects** list to view:

- All the projects on an instance
- The projects you work with or own
- Inactive projects, including archived projects and projects pending deletion

### View all projects on an instance

To view the projects on your GitLab instance:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Explore**.
1. Optional. Select a tab to filter which projects are displayed.

If you are not authenticated, the list shows public projects only.

### View projects you work with

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13066) in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `your_work_projects_vue`. Disabled by default.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) tab label from **Yours** to **Member** in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `your_work_projects_vue`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.

{{< /history >}}

To view the projects you have interacted with:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **View all my projects**.
1. Optional. Select a tab to filter which projects are displayed:
   - **Contributed**: Projects where you have:
     - Created issues, merge requests, or epics
     - Commented on issues, merge requests, or epics
     - Closed issues, merge requests, or epics
     - Pushed commits
     - Approved merge requests
     - Merged merge requests
   - **Starred**: Projects you have [starred](#star-a-project)
   - **Personal**: Projects created under your personal namespace
   - **Member**: Projects you are a member of
   - **Inactive**: Archived projects and projects pending deletion

You can also view your starred and personal projects from your personal profile:

1. On the left sidebar, select your avatar and then your username. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. On the left sidebar, select **Starred projects** or **Personal projects**.

### View inactive projects

{{< history >}}

- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) tab label from "Pending deletion" to "Inactive" in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `your_work_projects_vue`. Disabled by default.
- [Changed tab label generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in GitLab 18.0.

{{< /history >}}

A project is inactive when it is either pending deletion or it has been archived.

To view all inactive projects:

1. Select either:
   - **View all my projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. Select the **Inactive** tab.

Each inactive project in the list displays a badge to indicate that the project is either
archived or pending deletion.

If the project is pending deletion, the list also shows:

- The time the project is scheduled for final deletion.
- A **Restore** action. When you restore a project:
  - The **Pending deletion** label is removed. The project is no longer scheduled for deletion.
  - The project is removed from the **Inactive** tab.

### View only projects you own

To view only the projects you are the owner of:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select either:
   - **View all your projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. Above the list of projects, select **Search or filter results**.
1. From the **Role** dropdown list, select **Owner**.

## View project activity

To view the activity of a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Manage** > **Activity**.
1. Optional. To filter activity by contribution type, select a tab:

   - **All**: All contributions by project members.
   - **Push events**: Push events in the project.
   - **Merge events**: Accepted merge requests in the project.
   - **Issue events**: Issues opened and closed in the project.
   - **Comments**: Comments posted by project members.
   - **Designs**: Designs added, updated, and removed in the project.
   - **Team**: Members who joined and left the project.

GitLab removes project activity events older than three years from the events table for performance reasons.

## Filter projects by language

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385465) in GitLab 15.9 [with a flag](../../administration/feature_flags/_index.md) named `project_language_search`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110956) in GitLab 15.9. Feature flag `project_language_search` removed.

{{< /history >}}

You can filter projects by the programming language they use. To do this:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select either:
   - **View all your projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. Above the list of projects, select **Search or filter results**.
1. From the **Language** dropdown list, select the language you want to filter projects by.

A list of projects that use the selected language is displayed.

## Star a project

You can star projects you use frequently to make them easier to find.

To star a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the upper-right corner of the page, select **Star**.

## Leave a project

{{< history >}}

- The button to leave a project [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/431539) to the Actions menu in GitLab 16.7.

{{< /history >}}

When you leave a project:

- You are no longer a project member and cannot contribute.
- All the issues and merge requests that were assigned
  to you are unassigned.

Prerequisites:

- You can leave a project this way only when a project is part of a group under a [group namespace](../namespace/_index.md).
- You must be a [direct member](members/_index.md#membership-types) of the project.

To leave a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the project overview page, in the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}).
1. Select **Leave project**, then **Leave project** again.

## Edit a project

Use the project general settings to edit your project details.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. In the **Project name** text box, enter your project name. See the [limitations on project names](../reserved_names.md).
1. Optional. In the **Project description** text box, enter your project description. The description is limited to 2,000 characters.
Components published in the CI/CD catalog require a project description.
1. Select **Save changes**.

### Rename a repository

A project's repository name defines its URL.

Prerequisites:

- You must be an administrator or have the Maintainer or Owner role for the project.

{{< alert type="note" >}}

When you change the repository path, users may experience issues if they push to, or pull from, the old URL.
For more information on redirect duration and its side-effects, see
[redirects when renaming repositories](repository/_index.md#repository-path-changes).

{{< /alert >}}

To rename a repository:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Change path** text box, edit the path.
1. Select **Change path**.

### Add a project avatar

Add a project avatar to help visually identify your project. If you do not add an avatar, GitLab displays the first letter of your project name as the default project avatar.

To add a project avatar, use one of the following methods:

- Add a logo to your repository.
- Upload an avatar in your project settings.

#### Add a logo to your repository

If you haven't uploaded an avatar to your project settings, GitLab looks for a file named `logo` in your repository to use as the default project avatar.

Prerequisites:

- You must have at least the Maintainer role for the project.
- Your file must be 200 KB or smaller. The ideal image size is 192 x 192 pixels.
- The file must be named `logo` with the extension `.png`, `.jpg`, or `.gif`. For example, `logo.gif`.

To add a logo file to use as your project avatar:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the root of your project repository, upload the logo file.

#### Upload an avatar in project settings

Prerequisites:

- You must have at least the Maintainer role for the project.
- Your file must be 200 KB or smaller. The ideal image size is 192 x 192 pixels.
- The image must be one of the following file types:
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

To upload an avatar in your project settings:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. In the **Project avatar** section, select **Choose file**.
1. Select your avatar file.
1. Select **Save changes**.

## Delete a project

{{< history >}}

- Default behavior [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) to delayed project deletion for Premium and Ultimate tiers on [GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in 16.0.
- Default behavior changed to delayed project deletion for [GitLab Free](https://gitlab.com/groups/gitlab-org/-/epics/17208) and [personal projects](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in 18.0.

{{< /history >}}

By default, when you delete a project for the first time, it enters a pending deletion state.
Delete a project again to remove it immediately.

Prerequisites:

- You must have the Owner role for a project.
- Owners must be [allowed to delete projects](../../administration/settings/visibility_and_access_controls.md#restrict-project-deletion-to-administrators).

To delete a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Delete project** section, select **Delete**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.

This action adds a background job to mark a project for deletion. On GitLab.com, the project is deleted after 30 days. On GitLab Self-Managed,
you can modify the retention period through the [instance settings](../../administration/settings/visibility_and_access_controls.md#deletion-protection).

If the user who scheduled the project deletion loses access to the project before the deletion occurs
(for example, by leaving the project, having their role downgraded, or being banned from the project),
the deletion job instead restores the project, and the project is no longer scheduled for deletion.

{{< alert type="warning" >}}

If the user who scheduled the project deletion regains Owner role or administrator access before the job runs, then the job removes the project permanently.

{{< /alert >}}

You can also [delete projects using the Rails console](troubleshooting.md#delete-a-project-using-console).

## Delete a project immediately

{{< history >}}

- Option to delete projects immediately as a group setting removed [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.
- Option to delete projects immediately [moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/561680) in GitLab 18.4 [with a flag](../../administration/feature_flags/_index.md) named `disallow_immediate_deletion`. Disabled by default.
- [Replaced](https://gitlab.com/gitlab-org/gitlab/-/issues/569453) in GitLab 18.5 by an instance setting to allow immediate deletion of groups and projects scheduled for deletion. [Controlled by a flag](../../administration/feature_flags/_index.md) named `allow_immediate_namespaces_deletion`. Feature flag is disabled by default.

{{< /history >}}

{{< alert type="warning" >}}

On GitLab.com and GitLab Dedicated, after a project is deleted, its data is retained for 30 days, and immediate deletion is not available.
If you must delete a project immediately on GitLab.com, you can open a [support ticket](https://about.gitlab.com/support/).

{{< /alert >}}

If you do not want to wait for the configured retention period to delete a project,
you can delete the project immediately.

Prerequisites:

- You must have the Owner role for a project.
- You have [scheduled the project for deletion](#delete-a-project).

To immediately delete a project scheduled for deletion:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Delete project** section, select **Delete immediately**.
1. On the confirmation dialog, enter the project name and select **Confirm**.

This action deletes the project and all related resources, including issues and merge requests.

### Restore a project

{{< history >}}

- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the project.

To restore a project pending deletion:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Restore project** section, select **Restore project**.

## Archive a project

{{< history >}}

- Pages removal [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343109) in GitLab 17.5.

{{< /history >}}

Archive a project to make it read-only and preserve its data for future reference.

When you archive a project:

- The project becomes inactive and displays an `Archived` badge
- Most features become read-only, including repositories, issues, merge requests, and packages
- Fork relationships are removed and open merge requests from forks are closed
- Deployed Pages are removed along with custom domains
- Scheduled CI/CD pipelines stop running
- Pull mirroring stops

Prerequisites:

- You must be an administrator or have the Owner role for the project.

To archive a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Archive project** section, select **Archive**.

To archive a project from the **Your work** list view directly:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **View all my projects**.
1. In the **Member** tab, find the project you want to archive and select ({{< icon name="ellipsis_v" >}}).
1. Select **Archive**.

This action is also available on other list pages.

### Unarchive a project

When you unarchive a project:

- Read-only restrictions are removed
- The project is no longer marked as inactive
- Scheduled CI/CD pipelines resume automatically
- Pull mirroring resumes automatically

Projects that were archived as part of group archiving cannot be unarchived individually.
You must [unarchive the parent group](../group/manage.md#unarchive-a-group) to unarchive all its projects and subgroups.

{{< alert type="note" >}}

Deployed Pages are not automatically restored. You must rerun the pipeline to restore Pages.

{{< /alert >}}

Prerequisites:

- You must be an administrator or have the Owner role for the project.

To unarchive a project:

1. Find the archived project.
   1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   1. Select **View all my projects**.
   1. In the **Inactive** tab, select your project.
1. On the left sidebar, select **Settings** > **General**.
1. Under **Advanced**, select **Expand**.
1. In the **Unarchive project** section, select **Unarchive**.

To unarchive a project from the **Your work** list view directly:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **View all my projects**.
1. In the **Inactive** tab, find the project you want to unarchive and select ({{< icon name="ellipsis_v" >}}).
1. Select **Unarchive**.

This action is also available on other list pages.

## Transfer a project

{{< history >}}

- Support for transferring projects with container images within the same top-level namespace [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/499163) on GitLab.com in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `transfer_project_with_tags`. Disabled by default.
- Support for transferring projects with container images within the same top-level namespace [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/499163) in GitLab 17.7. Feature flag removed.

{{< /history >}}

Transfer a project to move it to a different group.
A project transfer includes:

- Project components:
  - Issues
  - Merge requests
  - Pipelines
  - Dashboards
- Project members:
  - Direct members
  - Membership invitations

   {{< alert type="note" >}}

   Members with [inherited membership](members/_index.md#membership-types)
   in the project lose access unless they are also members of the target group.
   The project inherits new member permissions from the group you transfer it to.

   {{< /alert >}}

The project's [path also changes](repository/_index.md#repository-path-changes), so make sure to update the URLs to the project components where necessary.

New project-level labels are created for issues and merge requests if matching group labels don't already exist in the target namespace.

If a project contains issues assigned to an epic, and that epic is not available in the target
group, GitLab creates a copy of the epic in the target group. When you transfer multiple projects
with issues assigned to the same epic, GitLab creates a separate copy of that epic in the target
group for each project.

{{< alert type="warning" >}}

Errors during the transfer process may lead to data loss of the project's components or dependencies of end users.

{{< /alert >}}

Prerequisites:

- You must have at least the Maintainer role for the [group](../group/_index.md#create-a-group) you are transferring to.
- You must be the Owner of the project you transfer.
- The group must allow creation of new projects.
- For projects where the container registry is enabled:
  - On GitLab.com: You can only transfer projects within the same top-level namespace.
  - On GitLab Self-Managed: The project must not contain [container images](../packages/container_registry/_index.md#move-or-rename-container-registry-repositories).
- The project must not have a security policy.
  If a security policy is assigned to the project, it is automatically unassigned during the transfer.
- If the root namespace changes, you must remove npm packages that follow the [naming convention](../packages/npm_registry/_index.md#naming-convention) from the project.
  After you transfer the project you can either:

  - Update the package scope with the new root namespace path, and publish it again to the project.
  - Republish the package to the project without updating the root namespace path, which causes the package to no longer follow the naming convention.
    If you republish the package without updating the root namespace path, it will not be available for the [instance endpoint](../packages/npm_registry/_index.md#install-from-an-instance).

To transfer a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the namespace to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

You are redirected to the project's new page and GitLab applies a redirect. For more information about repository redirects, see [repository path changes](repository/_index.md#repository-path-changes).

{{< alert type="note" >}}
Administrators can also transfer projects from the [Admin area](../../administration/admin_area.md#administering-projects).

{{< /alert >}}

### Transfer a GitLab.com project to a different subscription tier

When you transfer a project from a namespace licensed for GitLab.com Premium or Ultimate to GitLab Free:

- [Project access tokens](settings/project_access_tokens.md) are revoked.
- [Pipeline subscriptions](../../ci/pipelines/_index.md#trigger-a-pipeline-when-an-upstream-project-is-rebuilt)
  and [test cases](../../ci/test_cases/_index.md) are deleted.

## Manage projects with the Actions menu

You can view a list of all your projects and
manage them with the **Actions** menu.

Prerequisites:

- You must have the required [project permissions](../../user/permissions.md#projects) to perform the action.

To manage projects with the **Actions** menu:

1. On the left sidebar, select **Search or go to** > **View all my projects**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the **Projects** page, find your project and select the **Actions** menu ({{< icon name="ellipsis_v" >}}).
1. Select an action.

The following actions are available
depending on the state of your project:

| Project state    | Actions available |
|----------|-------------------------|
| Active   | **Edit**, **Archive**, **Transfer**, **Leave project**, **Delete** |
| Archived | **Unarchive**, **Leave project**, **Delete** |
| Pending deletion | **Restore**, **Leave project**, **Delete immediately** |

## Add a compliance framework to a project

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can add compliance frameworks to projects in a group that has a [compliance framework](../compliance/compliance_frameworks/_index.md).

## Manage project access through LDAP groups

You can [use LDAP to manage group membership](../group/access_and_permissions.md#manage-group-memberships-with-ldap).

You cannot use LDAP groups to manage project access, but you can use the following workaround.

Prerequisites:

- You must [integrate LDAP with GitLab](../../administration/auth/ldap/_index.md).
- You must be an administrator.

1. [Create a group](../group/_index.md#create-a-group) to track membership of your project.
1. [Set up LDAP synchronization](../../administration/auth/ldap/ldap_synchronization.md) for that group.
1. To use LDAP groups to manage access to a project,
   [add the LDAP-synchronized group as a member](../group/manage.md) to the project.

## Project aliases

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab repositories are usually accessed with a namespace and a project name. When migrating
frequently accessed repositories to GitLab, however, you can use project aliases to access those
repositories with the original name. Accessing repositories through a project alias reduces the risk
associated with migrating such repositories.

This feature is only available on Git over SSH. Also, only GitLab administrators can create project
aliases, and they can only do so through the API. For more information, see the
[Project Aliases API documentation](../../api/project_aliases.md).

After an administrator creates an alias for a project, you can use the alias to clone the
repository. For example, if an administrator creates the alias `gitlab` for the project
`https://gitlab.com/gitlab-org/gitlab`, you can clone the project with
`git clone git@gitlab.com:gitlab.git` instead of `git clone git@gitlab.com:gitlab-org/gitlab.git`.

## Related topics

- [Import a project](import/_index.md).
- [Connect an external repository to GitLab CI/CD](../../ci/ci_cd_for_external_repos/_index.md).
- [Fork a project](repository/forking_workflow.md#create-a-fork).
- Adjust [project visibility](../public_access.md#change-project-visibility) and [permissions](settings/_index.md#configure-project-features-and-permissions).
- [Rules for project and group names](../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)
