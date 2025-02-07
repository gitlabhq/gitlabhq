---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

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

To resolve this error:

- If you followed the [version-specific upgrade instructions for 14.2](https://archives.docs.gitlab.com/17.3/ee/update/versions/gitlab_14_changes.html#1420),
  [manually finish the batched background migration](background_migrations.md#finish-a-failed-migration-manually).
- If you didn't follow those instructions, you must either:
  - [Roll back and upgrade](#roll-back-and-follow-the-required-upgrade-path) through one of the required
    versions before updating to 14.2+.
  - [Roll forward](#roll-forward-and-finish-the-migrations-on-the-upgraded-version), staying on the current
   version and manually ensuring that the batched migrations complete successfully.

### Roll back and follow the required upgrade path

To roll back and follow the required upgrade path:

1. [Roll back and restore the previously installed version](../administration/backup_restore/_index.md).
1. Update to either 14.0.5 or 14.1 **before** updating to 14.2+.
1. [Check the status](background_migrations.md#check-the-status-of-batched-background-migrations) of the batched
   background migrations and make sure they are all marked as finished before attempting to upgrade again. If any remain
   marked as active, [manually finish them](background_migrations.md#finish-a-failed-migration-manually).

### Roll forward and finish the migrations on the upgraded version

The process for rolling forward depends on whether no downtime is required or not.

#### For a deployment with downtime

Running all batched background migrations can take a significant amount of time depending on the size of your GitLab installation.

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

Because the failing migrations are post-deployment migrations, you can remain on a running instance of the upgraded
version and wait for the batched background migrations to finish.

1. [Check the status](background_migrations.md#check-the-status-of-batched-background-migrations) of the batched
   background migration from the error message, and make sure it is listed as finished. If the migration is still active,
   either:
   - Wait until it is finished.
   - [Manually finish it](background_migrations.md#finish-a-failed-migration-manually).
1. Re-run migrations for your installation so the remaining post-deployment migrations finish.

## Background migrations remain in the Sidekiq queue

WARNING:
The following operations can disrupt your GitLab performance. They run Sidekiq jobs that perform various database or file updates.

Run the following check. If the check returns non-zero and the count does not decrease over time, follow the rest of the steps in this section.

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

## Advanced search migrations are stuck

In GitLab 15.0, an advanced search migration named `DeleteOrphanedCommit` can be permanently stuck
in a pending state across upgrades. This issue
[is corrected in GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89539).

If you are a self-managed customer who uses GitLab 15.0 with advanced search, you will experience performance degradation.
To clean up the migration, upgrade to 15.1 or later.

For other advanced search migrations stuck in pending problems, [retry the halted migrations](../integration/advanced_search/elasticsearch.md#retry-a-halted-migration).

If you upgrade GitLab before all pending advanced search migrations are completed, any pending migrations
that have been removed in the new version cannot be executed or retried.
In this case, you must
[re-create your index from scratch](../integration/elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).

## Error: `Elasticsearch version not compatible`

To resolve this problem, confirm that your version of Elasticsearch or OpenSearch is
[compatible with your version of GitLab](../integration/advanced_search/elasticsearch.md#version-requirements).
