---
stage: Data Stores
group: Tenant Scale
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Manage projects

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Most work in GitLab is done in a [project](../../user/project/index.md). Files and
code are saved in projects, and most features are in the scope of projects.

## Project overview

> - Project creation date [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19452) in GitLab 16.10.

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

- A [`README` or index file](repository/files/index.md#readme-and-index-files).
- A list of directories in the project's repository.

For users without permission to view the project's code, the overview page shows:

- The wiki homepage.
- The list of issues in the project.

### Access a project by using the project ID

> - Project ID [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/431539) to the Actions menu in GitLab 16.7.

You can access a project by using its ID instead of its name at `https://gitlab.example.com/projects/<id>`.
For example, if in your personal namespace `alex` you have a project `my-project` with the ID `123456`,
you can access the project either at `https://gitlab.example.com/alex/my-project` or `https://gitlab.example.com/projects/123456`.

You might also need the project ID if you want to interact with the project using the [GitLab API](../../api/index.md).

To copy the project ID:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** (**{ellipsis_v}**).
1. Select **Copy project ID**.

## View all projects for the instance

To view all projects for the GitLab instance:

1. On the left sidebar, select **Search or go to**.
1. Select **Explore**.

On the left sidebar, **Projects** is selected. On the right, the list shows
all projects for the instance.

If you are not authenticated, then the list shows public projects only.

## View projects you are a member of

To view projects you are a member of:

1. On the left sidebar, select **Search or go to**.
1. Select **Your work**.

On the left sidebar, **Projects** is selected. On the list, on the **Yours** tab,
all the projects you are a member of are displayed.

## View personal projects

Personal projects are projects created under your personal namespace.

For example, if you create an account with the username `alex`, and create a project
called `my-project` under your username, the project is created at `https://gitlab.example.com/alex/my-project`.

To view your personal projects:

1. On the left sidebar, select your avatar and then your username.
1. On the left sidebar, select **Personal projects**.

## View starred projects

To view projects you have [starred](#star-a-project):

1. On the left sidebar, select your avatar and then your username.
1. On the left sidebar, select **Starred projects**.

## Edit project name, description, and avatar

Use the project general settings to edit your project details.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. In the **Project name** text box, enter your project name. See the [limitations on project names](../../user/reserved_names.md).
1. Optional. In the **Project description** text box, enter your project description. The description is limited to 2,000 characters.
1. Optional. Under **Project avatar**, to change your project avatar, select **Choose file**. The ideal image size is 192 x 192 pixels, and the maximum file size allowed is 200 KB.
1. Select **Save changes**.

## Star a project

You can add a star to projects you use frequently to make them easier to find.

To add a star to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper-right corner of the page, select **Star**.

## Delete a project

> - Default deletion behavior for projects on the Premium and Ultimate tier changed to [delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 16.0.
> - Default deletion behavior changed to delayed deletion on the Premium and Ultimate tier [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

You can mark a project to be deleted.
After you delete a project:

- Projects in personal namespaces are deleted immediately.
- Projects in groups are deleted after a retention period.

Prerequisites:

- You must have the Owner role for a project.

To delete a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Delete this project** section, select **Delete project**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.

This action deletes the project and all associated resources (such as issues and merge requests).

You can also [delete projects using the Rails console](troubleshooting.md#delete-a-project-using-console).

### Delayed project deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89466) in GitLab 15.1.
> - [Disabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95495) in GitLab 15.3.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

Prerequisites:

- You must have the Owner role for the project.

Projects in a group (not a personal namespace) can be deleted after a delay period.

On self-managed instances, group administrators can define a deletion delay period of between 1 and 90 days.
On SaaS, there is a non-adjustable default retention period of seven days.

You can [view projects that are pending deletion](#view-projects-pending-deletion),
and use the Rails console to
[find projects that are pending deletion](troubleshooting.md#find-projects-that-are-pending-deletion).

### Delete a project immediately

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Option to delete projects immediately from the Admin area and as a group setting removed [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

Prerequisites:

- You must have the Owner role for the project.
- The project must be [marked for deletion](#delete-a-project).

If you don't want to wait for delayed deletion, you can delete a project immediately. To do this, perform the steps for [deleting a projects](#delete-a-project) again.

In the first cycle of deleting a project, the project is moved to the delayed deletion queue and automatically deleted after the retention period has passed.
If during this delayed deletion time you run a second deletion cycle, the project is deleted immediately.

To immediately delete a project marked for deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Delete this project** section, select **Delete project**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.

### View projects pending deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To view a list of all projects that are pending deletion:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Select the **Pending deletion** tab.

Each project in the list shows:

- The time the project was marked for deletion.
- The time the project is scheduled for final deletion.
- A **Restore** link to stop the project being eventually deleted.

## Restore a project

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Prerequisites:

- You must have the Owner role for the project.
- The project must be marked for deletion.

To restore a project marked for deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the Restore project section, select **Restore project**.

## Archive a project

When you archive a project, some features become read-only.
These features are still accessible, but not writable.

- Repository
- Packages
- Issues
- Merge requests
- Feature flags
- All other project features

Active pipeline schedules of archived projects don't become read-only.

Archived projects are:

- Labeled with an `archived` badge on the project page.
- Listed on the group page in the **Inactive** tab.
- Hidden from project lists in **Your Work** and **Explore**.
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
- Owner

You can also choose to hide or show archived projects.

### Filter projects by language

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385465) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) named `project_language_search`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110956) in GitLab 15.9. Feature flag `project_language_search` removed.

You can filter projects by the programming language they use. To do this:

1. On the left sidebar, select **Search or go to**.
1. Select either:
   - **View all your projects**, to filter your projects.
   - **Explore**, to filter all projects you can access.
1. From the **Language** dropdown list, select the language you want to filter projects by.

A list of projects that use the selected language is displayed.

## Rename a repository

A project's repository name defines its URL and its place on the file disk
where GitLab is installed.

Prerequisites:

- You must be an administrator or have the Maintainer or Owner role for the project.

NOTE:
When you change the repository path, users may experience issues if they push to, or pull from, the old URL. For more information, see
[redirects when renaming repositories](../project/repository/index.md#what-happens-when-a-repository-path-changes).

To rename a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Change path** text box, edit the path.
1. Select **Change path**.

## Leave a project

> - The button to leave a project [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/431539) to the Actions menu in GitLab 16.7.

When you leave a project:

- You are no longer a project member and cannot contribute.
- All the issues and merge requests that were assigned
  to you are unassigned.

Prerequisites:

- You can leave a project this way only when a project is part of a group under a [group namespace](../namespace/index.md).
- You must be a [direct member](members/index.md#membership-types) of the project.

To leave a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** (**{ellipsis_v}**).
1. Select **Leave project**, then **Leave project** again.

## Add a compliance framework to a project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can add compliance frameworks to projects in a group that has a [compliance framework](../group/compliance_frameworks.md).

## Manage project access through LDAP groups

You can [use LDAP to manage group membership](../group/access_and_permissions.md#manage-group-memberships-via-ldap).

You cannot use LDAP groups to manage project access, but you can use the following workaround.

Prerequisites:

- You must [integrate LDAP with GitLab](../../administration/auth/ldap/index.md).
- You must be an administrator.

1. [Create a group](../group/index.md#create-a-group) to track membership of your project.
1. [Set up LDAP synchronization](../../administration/auth/ldap/ldap_synchronization.md) for that group.
1. To use LDAP groups to manage access to a project,
   [add the LDAP-synchronized group as a member](../group/manage.md) to the project.

## Project aliases

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

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

- [Import a project](../../user/project/import/index.md).
- [Connect an external repository to GitLab CI/CD](../../ci/ci_cd_for_external_repos/index.md).
- [Fork a project](repository/forking_workflow.md#create-a-fork).
- Adjust [project visibility](../../user/public_access.md#change-project-visibility) and [permissions](settings/index.md#configure-project-features-and-permissions).
- [Limitations on project and group names](../../user/reserved_names.md#limitations-on-usernames-project-and-group-names)
