---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

## Mirrors

### Find mirrors with "bad decrypt" errors

This content has been converted to a Rake task, see [verify database values can be decrypted using the current secrets](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Transfer mirror users and tokens to a single service account

This content has been moved to [Troubleshooting Repository mirroring](../../user/project/repository/mirror/index.md#transfer-mirror-users-and-tokens-to-a-single-service-account-in-rails-console).

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

## Merge requests

## CI

This content has been moved to [Troubleshooting CI/CD](../../ci/troubleshooting.md).

## License

This content has been moved to [Activate GitLab EE with a license file or key](../../user/admin_area/license_file.md).

## Registry

### Registry Disk Space Usage by Project

Find this content in the [Container Registry troubleshooting documentation](../packages/container_registry.md#registry-disk-space-usage-by-project).

### Run the Cleanup policy now

Find this content in the [Container Registry troubleshooting documentation](../packages/container_registry.md#run-the-cleanup-policy-now).

## Sidekiq

This content has been moved to [Troubleshooting Sidekiq](../sidekiq/sidekiq_troubleshooting.md).

## Geo

### Reverify all uploads (or any SSF data type which is verified)

1. SSH into a GitLab Rails node in the primary Geo site.
1. Open [Rails console](../operations/rails_console.md).
1. Mark all uploads as "pending verification":

   ```ruby
   Upload.verification_state_table_class.each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

1. This will cause the primary to start checksumming all Uploads.
1. When a primary successfully checksums a record, then all secondaries rechecksum as well, and they compare the values.

A similar thing can be done for all Models handled by the [Geo Self-Service Framework](../../development/geo/framework.md) which have implemented verification:

- `LfsObject`
- `MergeRequestDiff`
- `Packages::PackageFile`
- `Terraform::StateVersion`
- `SnippetRepository`
- `Ci::PipelineArtifact`
- `PagesDeployment`
- `Upload`
- `Ci::JobArtifact`
- `Ci::SecureFile`

NOTE:
`GroupWikiRepository` is not in the previous list since verification is not implemented.
There is an [issue to implement this functionality in the Admin Area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

### Artifacts

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#find-failed-artifacts).

### Repository verification failures

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#repository-verification-failures).

### Resync repositories

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#resync-repositories).

### Blob types

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#blob-types).

## Generate Service Ping

This content has been moved to [Service Ping Troubleshooting](../../development/service_ping/troubleshooting.md).

## GraphQL

Call a [GraphQL](../../api/graphql/getting_started.md) endpoint through the Rails console:

```ruby
query = <<~EOQ
query securityGetProjects($search: String!) {
  projects(search: $search) {
    nodes {
      path
    }
  }
}
EOQ

variables = { "search": "gitlab" }

result = GitlabSchema.execute(query, variables: variables, context: { current_user: current_user })
result.to_h
```
