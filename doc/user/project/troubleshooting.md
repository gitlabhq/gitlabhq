---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting projects
---

When working with projects, you might encounter the following issues, or require alternate methods to complete specific tasks.

## `An error occurred while fetching commit data`

When you visit a project, the message `An error occurred while fetching commit data` might be displayed
if you use an ad blocker in your browser. The solution is to disable your ad blocker
for the GitLab instance you are trying to access.

## Find projects using an SQL query

While in [a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), you can find and store an array of projects based on a SQL query:

```ruby
# Finds projects that end with '%ject'
projects = Project.find_by_sql("SELECT * FROM projects WHERE name LIKE '%ject'")
=> [#<Project id:12 root/my-first-project>>, #<Project id:13 root/my-second-project>>]
```

## Clear a project's or repository's cache

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

## Find projects that are pending deletion

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

## Delete a project using console

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

## Toggle a feature for all projects within a group

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
