---
stage: Tenant Scale
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

You might also need the project ID if you want to interact with the project using the [GitLab API](../../api/_index.md).

To find the project ID:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}).
1. Select **Copy project ID**.

## View all projects for the instance

To view all projects for the GitLab instance:

1. On the left sidebar, select **Search or go to**.
1. Select **Explore**.

On the left sidebar, **Projects** is selected.
A list of all projects for the instance is displayed.

If you are not authenticated, the list shows public projects only.

## View projects you have contributed to

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13066) in GitLab 17.9 [with a flag](../../administration/feature_flags.md) named `your_work_projects_vue`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

The **Contributed** tab displays projects where you have:

- Created issues, merge requests, or epics
- Commented on issues, merge requests, or epics
- Closed issues, merge requests, or epics
- Pushed commits
- Approved merge requests
- Merged merge requests

To view projects you have contributed to:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Contributed** tab.

## View projects you are a member of

{{< history >}}

- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) tab label from "Yours" to "Member" in GitLab 17.9 [with a flag](../../administration/feature_flags.md) named `your_work_projects_vue`. Disabled by default.
- [Changed tab label generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.

{{< /history >}}

To view projects you are a member of:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Yours** tab.

{{< alert type="note" >}}

This tab appears as **Member** when the `your_work_projects_vue` feature flag is enabled.

{{< /alert >}}

## View personal projects

Personal projects are projects created under your personal namespace.

For example, if you create an account with the username `alex`, and create a project
called `my-project` under your username, the project is created at `https://gitlab.example.com/alex/my-project`.

To view your personal projects:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Personal** tab.

Or

1. On the left sidebar, select your avatar and then your username.
1. On the left sidebar, select **Personal projects**.

## View starred projects

To view projects you have [starred](#star-a-project):

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Starred** tab.

Or

1. On the left sidebar, select your avatar and then your username.
1. On the left sidebar, select **Starred projects**.

## Edit project name and description

Use the project general settings to edit your project details.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. In the **Project name** text box, enter your project name. See the [limitations on project names](../reserved_names.md).
1. Optional. In the **Project description** text box, enter your project description. The description is limited to 2,000 characters.
Components published in the CI/CD catalog require a project description.
1. Select **Save changes**.

## Add a project avatar

Add a project avatar to help visually identify your project. If you do not add an avatar, GitLab displays the first letter of your project name as the default project avatar.

To add a project avatar, use one of the following methods:

- [Add a logo](#add-a-logo-to-your-repository) to your repository.
- [Upload an avatar](#upload-an-avatar-in-project-settings) in your project settings.

### Add a logo to your repository

If you haven't uploaded an avatar to your project settings, GitLab looks for a file named `logo` in your repository to use as the default project avatar.

Prerequisites:

- You must have at least the Maintainer role for the project.
- Your file must be 200 KB or smaller. The ideal image size is 192 x 192 pixels.
- The file must be named `logo` with the extension `.png`, `.jpg`, or `.gif`. For example, `logo.gif`.

To add a logo file to use as your project avatar:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the root of your project repository, upload the logo file.

### Upload an avatar in project settings

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

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. In the **Project avatar** section, select **Choose file**.
1. Select your avatar file.
1. Select **Save changes**.

## Star a project

You can star projects you use frequently to make them easier to find.

To star a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper-right corner of the page, select **Star**.

## Delete a project

{{< history >}}

- Default behavior [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) to delayed project deletion for Premium and Ultimate tiers on [GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in 16.0.
- Option to delete projects immediately as a group setting removed [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.
- Default behavior changed to delayed project deletion for [GitLab Free](https://gitlab.com/groups/gitlab-org/-/epics/17208) and [personal projects](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in 18.0.
- Option to delete projects immediately [moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.

{{< /history >}}

You can schedule a project for deletion.
By default, when you delete a project for the first time, it enters a pending deletion state.
Delete a project again to remove it immediately.

On GitLab.com, after a project is deleted, its data is retained for seven days.

Prerequisites:

- You must have the Owner role for a project.
- Owners must be [allowed to delete projects](../../administration/settings/visibility_and_access_controls.md#restrict-project-deletion-to-administrators).

To delete a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Delete project** section, select **Delete project**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.
1. Optional. To delete the project immediately, repeat these steps.

You can also [delete projects using the Rails console](troubleshooting.md#delete-a-project-using-console).

If the user who scheduled the project deletion loses access to the project before the deletion occurs
(for example, by leaving the project, having their role downgraded, or being banned from the project),
the deletion job restores the project. However, if the user regains access before the deletion job runs,
the job removes the project permanently.

### View projects pending deletion

{{< history >}}

- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) tab label from "Pending deletion" to "Inactive" in GitLab 17.9 [with a flag](../../administration/feature_flags.md) named `your_work_projects_vue`. Disabled by default.
- [Changed tab label generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in GitLab 18.0.

{{< /history >}}

To view a list of all projects that are pending deletion:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Inactive** tab.

Each project in the list shows:

- A badge indicating that the project has been marked for deletion.
- The time the project was marked for deletion.
- The time the project is scheduled for final deletion.
- A **Restore** action to stop the project being eventually deleted.

### Restore a project

{{< history >}}

- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/issues/536244) in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the project.

To restore a project pending deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Restore project** section, select **Restore project**.

## Archive a project

{{< history >}}

- Pages removal [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343109) in GitLab 17.5.

{{< /history >}}

{{< alert type="note" >}}

When a project is archived, its fork relationship is removed and any open merge requests from forks
targeting this project are automatically closed.

{{< /alert >}}

When you archive a project, some features become read-only.
These features are still accessible, but not writable.

- Repository
- Packages
- Issues
- Merge requests
- Feature flags
- Pull mirroring
- All other project features

Active pipeline schedules of archived projects don't become read-only.

If the project has deployed Pages, they are removed along with any custom domains,
and the Pages link is no longer accessible.

Archived projects are:

- Labeled with an `archived` badge on the project page.
- Listed in the **Inactive** tab on the group page, **Your work** page, and **Explore** page.
- Read-only.

Prerequisites:

- [Deactivate](../../ci/pipelines/schedules.md#edit-a-pipeline-schedule) or delete any active pipeline schedules for the project.
<!-- LP: Remove this prerequisite after the issue is resolved (when a project is archived, active pipeline schedules continue to run). -->

To archive a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Archive project** section, select **Archive project**.
1. To confirm, select **OK**.

## Unarchive a project

When you unarchive a project, the read-only restriction is removed,
and the project becomes available in project lists.

Prerequisites:

- You must be an administrator or have the Owner role for the project.

1. Find the archived project.
   1. On the left sidebar, select **Search or go to**.
   1. Select **View all my projects**.
   1. Select **Explore projects**.
   1. In the **Sort projects** dropdown list, select **Show archived projects**.
   1. In the **Filter by name** field, enter the project name.
   1. Select the project link.
1. On the left sidebar, select **Settings > General**.
1. Under **Advanced**, select **Expand**.
1. In the **Unarchive project** section, select **Unarchive project**.
1. To confirm, select **OK**.

The deployed Pages are not restored and you must rerun the pipeline.

When a project is unarchived, its pull mirroring process will automatically resume.

## View project activity

To view the activity of a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Activity**.
1. Optional. To filter activity by contribution type, select a tab:

   - **All**: All contributions by project members.
   - **Push events**: Push events in the project.
   - **Merge events**: Accepted merge requests in the project.
   - **Issue events**: Issues opened and closed in the project.
   - **Comments**: Comments posted by project members.
   - **Designs**: Designs added, updated, and removed in the project.
   - **Team**: Members who joined and left the project.

### Event time period limit

GitLab removes project activity events older than 3 years from the events table for performance reasons.

## Search in projects

To search through your projects, on the left sidebar, select **Search or go to**.
GitLab filters as you type.

You can also look for the projects you [starred](#star-a-project) (**Starred projects**).

You can **Explore** all public and internal projects available in GitLab.com, from which you can filter by visibility,
through **Trending**, best rated with **Most stars**, or **All** of them.

You can sort projects by:

- Name
- Created date
- Updated date
- Stars

### Filter projects by language

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385465) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) named `project_language_search`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110956) in GitLab 15.9. Feature flag `project_language_search` removed.

{{< /history >}}

You can filter projects by the programming language they use. To do this:

1. On the left sidebar, select **Search or go to**.
1. Select either:
   - **View all your projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. Above the list of projects, select **Search or filter results**.
1. From the **Language** dropdown list, select the language you want to filter projects by.

A list of projects that use the selected language is displayed.

### View only projects you own

To view only the projects you are the owner of:

1. On the left sidebar, select **Search or go to**.
1. Select either:
   - **View all your projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. Above the list of projects, select **Search or filter results**.
1. From the **Role** dropdown list, select **Owner**.

## Rename a repository

A project's repository name defines its URL.

Prerequisites:

- You must be an administrator or have the Maintainer or Owner role for the project.

{{< alert type="note" >}}

When you change the repository path, users may experience issues if they push to, or pull from, the old URL.
For more information on redirect duration and its side-effects, see
[redirects when renaming repositories](repository/_index.md#repository-path-changes).

{{< /alert >}}

To rename a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Change path** text box, edit the path.
1. Select **Change path**.

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

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}).
1. Select **Leave project**, then **Leave project** again.

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
