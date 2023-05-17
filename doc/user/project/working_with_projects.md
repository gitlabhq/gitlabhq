---
stage: Data Stores
group: Tenant Scale
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Manage projects **(FREE)**

Most work in GitLab is done in a [project](../../user/project/index.md). Files and
code are saved in projects, and most features are in the scope of projects.

## View projects

To view all your projects, on the top bar, select **Main menu > Projects > View all projects**.

To browse all public projects, select **Main menu > Explore > Projects**.

### Who can view the Projects page

When you select a project, the project landing page shows the project contents.

For public projects, and members of internal and private projects
with [permissions to view the project's code](../permissions.md#project-members-permissions),
the project landing page shows:

- A [`README` or index file](repository/index.md#readme-and-index-files).
- A list of directories in the project's repository.

For users without permission to view the project's code, the landing page shows:

- The wiki homepage.
- The list of issues in the project.

### Access a project page with the project ID

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53671) in GitLab 11.8.

To access a project from the GitLab UI using the project ID,
visit the `/projects/:id` URL in your browser or other tool accessing the project.

## Explore topics

To explore project topics:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. Select the **Explore topics** tab.
1. To view projects associated with a topic, select a topic.

The **Explore topics** tab shows a list of topics sorted by the number of associated projects.

You can assign topics to a project on the [Project Settings page](settings/index.md#assign-topics-to-a-project).

If you're an instance administrator, you can administer all project topics from the
[Admin Area's Topics page](../admin_area/index.md#administering-topics).

## Star a project

You can add a star to projects you use frequently to make them easier to find.

To add a star to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. In the upper-right corner of the page, select **Star**.

## View starred projects

1. On the top bar, select **Main menu > Projects > View all projects**.
1. Select the **Starred projects** tab.
1. GitLab displays information about your starred projects, including:

   - Project description, including name, description, and icon.
   - Number of times this project has been starred.
   - Number of times this project has been forked.
   - Number of open merge requests.
   - Number of open issues.

## View personal projects

Personal projects are projects created under your personal namespace.

For example, if you create an account with the username `alex`, and create a project
called `my-project` under your username, the project is created at `https://gitlab.example.com/alex/my-project`.

To view your personal projects:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. In the **Yours** tab, select **Personal**.

## Delete a project

After you delete a project, projects in personal namespaces are deleted immediately. To delay deletion of projects in a group
you can [enable delayed project removal](../group/manage.md#enable-delayed-project-deletion).

To delete a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. Select **Settings > General**.
1. Expand the **Advanced** section.
1. Scroll down to the **Delete project** section.
1. Select **Delete project**.
1. Confirm this action by completing the field.

## View projects pending deletion **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37014) in GitLab 13.3 for Administrators.
> - [Tab renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/347468) from **Deleted projects** in GitLab 14.6.
> - [Available to all users](https://gitlab.com/gitlab-org/gitlab/-/issues/346976) in GitLab 14.8 [with a flag](../../administration/feature_flags.md) named `project_owners_list_project_pending_deletion`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/351556) in GitLab 14.9. [Feature flag `project_owners_list_project_pending_deletion`](https://gitlab.com/gitlab-org/gitlab/-/issues/351556) removed.

When delayed project deletion is [enabled for a group](../group/manage.md#enable-delayed-project-deletion),
projects within that group are not deleted immediately, but only after a delay.

To view a list of all projects that are pending deletion:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. Based on your GitLab version:
   - GitLab 14.6 and later: select the **Pending deletion** tab.
   - GitLab 14.5 and earlier: select the **Deleted projects** tab.

Each project in the list shows:

- The time the project was marked for deletion.
- The time the project is scheduled for final deletion.
- A **Restore** link to stop the project being eventually deleted.

## View project activity

To view the activity of a project:

1. On the top bar, select **Main menu > Projects** and find your project..
1. On the left sidebar, select **Project information > Activity**.
1. Select a tab to view the type of project activity.

## Search in projects

You can search through your projects.

1. On the top bar, select **Main menu**.
1. In **Search your projects**, type the project name.

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

1. On the top bar, select **Main menu > Projects > View all projects**.
1. From the **Language** dropdown list, select the language you want to filter projects by.

A list of projects that use the selected language is displayed.

## Change the visibility of individual features in a project

You can change the visibility of individual features in a project.

Prerequisite:

- You must have the Owner role for the project.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Use the toggle by each feature you want to turn on or off, or change access for.
1. Select **Save changes**.

## Leave a project

When you leave a project:

- You are no longer a project member and cannot contribute.
- All the issues and merge requests that were assigned
  to you are unassigned.

To leave a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. Select **Leave project**. The **Leave project** option only displays
on the project dashboard when a project is part of a group under a
[group namespace](../namespace/index.md).

## Use a project as a Go package

Prerequisites:

- Contact your administrator to enable the [GitLab Go Proxy](../packages/go_proxy/index.md).
- To use a private project in a subgroup as a Go package, you must [authenticate Go requests](#authenticate-go-requests-to-private-projects). Go requests that are not authenticated cause
`go get` to fail. You don't need to authenticate Go requests for projects that are not in subgroups.

To use a project as a Go package, use the `go get` and `godoc.org` discovery requests. You can use the meta tags:

- [`go-import`](https://pkg.go.dev/cmd/go#hdr-Remote_import_paths)
- [`go-source`](https://github.com/golang/gddo/wiki/Source-Code-Links)

### Authenticate Go requests to private projects

Prerequisites:

- Your GitLab instance must be accessible with HTTPS.
- You must have a [personal access token](../profile/personal_access_tokens.md) with `read_api` scope.

To authenticate Go requests, create a [`.netrc`](https://everything.curl.dev/usingcurl/netrc) file with the following information:

```plaintext
machine gitlab.example.com
login <gitlab_user_name>
password <personal_access_token>
```

On Windows, Go reads `~/_netrc` instead of `~/.netrc`.

The `go` command does not transmit credentials over insecure connections. It authenticates
HTTPS requests made by Go, but does not authenticate requests made
through Git.

### Authenticate Git requests

If Go cannot fetch a module from a proxy, it uses Git. Git uses a `.netrc` file to authenticate requests, but you can
configure other authentication methods.

Configure Git to either:

- Embed credentials in the request URL:

  ```shell
  git config --global url."https://${user}:${personal_access_token}@gitlab.example.com".insteadOf "https://gitlab.example.com"
  ```

- Use SSH instead of HTTPS:

  ```shell
  git config --global url."git@gitlab.example.com:".insteadOf "https://gitlab.example.com/"
  ```

### Disable Go module fetching for private projects

To [fetch modules or packages](../../development/go_guide/dependencies.md#fetching), Go uses
the [environment variables](../../development/go_guide/dependencies.md#proxies):

- `GOPRIVATE`
- `GONOPROXY`
- `GONOSUMDB`

To disable fetching:

1. Disable `GOPRIVATE`:
   - To disable queries for one project, disable `GOPRIVATE=gitlab.example.com/my/private/project`.
   - To disable queries for all projects on GitLab.com, disable `GOPRIVATE=gitlab.example.com`.
1. Disable proxy queries in `GONOPROXY`.
1. Disable checksum queries in `GONOSUMDB`.

- If the module name or its prefix is in `GOPRIVATE` or `GONOPROXY`, Go does not query module
  proxies.
- If the module name or its prefix is in `GONOPRIVATE` or `GONOSUMDB`, Go does not query
  Checksum databases.

### Fetch Go modules from Geo secondary sites

Use [Geo](../../administration/geo/index.md) to access Git repositories that contain Go modules
on secondary Geo servers.

You can use SSH or HTTP to access the Geo secondary server.

#### Use SSH to access the Geo secondary server

To access the Geo secondary server with SSH:

1. Reconfigure Git on the client to send traffic for the primary to the secondary:

   ```shell
   git config --global url."git@gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   git config --global url."git@gitlab-secondary.example.com".insteadOf "http://gitlab.example.com"
   ```

   - For `gitlab.example.com`, use the primary site domain name.
   - For `gitlab-secondary.example.com`, use the secondary site domain name.

1. Ensure the client is set up for SSH access to GitLab repositories. You can test this on the primary,
   and GitLab replicates the public key to the secondary.

The `go get` request generates HTTP traffic to the primary Geo server. When the module
download starts, the `insteadOf` configuration sends the traffic to the secondary Geo server.

#### Use HTTP to access the Geo secondary

You must use persistent access tokens that replicate to the secondary server. You cannot use
CI/CD job tokens to fetch Go modules with HTTP.

To access the Geo secondary server with HTTP:

1. Add a Git `insteadOf` redirect on the client:

   ```shell
   git config --global url."https://gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   ```

   - For `gitlab.example.com`, use the primary site domain name.
   - For `gitlab-secondary.example.com`, use the secondary site domain name.

1. Generate a [personal access token](../profile/personal_access_tokens.md) and
   add the credentials in the client's `~/.netrc` file:

   ```shell
   machine gitlab.example.com login USERNAME password TOKEN
   machine gitlab-secondary.example.com login USERNAME password TOKEN
   ```

The `go get` request generates HTTP traffic to the primary Geo server. When the module
download starts, the `insteadOf` configuration sends the traffic to the secondary Geo server.

## Related topics

- [Import a project](../../user/project/import/index.md).
- [Connect an external repository to GitLab CI/CD](../../ci/ci_cd_for_external_repos/index.md).
- [Fork a project](repository/forking_workflow.md#create-a-fork).
- [Adjust project visibility and access levels](settings/index.md#configure-project-visibility-features-and-permissions).
- [Limitations on project and group names](../../user/reserved_names.md#limitations-on-project-and-group-names)

## Troubleshooting

When working with projects, you might encounter the following issues, or require alternate methods to complete specific tasks.

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
