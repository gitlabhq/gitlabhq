---
stage: Data Stores
group: Tenant Scale
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Manage projects **(FREE ALL)**

Most work in GitLab is done in a [project](../../user/project/index.md). Files and
code are saved in projects, and most features are in the scope of projects.

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

## Edit project name and description

Use the project general settings to edit your project details.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. In the **Project name** text box, enter your project name. See the [limitations on project names](../../user/reserved_names.md).
1. In the **Project description** text box, enter your project description. The description is limited to 500 characters.
1. Under **Project avatar**, to change your project avatar, select **Choose file**.

## Star a project

You can add a star to projects you use frequently to make them easier to find.

To add a star to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper-right corner of the page, select **Star**.

## Delete a project

> - Default deletion behavior for projects changed to [delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.
> - Default deletion behavior for projects changed to [immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.
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

You can also [delete projects using the Rails console](#delete-a-project-using-console).

### Delayed project deletion **(PREMIUM ALL)**

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
[find projects that are pending deletion](#find-projects-that-are-pending-deletion).

### Delete a project immediately

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/191367) in GitLab 14.1.
> - Option to delete projects immediately from the Admin Area and as a group setting removed [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37014) in GitLab 13.3 for Administrators.
> - [Tab renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/347468) from **Deleted projects** in GitLab 14.6.
> - [Available to all users](https://gitlab.com/gitlab-org/gitlab/-/issues/346976) in GitLab 14.8 [with a flag](../../administration/feature_flags.md) named `project_owners_list_project_pending_deletion`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/351556) in GitLab 14.9. [Feature flag `project_owners_list_project_pending_deletion`](https://gitlab.com/gitlab-org/gitlab/-/issues/351556) removed.

To view a list of all projects that are pending deletion:

1. On the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. Based on your GitLab version:
   - GitLab 14.6 and later: select the **Pending deletion** tab.
   - GitLab 14.5 and earlier: select the **Deleted projects** tab.

Each project in the list shows:

- The time the project was marked for deletion.
- The time the project is scheduled for final deletion.
- A **Restore** link to stop the project being eventually deleted.

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

## Access the project overview page by using the project ID

> Project ID [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/431539) to the Actions menu in GitLab 16.7.

To access a project by using the project ID instead of its name,
go to `https://gitlab.example.com/projects/<id>`.

To copy the project ID:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** (**{ellipsis_v})**.
1. Select **Copy project ID**.

For example, if in your personal namespace `alex` you have a project `my-project` with the ID `123456`, you can access the project
either at `https://gitlab.example.com/alex/my-project` or `https://gitlab.example.com/projects/123456`.

You might also need the project ID if you want to interact with it using the [GitLab API](../../api/index.md).

## Who can view the Project overview page

When you select a project, the **Project overview** page shows the project contents.

For public projects, and members of internal and private projects
with [permissions to view the project's code](../permissions.md#project-members-permissions),
the project landing page shows:

- A [`README` or index file](repository/index.md#readme-and-index-files).
- A list of directories in the project's repository.

For users without permission to view the project's code, the landing page shows:

- The wiki homepage.
- The list of issues in the project.

## Leave a project

> The button to leave a project [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/431539) to the Actions menu in GitLab 16.7.

When you leave a project:

- You are no longer a project member and cannot contribute.
- All the issues and merge requests that were assigned
  to you are unassigned.

Prerequisites:

- You can leave a project this way only when a project is part of a group under a [group namespace](../namespace/index.md).
- You must be a [direct member](members/index.md#membership-types) of the project.

To leave a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the project overview page, in the upper-right corner, select **Actions** (**{ellipsis_v})**.
1. Select **Leave project**, then **Leave project** again..

## Add a compliance framework to a project **(PREMIUM)**

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

## Troubleshooting

When working with projects, you might encounter the following issues, or require alternate methods to complete specific tasks.

### `An error occurred while fetching commit data`

When you visit a project, the message `An error occurred while fetching commit data` might be displayed
if you use an ad blocker in your browser. The solution is to disable your ad blocker
for the GitLab instance you are trying to access.

### Find projects using an SQL query

While in [a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), you can find and store an array of projects based on a SQL query:

```ruby
# Finds projects that end with '%ject'
projects = Project.find_by_sql("SELECT * FROM projects WHERE name LIKE '%ject'")
=> [#<Project id:12 root/my-first-project>>, #<Project id:13 root/my-second-project>>]
```

### Clear a project's or repository's cache

If a project or repository has been updated but the state is not reflected in the UI, you may need to clear the project's or repository's cache.
You can do so through [a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session) and one of the following:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
## Clear project cache
ProjectCacheWorker.perform_async(project.id)

## Clear repository .exists? cache
project.repository.expire_exists_cache
```

### Find projects that are pending deletion

If you need to find all projects marked for deletion but that have not yet been deleted,
[start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session) and run the following:

```ruby
projects = Project.where(pending_delete: true)
projects.each do |p|
  puts "Project ID: #{p.id}"
  puts "Project name: #{p.name}"
  puts "Repository path: #{p.repository.full_path}"
end
```

### Delete a project using console

If a project cannot be deleted, you can attempt to delete it through [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
project = Project.find_by_full_path('<project_path>')
user = User.find_by_username('<username>')
ProjectDestroyWorker.new.perform(project.id, user.id, {})
```

If this fails, display why it doesn't work with:

```ruby
project = Project.find_by_full_path('<project_path>')
project.delete_error
```

### Toggle a feature for all projects within a group

While toggling a feature in a project can be done through the [projects API](../../api/projects.md),
you may need to do this for a large number of projects.

To toggle a specific feature, you can [start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session)
and run the following function:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
projects = Group.find_by_name('_group_name').projects
projects.each do |p|
  ## replace <feature-name> with the appropriate feature name in all instances
  state = p.<feature-name>

  if state != 0
    puts "#{p.name} has <feature-name> already enabled. Skipping..."
  else
    puts "#{p.name} didn't have <feature-name> enabled. Enabling..."
    p.project_feature.update!(<feature-name>: ProjectFeature::PRIVATE)
  end
end
```

To find features that can be toggled, run `pp p.project_feature`.
Available permission levels are listed in
[concerns/featurable.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/app/models/concerns/featurable.rb).

## Related topics

- [Import a project](../../user/project/import/index.md).
- [Connect an external repository to GitLab CI/CD](../../ci/ci_cd_for_external_repos/index.md).
- [Fork a project](repository/forking_workflow.md#create-a-fork).
- Adjust [project visibility](../../user/public_access.md#change-project-visibility) and [permissions](settings/project_features_permissions.md#configure-project-features-and-permissions).
- [Limitations on project and group names](../../user/reserved_names.md#limitations-on-project-and-group-names)
