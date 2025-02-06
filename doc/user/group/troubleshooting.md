---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting groups
---

## Validation errors on namespaces and groups

Performs the following checks when creating or updating namespaces or groups:

- Namespaces must not have parents.
- Group parents must be groups and not namespaces.

In the unlikely event that you see these errors in your GitLab installation,
[contact Support](https://about.gitlab.com/support/) so that we can improve this validation.

## Find groups using an SQL query

To find and store an array of groups based on an SQL query in the [rails console](../../administration/operations/rails_console.md):

```ruby
# Finds groups and subgroups that end with '%oup'
Group.find_by_sql("SELECT * FROM namespaces WHERE name LIKE '%oup'")
=> [#<Group id:3 @test-group>, #<Group id:4 @template-group/template-subgroup>]
```

## Transfer subgroup to another location using Rails console

If transferring a group doesn't work through the UI or API, you may want to attempt the transfer in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
user = User.find_by_username('<username>')
group = Group.find_by_name("<group_name>")
## Set parent_group = nil to make the subgroup a top-level group
parent_group = Group.find_by(id: "<group_id>")
service = ::Groups::TransferService.new(group, user)
service.execute(parent_group)
```

## Find groups pending deletion using Rails console

If you need to find all the groups that are pending deletion, you can use the following command in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
Group.all.each do |g|
 if g.marked_for_deletion?
    puts "Group ID: #{g.id}"
    puts "Group name: #{g.name}"
    puts "Group path: #{g.full_path}"
 end
end
```

## Delete a group using Rails console

At times, a group deletion may get stuck. If needed, in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can attempt to delete a group using the following command:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
GroupDestroyWorker.new.perform(group_id, user_id)
```

## Find a user's maximum permissions for a group or project

Administrators can find a user's maximum permissions for a group or project.

1. Start a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the following commands:

   ```ruby
   user = User.find_by_username 'username'
   project = Project.find_by_full_path 'group/project'
   user.max_member_access_for_project project.id
   ```

   ```ruby
   user = User.find_by_username 'username'
   group = Group.find_by_full_path 'group'
   user.max_member_access_for_group group.id
   ```

## Unable to remove billable members with badge `Project Invite/Group Invite`

The following error typically occurs when the user belongs to an external group that has been shared with your [projects](../project/members/sharing_projects_groups.md) or [groups](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group):

<!-- vale gitlab_base.LatinTerms = NO -->
`Members who were invited via a group invitation cannot be removed. You can either remove the entire group, or ask an Owner of the invited group to remove the member.`
<!-- vale gitlab_base.LatinTerms = YES -->

To remove the user as a billable member, follow one of these options:

- Remove the invited group membership from your project or group members page.
- Recommended. Remove the user directly from the invited group, if you have access to the group.

## Missing or insufficient permission, delete button disabled

This error typically occurs when a user attempts to remove the `container_registry` images from the archived projects during group transfer. To solve this error:

1. Unarchive the project.
1. Delete the `container_registry` images.
1. Archive the project.
