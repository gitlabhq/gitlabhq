---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Rails Console Cheat Sheet **(FREE SELF)**

This is the GitLab Support Team's collection of information regarding the GitLab Rails
console, for use while troubleshooting. It is listed here for transparency,
and for users with experience with these tools. If you are currently
having an issue with GitLab, it is highly recommended that you first check
our guide on [our Rails console](../operations/rails_console.md),
and your [support options](https://about.gitlab.com/support/), before attempting to use
this information.

WARNING:
Some of these scripts could be damaging if not run correctly,
or under the right conditions. We highly recommend running them under the
guidance of a Support Engineer, or running them in a test environment with a
backup of the instance ready to be restored, just in case.

WARNING:
As GitLab changes, changes to the code are inevitable,
and so some scripts may not work as they once used to. These are not kept
up-to-date as these scripts/commands were added as they were found/needed. As
mentioned above, we recommend running these scripts under the supervision of a
Support Engineer, who can also verify that they continue to work as they
should and, if needed, update the script for the latest version of GitLab.

## Find specific methods for an object

```ruby
Array.methods.select { |m| m.to_s.include? "sing" }
Array.methods.grep(/sing/)
```

## Find method source

```ruby
instance_of_object.method(:foo).source_location

# Example for when we would call project.private?
project.method(:private?).source_location
```

## Attributes

View available attributes, formatted using pretty print (`pp`).

For example, determine what attributes contain users' names and email addresses:

```ruby
u = User.find_by_username('someuser')
pp u.attributes
```

Partial output:

```plaintext
{"id"=>1234,
 "email"=>"someuser@example.com",
 "sign_in_count"=>99,
 "name"=>"S User",
 "username"=>"someuser",
 "first_name"=>nil,
 "last_name"=>nil,
 "bot_type"=>nil}
```

Then make use of the attributes, [testing SMTP, for example](https://docs.gitlab.com/omnibus/settings/smtp.html#testing-the-smtp-configuration):

```ruby
e = u.email
n = u.name
Notify.test_email(e, "Test email for #{n}", 'Test email').deliver_now
#
Notify.test_email(u.email, "Test email for #{u.name}", 'Test email').deliver_now
```

## Limiting output

Adding a semicolon(`;`) and a follow-up statement at the end of a statement prevents the default implicit return output. This can be used if you are already explicitly printing details and potentially have a lot of return output:

```ruby
puts ActiveRecord::Base.descendants; :ok
Project.select(&:pages_deployed?).each {|p| puts p.pages_url }; true
```

## Get or store the result of last operation

Underscore(`_`) represents the implicit return of the previous statement. You can use this to quickly assign a variable from the output of the previous command:

```ruby
Project.last
# => #<Project id:2537 root/discard>>
project = _
# => #<Project id:2537 root/discard>>
project.id
# => 2537
```

## Open object in `irb`

Sometimes it is easier to go through a method if you are in the context of the object. You can shim into the namespace of `Object` to let you open `irb` in the context of any object:

```ruby
Object.define_method(:irb) { binding.irb }

project = Project.last
# => #<Project id:2537 root/discard>>
project.irb
# Notice new context
irb(#<Project>)> web_url
# => "https://gitlab-example/root/discard"
```

## Query the database using an ActiveRecord Model

```ruby
m = Model.where('attribute like ?', 'ex%')

# for example to query the projects
projects = Project.where('path like ?', 'Oumua%')
```

## View all keys in cache

```ruby
Rails.cache.instance_variable_get(:@data).keys
```

## Profile a page

```ruby
url = '<url/of/the/page>'

# Before 11.6.0
logger = Logger.new($stdout)
admin_token = User.find_by_username('<admin-username>').personal_access_tokens.first.token
app.get("#{url}/?private_token=#{admin_token}")

# From 11.6.0
admin = User.find_by_username('<admin-username>')
Gitlab::Profiler.with_user(admin) { app.get(url) }
```

## Using the GitLab profiler inside console (used as of 10.5)

```ruby
logger = Logger.new($stdout)
admin = User.find_by_username('<admin-username>')
Gitlab::Profiler.profile('<url/of/the/page>', logger: logger, user: admin)
```

## Time an operation

```ruby
# A single operation
Benchmark.measure { <operation> }

# A breakdown of multiple operations
Benchmark.bm do |x|
  x.report(:label1) { <operation_1> }
  x.report(:label2) { <operation_2> }
end
```

## Feature flags

### Show all feature flags that are enabled

```ruby
# Regular output
Feature.all

# Nice output
Feature.all.map {|f| [f.name, f.state]}
```

## Command Line

### Check the GitLab version fast

```shell
grep -m 1 gitlab /opt/gitlab/version-manifest.txt
```

### Debugging SSH

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <repository>
```

### Debugging over HTTPS

```shell
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git clone <repository>
```

## Projects

### Clear a project's cache

```ruby
ProjectCacheWorker.perform_async(project.id)
```

### Expire the .exists? cache

```ruby
project.repository.expire_exists_cache
```

### Make all projects private

```ruby
Project.update_all(visibility_level: 0)
```

### Find projects that are pending deletion

```ruby
#
# This section lists all the projects which are pending deletion
#
projects = Project.where(pending_delete: true)
projects.each do |p|
  puts "Project ID: #{p.id}"
  puts "Project name: #{p.name}"
  puts "Repository path: #{p.repository.full_path}"
end

#
# Assign a user (the root user does)
#
user = User.find_by_username('root')

#
# For each project listed repeat these two commands
#

# Find the project, update the xxx-changeme values from above
project = Project.find_by_full_path('group-changeme/project-changeme')

# Immediately delete the project
::Projects::DestroyService.new(project, user, {}).execute
```

### Destroy a project

```ruby
project = Project.find_by_full_path('<project_path>')
user = User.find_by_username('<username>')
ProjectDestroyWorker.perform_async(project.id, user.id, {})
# or ProjectDestroyWorker.new.perform(project.id, user.id, {})
# or Projects::DestroyService.new(project, user).execute
```

If this fails, display why it doesn't work with:

```ruby
project = Project.find_by_full_path('<project_path>')
project.delete_error
```

### Remove fork relationship manually

```ruby
p = Project.find_by_full_path('<project_path>')
u = User.find_by_username('<username>')
::Projects::UnlinkForkService.new(p, u).execute
```

### Make a project read-only (can only be done in the console)

```ruby
# Make a project read-only
project.repository_read_only = true; project.save

# OR
project.update!(repository_read_only: true)
```

### Transfer project from one namespace to another

```ruby
p = Project.find_by_full_path('<project_path>')

 # To set the owner of the project
 current_user= p.creator

# Namespace where you want this to be moved.
namespace = Namespace.find_by_full_path("<new_namespace>")

::Projects::TransferService.new(p, current_user).execute(namespace)
```

### Bulk update service integration password for _all_ projects

For example, change the Jira user's password for all projects that have the Jira
integration active:

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN services s ON p.id = s.project_id WHERE s.type = 'JiraService' AND s.active = true")

p.each do |project|
  project.jira_integration.update_attribute(:password, '<your-new-password>')
end
```

### Bulk update push rules for _all_ projects

For example, enable **Check whether the commit author is a GitLab user** and **Do not allow users to remove Git tags with `git push`** checkboxes, and create a filter for allowing commits from a specific email domain only:

``` ruby
Project.find_each do |p|
  pr = p.push_rule || PushRule.new(project: p)
  # Check whether the commit author is a GitLab user
  pr.member_check = true
  # Do not allow users to remove Git tags with `git push`
  pr.deny_delete_tag = true
  # Commit author's email
  pr.author_email_regex = '@domain\.com$'
  pr.save!
end
```

## Bulk update to change all the Jira integrations to Jira instance-level values

To change all Jira project to use the instance-level integration settings:

1. In a Rails console:

   ```ruby
   jira_integration_instance_id = Integrations::Jira.find_by(instance: true).id
   Integrations::Jira.where(active: true, instance: false, template: false, inherit_from_id: nil).find_each do |integration|
     integration.update_attribute(:inherit_from_id, jira_integration_instance_id)
   end
   ```

1. Modify and save again the instance-level integration from the UI to propagate the changes to all the group-level and project-level integrations.

### Bulk update to disable the Slack Notification service

To disable notifications for all projects that have Slack service enabled, do:

```ruby
# Grab all projects that have the Slack notifications enabled
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN services s ON p.id = s.project_id WHERE s.type = 'SlackService' AND s.active = true")

# Disable the service on each of the projects that were found.
p.each do |project|
  project.slack_service.update_attribute(:active, false)
end
```

### Incorrect repository statistics shown in the GUI

After [reducing a repository size with third-party tools](../../user/project/repository/reducing_the_repo_size_using_git.md)
the displayed size may still show old sizes or commit numbers. To force an update, do:

```ruby
p = Project.find_by_full_path('<namespace>/<project>')
pp p.statistics
p.statistics.refresh!
pp p.statistics
# compare with earlier values

# check the total artifact storage space separately
builds_with_artifacts = p.builds.with_downloadable_artifacts.all

artifact_storage = 0
builds_with_artifacts.find_each do |build|
  artifact_storage += build.artifacts_size
end

puts "#{artifact_storage} bytes"
```

### Identify deploy keys associated with blocked and non-member users

When the user who created a deploy key is blocked or removed from the project, the key
can no longer be used to push to protected branches in a private project (see [issue #329742](https://gitlab.com/gitlab-org/gitlab/-/issues/329742)).
The following script identifies unusable deploy keys:

```ruby
ghost_user_id = User.ghost.id

DeployKeysProject.with_write_access.find_each do |deploy_key_mapping|
  project = deploy_key_mapping.project
  deploy_key = deploy_key_mapping.deploy_key
  user = deploy_key.user

  access_checker = Gitlab::DeployKeyAccess.new(deploy_key, container: project)

  # can_push_for_ref? tests if deploy_key can push to default branch, which is likely to be protected
  can_push = access_checker.can_do_action?(:push_code)
  can_push_to_default = access_checker.can_push_for_ref?(project.repository.root_ref)

  next if access_checker.allowed? && can_push && can_push_to_default

  if user.nil? || user.id == ghost_user_id
    username = 'none'
    state = '-'
  else
    username = user.username
    user_state = user.state
  end

  puts "Deploy key: #{deploy_key.id}, Project: #{project.full_path}, Can push?: " + (can_push ? 'YES' : 'NO') +
       ", Can push to default branch #{project.repository.root_ref}?: " + (can_push_to_default ? 'YES' : 'NO') +
       ", User: #{username}, User state: #{user_state}"
end
```

### Find projects using an SQL query

Find and store an array of projects based on an SQL query:

```ruby
# Finds projects that end with '%ject'
projects = Project.find_by_sql("SELECT * FROM projects WHERE name LIKE '%ject'")
=> [#<Project id:12 root/my-first-project>>, #<Project id:13 root/my-second-project>>]
```

## Wikis

### Recreate

WARNING:
This is a destructive operation, the Wiki becomes empty.

A Projects Wiki can be recreated by this command:

```ruby
p = Project.find_by_full_path('<username-or-group>/<project-name>')  ### enter your projects path

GitlabShellWorker.perform_in(0, :remove_repository, p.repository_storage, p.wiki.disk_path)  ### deletes the wiki project from the filesystem

p.create_wiki  ### creates the wiki project on the filesystem
```

## Issue boards

### In case of issue boards not loading properly and it's getting time out. Call the Issue Rebalancing service to fix this

```ruby
p = Project.find_by_full_path('<username-or-group>/<project-name>')

Issues::RelativePositionRebalancingService.new(p.root_namespace.all_projects).execute
```

## Imports and exports

### Import a project

```ruby
# Find the project and get the error
p = Project.find_by_full_path('<username-or-group>/<project-name>')

p.import_error

# To finish the import on GitLab running version before 11.6
p.import_finish

# To finish the import on GitLab running version 11.6 or after
p.import_state.mark_as_failed("Failed manually through console.")
```

### Rename imported repository

In a specific situation, an imported repository needed to be renamed. The Support
Team was informed of a backup restore that failed on a single repository, which created
the project with an empty repository. The project was successfully restored to a development
instance, then exported, and imported into a new project under a different name.

The Support Team was able to transfer the incorrectly named imported project into the
correctly named empty project using the steps below.

Move the new repository to the empty repository:

```shell
mv /var/opt/gitlab/git-data/repositories/<group>/<new-project> /var/opt/gitlab/git-data/repositories/<group>/<empty-project>
```

Make sure the permissions are correct:

```shell
chown -R git:git <path-to-directory>.git
```

Clear the cache:

```shell
sudo gitlab-rake cache:clear
```

### Export a project

It's typically recommended to export a project through [the web interface](../../user/project/settings/import_export.md#export-a-project-and-its-data) or through [the API](../../api/project_import_export.md). In situations where this is not working as expected, it may be preferable to export a project directly via the Rails console:

```ruby
user = User.find_by_username('<username>')
# Sufficient permissions needed
# Read https://docs.gitlab.com/ee/user/permissions.html#project-members-permissions

project = Project.find_by_full_path('<username-or-group>/<project-name')
Projects::ImportExport::ExportService.new(project, user).execute
```

If this all runs successfully, you see an output like the following before being returned to the Rails console prompt:

```ruby
=> nil
```

The exported project is located in a `.tar.gz` file in `/var/opt/gitlab/gitlab-rails/uploads/-/system/import_export_upload/export_file/`.

If this fails, [enable verbose logging](../operations/rails_console.md#looking-up-database-persisted-objects),
repeat the above procedure after,
and report the output to
[GitLab Support](https://about.gitlab.com/support/).

## Repository

### Search sequence of pushes to a repository

If it seems that a commit has gone "missing", search the sequence of pushes to a repository.
[This StackOverflow article](https://stackoverflow.com/questions/13468027/the-mystery-of-the-missing-commit-across-merges)
describes how you can end up in this state without a force push. Another cause can be a misconfigured [server hook](../server_hooks.md) that changes a HEAD ref via a `git reset` operation.

If you look at the output from the sample code below for the target branch, you
see a discontinuity in the from/to commits as you step through the output. The `commit_from` of each new push should equal the `commit_to` of the previous push. A break in that sequence indicates one or more commits have been "lost" from the repository history.

The following example checks the last 100 pushes and prints the `commit_from` and `commit_to` entries:

```ruby
p = Project.find_by_full_path('u/p')
p.events.pushed_action.last(100).each do |e|
  printf "%-20.20s %8s...%8s (%s)
", e.push_event_payload[:ref], e.push_event_payload[:commit_from], e.push_event_payload[:commit_to], e.author.try(:username)
end
```

Example output showing break in sequence at line 4:

```plaintext
master               f21b07713251e04575908149bdc8ac1f105aabc3...6bc56c1f46244792222f6c85b11606933af171de (root)
master               6bc56c1f46244792222f6c85b11606933af171de...132da6064f5d3453d445fd7cb452b148705bdc1b (root)
master               132da6064f5d3453d445fd7cb452b148705bdc1b...a62e1e693150a2e46ace0ce696cd4a52856dfa65 (root)
master               58b07b719a4b0039fec810efa52f479ba1b84756...f05321a5b5728bd8a89b7bf530aa44043c951dce (root)
master               f05321a5b5728bd8a89b7bf530aa44043c951dce...7d02e575fd790e76a3284ee435368279a5eb3773 (root)
```

## Mirrors

### Find mirrors with "bad decrypt" errors

This content has been converted to a Rake task, see [verify database values can be decrypted using the current secrets](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Transfer mirror users and tokens to a single service account

Use case: If you have multiple users using their own GitHub credentials to set up
repository mirroring, mirroring breaks when people leave the company. Use this
script to migrate disparate mirroring users and tokens into a single service account:

```ruby
svc_user = User.find_by(username: 'ourServiceUser')
token = 'githubAccessToken'

Project.where(mirror: true).each do |project|
  import_url = project.import_url

  # The url we want is https://token@project/path.git
  repo_url = if import_url.include?('@')
               # Case 1: The url is something like https://23423432@project/path.git
               import_url.split('@').last
             elsif import_url.include?('//')
               # Case 2: The url is something like https://project/path.git
               import_url.split('//').last
             end

  next unless repo_url

  final_url = "https://#{token}@#{repo_url}"

  project.mirror_user = svc_user
  project.import_url = final_url
  project.username_only_import_url = final_url
  project.save
end
```

## Users

### Create new user

```ruby
u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
u.skip_confirmation! # Use it only if you wish user to be automatically confirmed. If skipped, user receives confirmation e-mail
u.save!
```

### Skip reconfirmation

```ruby
user = User.find_by_username('<username>')
user.skip_reconfirmation!
```

### Disable 2fa for single user

**In GitLab 13.5 and later:**

Use the code under [Disable 2FA | For a single user](../../security/two_factor_authentication.md#for-a-single-user) so that the target user
is notified that 2FA has been disabled.

**In GitLab 13.4 and earlier:**

```ruby
user = User.find_by_username('<username>')
user.disable_two_factor!
```

### Active users & Historical users

```ruby
# Active users on the instance, now
User.active.count

# Users taking a seat on the instance
User.billable.count

# The historical max on the instance as of the past year
::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
```

Using cURL and jq (up to a max 100, see [Pagination](../../api/index.md#pagination)):

```shell
curl --silent --header "Private-Token: ********************" \
     "https://gitlab.example.com/api/v4/users?per_page=100&active" | jq --compact-output '.[] | [.id,.name,.username]'
```

### Update Daily Billable & Historical users

```ruby
# Forces recount of historical (max) users
::HistoricalDataWorker.new.perform

# Forces recount of daily billable users
identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
```

### Block or Delete Users that have no projects or groups

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users are removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user|  user.blocked? ? nil  : user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```

### Deactivate Users that have no recent activity

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### Block Users that have no recent activity

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### Find a user's max permissions for project/group

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

## Groups

### Transfer group to another location

```ruby
user = User.find_by_username('<username>')
group = Group.find_by_name("<group_name>")
parent_group = Group.find_by(id: "<group_id>")
service = ::Groups::TransferService.new(group, user)
service.execute(parent_group)
```

### Count unique users in a group and subgroups

```ruby
group = Group.find_by_path_or_name("groupname")
members = []
for member in group.members_with_descendants
   members.push(member.user_name)
end

members.uniq.length
```

```ruby
group = Group.find_by_path_or_name("groupname")

# Count users from subgroup and up (inherited)
group.members_with_parents.count

# Count users from the parent group and down (specific grants)
parent.members_with_descendants.count
```

### Find groups that are pending deletion

```ruby
#
# This section lists all the groups which are pending deletion
#
Group.all.each do |g|
 if g.marked_for_deletion?
    puts "Group ID: #{g.id}"
    puts "Group name: #{g.name}"
    puts "Group path: #{g.full_path}"
 end
end
```

### Delete a group

```ruby
GroupDestroyWorker.perform_async(group_id, user_id)
```

### Modify group project creation

```ruby
# Project creation levels: 0 - No one, 1 - Maintainers, 2 - Developers + Maintainers
group = Group.find_by_path_or_name('group-name')
group.project_creation_level=0
```

### Modify group - disable 2FA requirement

WARNING:
When disabling the 2FA Requirement on a subgroup, the whole parent group (including all subgroups) is affected by this change.

```ruby
group = Group.find_by_path_or_name('group-name')
group.require_two_factor_authentication=false
group.save
```

### Check and toggle a feature for all projects in a group

```ruby
projects = Group.find_by_name('_group_name').projects
projects.each do |p|
  state = p.<feature-name>?

  if state
    puts "#{p.name} has <feature-name> already enabled. Skipping..."
  else
    puts "#{p.name} didn't have <feature-name> enabled. Enabling..."
    p.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
  end
end
```

To find features that can be toggled, run `pp p.project_feature`.
Available permission levels are listed in
[concerns/featurable.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/app/models/concerns/featurable.rb).

### Get all error messages associated with groups, subgroups, members, and requesters

Collect error messages associated with groups, subgroups, members, and requesters. This
captures error messages that may not appear in the Web interface. This can be especially helpful
for troubleshooting issues with [LDAP group sync](../auth/ldap/ldap_synchronization.md#group-sync)
and unexpected behavior with users and their membership in groups and subgroups.

```ruby
# Find the group and subgroup
group = Group.find_by_full_path("parent_group")
subgroup = Group.find_by_full_path("parent_group/child_group")

# Group and subgroup errors
group.valid?
group.errors.map(&:full_messages)

subgroup.valid?
subgroup.errors.map(&:full_messages)

# Group and subgroup errors for the members AND requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
group.members_and_requesters.map(&:errors).map(&:full_messages)

subgroup.requesters.map(&:valid?)
subgroup.requesters.map(&:errors).map(&:full_messages)
subgroup.members.map(&:valid?)
subgroup.members.map(&:errors).map(&:full_messages)
subgroup.members_and_requesters.map(&:errors).map(&:full_messages)
```

## Authentication

### Re-enable standard web sign-in form

Re-enable the standard username and password-based sign-in form if it was disabled as a [Sign-in restriction](../../user/admin_area/settings/sign_in_restrictions.md#password-authentication-enabled).

You can use this method when a configured external authentication provider (through SSO or an LDAP configuration) is facing an outage and direct sign-in access to GitLab is required.

```ruby
Gitlab::CurrentSettings.update!(password_authentication_enabled_for_web: true)
```

## SCIM

### Fixing bad SCIM identities

```ruby
def delete_bad_scim(email, group_path)
    output = ""
    u = User.find_by_email(email)
    uid = u.id
    g = Group.find_by_full_path(group_path)
    saml_prov_id = SamlProvider.find_by(group_id: g.id).id
    saml = Identity.where(user_id: uid, saml_provider_id: saml_prov_id)
    scim = ScimIdentity.where(user_id: uid , group_id: g.id)
    if saml[0]
      saml_eid = saml[0].extern_uid
      output +=  "%s," % [email]
      output +=  "SAML: %s," % [saml_eid]
      if scim[0]
        scim_eid = scim[0].extern_uid
        output += "SCIM: %s" % [scim_eid]
        if saml_eid == scim_eid
          output += " Identities matched, not deleted \n"
        else
          scim[0].destroy
          output += " Deleted \n"
        end
      else
        output = "ERROR No SCIM identify found for: [%s]\n" % [email]
        puts output
        return 1
      end
    else
      output = "ERROR No SAML identify found for: [%s]\n" % [email]
      puts output
      return 1
    end
      puts output
    return 0
end

# In case of multiple emails
emails = [email1, email2]

emails.each do |e|
  delete_bad_scim(e,'<group-path>')
end
```

### Find groups using an SQL query

Find and store an array of groups based on an SQL query:

```ruby
# Finds groups and subgroups that end with '%oup'
Group.find_by_sql("SELECT * FROM namespaces WHERE name LIKE '%oup'")
=> [#<Group id:3 @test-group>, #<Group id:4 @template-group/template-subgroup>]
```

## Routes

### Remove redirecting routes

See <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41758#note_54828133>.

```ruby
path = 'foo'
conflicting_permanent_redirects = RedirectRoute.matching_path_and_descendants(path)

# Check that conflicting_permanent_redirects is as expected
conflicting_permanent_redirects.destroy_all
```

## Merge requests

### Close a merge request properly (if merged but still marked as open)

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::PostMergeService.new(project: p, current_user: u).execute(m)
```

### Delete a merge request

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
Issuable::DestroyService.new(project: m.project, current_user: u).execute(m)
```

### Rebase manually

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::RebaseService.new(project: m.target_project, current_user: u).execute(m)
```

## CI

### Cancel stuck pending pipelines

For more information, see the [confidential issue](../../user/project/issues/confidential_issues.md)
`https://gitlab.com/gitlab-com/support-forum/issues/2449#note_41929707`.

```ruby
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').count
```

### Remove artifacts more than a week old

This section has been moved to the [job artifacts troubleshooting documentation](../job_artifacts.md#delete-job-artifacts-from-jobs-completed-before-a-specific-date).

### Find reason failure (for when build trace is empty) (Introduced in 10.3.0)

See <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41111>.

```ruby
build = Ci::Build.find(78420)

build.failure_reason

build.dependencies.each do |d| { puts "status: #{d.status}, finished at: #{d.finished_at},
  completed: #{d.complete?}, artifacts_expired: #{d.artifacts_expired?}, erased: #{d.erased?}" }
```

### Try CI integration

```ruby
p = Project.find_by_full_path('<project_path>')
m = project.merge_requests.find_by(iid: )
m.project.try(:ci_integration)
```

### Validate the `.gitlab-ci.yml`

```ruby
project = Project.find_by_full_path 'group/project'
content = project.repository.gitlab_ci_yml_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project,  current_user: User.first).validate(content)
```

### Disable AutoDevOps on Existing Projects

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

### Obtain runners registration token

```ruby
Gitlab::CurrentSettings.current_application_settings.runners_registration_token
```

### Seed runners registration token

```ruby
appSetting = Gitlab::CurrentSettings.current_application_settings
appSetting.set_runners_registration_token('<new-runners-registration-token>')
appSetting.save!
```

### Run pipeline schedules manually

You can run pipeline schedules manually through the Rails console to reveal any errors that are usually not visible.

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```

## License

### See current license information

```ruby
# License information (name, company, email address)
License.current.licensee

# Plan:
License.current.plan

# Uploaded:
License.current.created_at

# Started:
License.current.starts_at

# Expires at:
License.current.expires_at

# Is this a trial license?
License.current.trial?

# License ID for lookup on CustomersDot
License.current.license_id
```

### Check if a project feature is available on the instance

Features listed in <https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/license.rb>.

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

### Check if a project feature is available in a project

Features listed in [`license.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/license.rb).

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### Add a license through the console

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

This is needed for example in a known edge-case with
[expired license and multiple LDAP servers](../auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers).

### Remove licenses

To clean up the [License History table](../../user/admin_area/license_file.md#view-license-details-and-history):

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## Registry

### Registry Disk Space Usage by Project

As a GitLab administrator, you may want to reduce disk space consumption.
A common culprit is Docker Registry images that are no longer in use. To find
the storage broken down by each project, run the following in the
[GitLab Rails console](../operations/rails_console.md):

```ruby
projects_and_size = [["project_id", "creator_id", "registry_size_bytes", "project path"]]
# You need to specify the projects that you want to look through. You can get these in any manner.
projects = Project.last(100)

projects.each do |p|
   project_total_size = 0
   container_repositories = p.container_repositories

   container_repositories.each do |c|
       c.tags.each do |t|
          project_total_size = project_total_size + t.total_size unless t.total_size.nil?
       end
   end

   if project_total_size > 0
      projects_and_size << [p.project_id, p.creator.id, project_total_size, p.full_path]
   end
end

# projects_and_size is filled out now
# maybe print it as comma separated output?
projects_and_size.each do |ps|
   puts "%s,%s,%s,%s" % ps
end
```

### Run the Cleanup policy now

Find this content in the [Container Registry troubleshooting documentation](../packages/container_registry.md#run-the-cleanup-policy-now).

## Sidekiq

This content has been moved to [Troubleshooting Sidekiq](sidekiq.md).

## Redis

### Connect to Redis (omnibus)

```shell
/opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
```

## LFS

### Get information about LFS objects and associated project

```ruby
o = LfsObject.find_by(oid: "<oid>")
p = Project.find(LfsObjectsProject.find_by_lfs_object_id(o.id).project_id)
```

You can then delete these records from the database with:

```ruby
LfsObjectsProject.find_by_lfs_object_id(o.id).destroy
o.destroy
```

You would also want to combine this with deleting the LFS file in the LFS storage
area on disk. It remains to be seen exactly how or whether the deletion is useful, however.

## Decryption Problems

### Bad Decrypt Script (for encrypted variables)

This content has been converted to a Rake task, see [verify database values can be decrypted using the current secrets](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

As an example of repairing, if `ProjectImportData Bad count:` is detected and the decision is made to delete the
encrypted credentials to allow manual reentry:

```ruby
  # Find the ids of the corrupt ProjectImportData objects
  total = 0
  bad = []
  ProjectImportData.find_each do |data|
    begin
      total += 1
      data.credentials
    rescue => e
      bad << data.id
    end
  end

  puts "Bad count: #{bad.count} / #{total}"

  # See the bad ProjectImportData ids
  bad

  # Remove the corrupted credentials
  import_data = ProjectImportData.where(id: bad)
  import_data.each do |data|
    data.update_columns({ encrypted_credentials: nil, encrypted_credentials_iv: nil, encrypted_credentials_salt: nil})
  end
```

If `User OTP Secret Bad count:` is detected. For each user listed disable/enable
two-factor authentication.

The following script searches in some of the tables for encrypted tokens that are
causing decryption errors, and update or reset as needed:

```shell
wget -O /tmp/encrypted-tokens.rb https://gitlab.com/snippets/1876342/raw
gitlab-rails runner /tmp/encrypted-tokens.rb
```

### Decrypt Script for encrypted tokens

This content has been converted to a Rake task, see [verify database values can be decrypted using the current secrets](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

## Geo

### Artifacts

#### Find failed artifacts

```ruby
Geo::JobArtifactRegistry.failed
```

#### Get a count of the synced artifacts

```ruby
Geo::JobArtifactRegistry.synced.count
```

#### Find `ID` of synced artifacts that are missing on primary

```ruby
Geo::JobArtifactRegistry.synced.missing_on_primary.pluck(:artifact_id)
```

### Repository verification failures

#### Get the number of verification failed repositories

```ruby
Geo::ProjectRegistry.verification_failed('repository').count
```

#### Find the verification failed repositories

```ruby
Geo::ProjectRegistry.verification_failed('repository')
```

### Find repositories that failed to sync

```ruby
Geo::ProjectRegistry.sync_failed('repository')
```

### Resync repositories

#### Queue up all repositories for resync. Sidekiq handles each sync

```ruby
Geo::ProjectRegistry.update_all(resync_repository: true, resync_wiki: true)
```

#### Sync individual repository now

```ruby
project = Project.find_by_full_path('<group/project>')

Geo::RepositorySyncService.new(project).execute
```

### Blob types

- `Ci::JobArtifact`
- `Ci::PipelineArtifact`
- `LfsObject`
- `MergeRequestDiff`
- `Packages::PackageFile`
- `PagesDeployment`
- `Terraform::StateVersion`
- `Upload`

`Packages::PackageFile` is used in the following examples, but things generally work the same for the other Blob types.

#### The Replicator

The main kinds of classes are Registry, Model, and Replicator. If you have an instance of one of these classes, you can get the others. The Registry and Model mostly manage PostgreSQL DB state. The Replicator knows how to replicate/verify (or it can call a service to do it):

```ruby
model_record = Packages::PackageFile.last
model_record.replicator.registry.replicator.model_record # just showing that these methods exist
```

#### Replicate a package file, synchronously, given an ID

```ruby
model_record = Packages::PackageFile.find(id)
model_record.replicator.send(:download)
```

#### Replicate a package file, synchronously, given a registry ID

```ruby
registry = Geo::PackageFileRegistry.find(registry_id)
registry.replicator.send(:download)
```

#### Verify package files on the secondary manually

This iterates over all package files on the secondary, looking at the
`verification_checksum` stored in the database (which came from the primary)
and then calculate this value on the secondary to check if they match. This
does not change anything in the UI:

```ruby
# Run on secondary
status = {}

Packages::PackageFile.find_each do |package_file|
  primary_checksum = package_file.verification_checksum
  secondary_checksum = Packages::PackageFile.hexdigest(package_file.file.path)
  verification_status = (primary_checksum == secondary_checksum)

  status[verification_status.to_s] ||= []
  status[verification_status.to_s] << package_file.id
end

# Count how many of each value we get
status.keys.each {|key| puts "#{key} count: #{status[key].count}"}

# See the output in its entirety
status
```

### Repository types newer than project/wiki repositories

- `SnippetRepository`
- `GroupWikiRepository`

`SnippetRepository` is used in the examples below, but things generally work the same for the other Repository types.

#### The Replicator

The main kinds of classes are Registry, Model, and Replicator. If you have an instance of one of these classes, you can get the others. The Registry and Model mostly manage PostgreSQL DB state. The Replicator knows how to replicate/verify (or it can call a service to do it).

```ruby
model_record = SnippetRepository.last
model_record.replicator.registry.replicator.model_record # just showing that these methods exist
```

#### Replicate a snippet repository, synchronously, given an ID

```ruby
model_record = SnippetRepository.find(id)
model_record.replicator.send(:sync_repository)
```

#### Replicate a snippet repository, synchronously, given a registry ID

```ruby
registry = Geo::SnippetRepositoryRegistry.find(registry_id)
registry.replicator.send(:sync_repository)
```

## Gitaly

### Find available and used space

A Gitaly storage resource can be polled through Rails to determine the available and used space.

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
```

## Generate Service Ping

The [Service Ping Guide](../../development/service_ping/index.md) in our developer documentation
has more information about Service Ping.

### Generate or get the cached Service Ping

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values, cached: true)
```

### Generate a fresh new Service Ping

This also refreshes the cached Service Ping displayed in the Admin Area

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
```

### Generate and print

Generates Service Ping data in JSON format.

```shell
rake gitlab:usage_data:generate
```

Generates Service Ping data in YAML format:

```shell
rake gitlab:usage_data:dump_sql_in_yaml
```

### Generate and send Service Ping

Prints the metrics saved in `conversational_development_index_metrics`.

```shell
rake gitlab:usage_data:generate_and_send
```

## Kubernetes integration

Find cluster:

```ruby
cluster = Clusters::Cluster.find(1)
cluster = Clusters::Cluster.find_by(name: 'cluster_name')
```

Delete cluster without associated resources:

```ruby
# Find users with the administrator access
user = User.find_by(username: 'admin_user')

# Find the cluster with the ID
cluster = Clusters::Cluster.find(1)

# Delete the cluster
Clusters::DestroyService.new(user).execute(cluster)
```

## Elasticsearch

### Configuration attributes

Open the rails console (`gitlab rails c`) and run the following command to see all the available attributes:

```ruby
ApplicationSetting.last.attributes
```

Among other attributes, the output contains all the settings available in the [Elasticsearch Integration page](../../integration/advanced_search/elasticsearch.md), such as `elasticsearch_indexing`, `elasticsearch_url`, `elasticsearch_replicas`, and `elasticsearch_pause_indexing`.

#### Setting attributes

You can then set anyone of Elasticsearch integration settings by issuing a command similar to:

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

#### Getting attributes

You can then check if the settings have been set in the [Elasticsearch Integration page](../../integration/advanced_search/elasticsearch.md) or in the rails console by issuing:

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

#### Changing the Elasticsearch password

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current ElasticSearch URL
es_url.elasticsearch_url

# Set the ElasticSearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```
