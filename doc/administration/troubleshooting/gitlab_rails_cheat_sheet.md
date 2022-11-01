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
