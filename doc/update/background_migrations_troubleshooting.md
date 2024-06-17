---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

<!-- Linked from lib/gitlab/database/migrations/batched_background_migration_helpers.rb -->

## Database migrations failing because of batched background migration not finished

When updating to GitLab version 14.2 or later, database migrations might fail with a message like:

```plaintext
StandardError: An error has occurred, all later migrations canceled:

Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob",
   :table_name=>"push_event_payloads",
   :column_name=>"event_id",
   :job_arguments=>[["event_id"],
   ["event_id_convert_to_bigint"]]
  }
```

First, check if you have followed the [version-specific upgrade instructions for 14.2](../update/versions/gitlab_14_changes.md#1420).
If you have, you can [manually finish the batched background migration](background_migrations.md#finish-a-failed-migration-manually)).
If you haven't, choose one of the following methods:

1. [Rollback and upgrade](#roll-back-and-follow-the-required-upgrade-path) through one of the required
   versions before updating to 14.2+.
1. [Roll forward](#roll-forward-and-finish-the-migrations-on-the-upgraded-version), staying on the current
   version and manually ensuring that the batched migrations complete successfully.

### Roll back and follow the required upgrade path

1. [Rollback and restore the previously installed version](../administration/backup_restore/index.md)
1. Update to either 14.0.5 or 14.1 **before** updating to 14.2+
1. [Check the status](background_migrations.md#check-the-status-of-batched-background-migrations) of the batched background migrations and
   make sure they are all marked as finished before attempting to upgrade again. If any remain marked as active,
   you can [manually finish them](background_migrations.md#finish-a-failed-migration-manually).

### Roll forward and finish the migrations on the upgraded version

#### For a deployment with downtime

To run all the batched background migrations, it can take a significant amount of time
depending on the size of your GitLab installation.

1. [Check the status](background_migrations.md#check-the-status-of-batched-background-migrations) of the batched background migrations in the
   database, and [manually run them](background_migrations.md#finish-a-failed-migration-manually) with the appropriate
   arguments until the status query returns no rows.
1. When the status of all of all them is marked as complete, re-run migrations for your installation.
1. [Complete the database migrations](../administration/raketasks/maintenance.md#run-incomplete-database-migrations) from your GitLab upgrade:

   ```plaintext
   sudo gitlab-rake db:migrate
   ```

1. Run a reconfigure:

   ```plaintext
   sudo gitlab-ctl reconfigure
   ```

1. Finish the upgrade for your installation.

#### For a no-downtime deployment

As the failing migrations are post-deployment migrations, you can remain on a running instance of the upgraded
version and wait for the batched background migrations to finish.

1. [Check the status](background_migrations.md#check-the-status-of-batched-background-migrations) of the batched background migration from
   the error message, and make sure it is listed as finished. If it is still active, either wait until it is done,
   or [manually finish it](background_migrations.md#finish-a-failed-migration-manually).
1. Re-run migrations for your installation, so the remaining post-deployment migrations finish.

## Background migrations remain in the Sidekiq queue

WARNING:
The following operations can disrupt your GitLab performance. They run a number of Sidekiq jobs that perform various database or file updates.

Run the following check. If it returns non-zero and the count does not decrease over time, follow the rest of the steps in this section.

```shell
# For Linux package installations:
sudo gitlab-rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'

# For self-compiled installations:
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

It is safe to re-execute the following commands, especially if you have 1000+ pending jobs which would likely overflow your runtime memory.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

:::TabTitle Self-compiled (source)

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

::EndTabs

## Background migrations stuck in 'pending' state

For background migrations stuck in pending, run the following check. If
it returns non-zero and the count does not decrease over time, follow the rest
of the steps in this section.

```shell
# For Linux package installations:
sudo gitlab-rails runner -e production 'puts Gitlab::Database::BackgroundMigrationJob.pending.count'

# For self-compiled installations:
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::Database::BackgroundMigrationJob.pending.count'
```

It is safe to re-attempt these migrations to clear them out from a pending status:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
Gitlab::Database::BackgroundMigrationJob.pending.find_each do |job|
  puts "Running pending job '#{job.class_name}' with arguments #{job.arguments}"
  result = Gitlab::BackgroundMigration.perform(job.class_name, job.arguments)
  puts "Result: #{result}"
end
```

:::TabTitle Self-compiled (source)

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
Gitlab::Database::BackgroundMigrationJob.pending.find_each do |job|
  puts "Running pending job '#{job.class_name}' with arguments #{job.arguments}"
  result = Gitlab::BackgroundMigration.perform(job.class_name, job.arguments)
  puts "Result: #{result}"
end
```

::EndTabs
