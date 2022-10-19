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

### Close a merge request

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::CloseService.new(project: p, current_user: u).execute(m)
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

### Set a merge request as merged

Use when a merge request was accepted and the changes merged into the Git repository,
but the merge request still shows as open.

If the changes are not merged yet, this action causes the merge request to
incorrectly show `merged into <branch-name>`.

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::PostMergeService.new(project: p, current_user: u).execute(m)
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

# License data in Base64-encoded ASCII format
License.current.data
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

Find this content in the [Container Registry troubleshooting documentation](../packages/container_registry.md#registry-disk-space-usage-by-project).

### Run the Cleanup policy now

Find this content in the [Container Registry troubleshooting documentation](../packages/container_registry.md#run-the-cleanup-policy-now).

## Sidekiq

This content has been moved to [Troubleshooting Sidekiq](sidekiq.md).

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
There is an [issue to implement this functionality in the Admin UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

### Artifacts

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#find-failed-artifacts).

### Repository verification failures

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#repository-verification-failures).

### Resync repositories

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#resync-repositories).

### Blob types

Moved to [Geo replication troubleshooting](../geo/replication/troubleshooting.md#blob-types).

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
