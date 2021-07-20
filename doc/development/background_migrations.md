---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Background migrations

Background migrations should be used to perform data migrations whenever a
migration exceeds [the time limits in our guidelines](database_review.md#timing-guidelines-for-migrations). For example, you can use background
migrations to migrate data that's stored in a single JSON column
to a separate table instead.

If the database cluster is considered to be in an unhealthy state, background
migrations automatically reschedule themselves for a later point in time.

## When To Use Background Migrations

You should use a background migration when you migrate _data_ in tables that have
so many rows that the process would exceed [the time limits in our guidelines](database_review.md#timing-guidelines-for-migrations) if performed using a regular Rails migration.

- Background migrations should be used when migrating data in [high-traffic tables](migration_style_guide.md#high-traffic-tables).
- Background migrations may also be used when executing numerous single-row queries
for every item on a large dataset. Typically, for single-record patterns, runtime is
largely dependent on the size of the dataset, hence it should be split accordingly
and put into background migrations.
- Background migrations should not be used to perform schema migrations.

Some examples where background migrations can be useful:

- Migrating events from one table to multiple separate tables.
- Populating one column based on JSON stored in another column.
- Migrating data that depends on the output of external services (e.g. an API).

NOTE:
If the background migration is part of an important upgrade, make sure it's announced
in the release post. Discuss with your Project Manager if you're not sure the migration falls
into this category.

## Isolation

Background migrations must be isolated and can not use application code (e.g.
models defined in `app/models`). Since these migrations can take a long time to
run it's possible for new versions to be deployed while they are still running.

It's also possible for different migrations to be executed at the same time.
This means that different background migrations should not migrate data in a
way that would cause conflicts.

## Idempotence

Background migrations are executed in a context of a Sidekiq process.
Usual Sidekiq rules apply, especially the rule that jobs should be small
and idempotent.

See [Sidekiq best practices guidelines](https://github.com/mperham/sidekiq/wiki/Best-Practices)
for more details.

Make sure that in case that your migration job is going to be retried data
integrity is guaranteed.

## Background migrations for EE-only features

All the background migration classes for EE-only features should be present in GitLab CE.
For this purpose, an empty class can be created for GitLab CE, and it can be extended for GitLab EE
as explained in the [guidelines for implementing Enterprise Edition features](ee_features.md#code-in-libgitlabbackground_migration).

## How It Works

Background migrations are simple classes that define a `perform` method. A
Sidekiq worker will then execute such a class, passing any arguments to it. All
migration classes must be defined in the namespace
`Gitlab::BackgroundMigration`, the files should be placed in the directory
`lib/gitlab/background_migration/`.

## Scheduling

Scheduling a background migration should be done in a post-deployment
migration that includes `Gitlab::Database::MigrationHelpers`
To do so, simply use the following code while
replacing the class name and arguments with whatever values are necessary for
your migration:

```ruby
migrate_async('BackgroundMigrationClassName', [arg1, arg2, ...])
```

Usually it's better to enqueue jobs in bulk, for this you can use
`bulk_migrate_async`:

```ruby
bulk_migrate_async(
  [['BackgroundMigrationClassName', [1]],
   ['BackgroundMigrationClassName', [2]]]
)
```

Note that this will queue a Sidekiq job immediately: if you have a large number
of records, this may not be what you want. You can use the function
`queue_background_migration_jobs_by_range_at_intervals` to split the job into
batches:

```ruby
queue_background_migration_jobs_by_range_at_intervals(
  ClassName,
  BackgroundMigrationClassName,
  2.minutes,
  batch_size: 10_000
  )
```

You'll also need to make sure that newly created data is either migrated, or
saved in both the old and new version upon creation. For complex and time
consuming migrations it's best to schedule a background job using an
`after_create` hook so this doesn't affect response timings. The same applies to
updates. Removals in turn can be handled by simply defining foreign keys with
cascading deletes.

If you would like to schedule jobs in bulk with a delay, you can use
`BackgroundMigrationWorker.bulk_perform_in`:

```ruby
jobs = [['BackgroundMigrationClassName', [1]],
        ['BackgroundMigrationClassName', [2]]]

bulk_migrate_in(5.minutes, jobs)
```

### Rescheduling background migrations

If one of the background migrations contains a bug that is fixed in a patch
release, the background migration needs to be rescheduled so the migration would
be repeated on systems that already performed the initial migration.

When you reschedule the background migration, make sure to turn the original
scheduling into a no-op by clearing up the `#up` and `#down` methods of the
migration performing the scheduling. Otherwise the background migration would be
scheduled multiple times on systems that are upgrading multiple patch releases at
once.

When you start the second post-deployment migration, you should delete any
previously queued jobs from the initial migration with the provided
helper:

```ruby
delete_queued_jobs('BackgroundMigrationClassName')
```

## Cleaning Up

NOTE:
Cleaning up any remaining background migrations _must_ be done in either a major
or minor release, you _must not_ do this in a patch release.

Because background migrations can take a long time you can't immediately clean
things up after scheduling them. For example, you can't drop a column that's
used in the migration process as this would cause jobs to fail. This means that
you'll need to add a separate _post deployment_ migration in a future release
that finishes any remaining jobs before cleaning things up (e.g. removing a
column).

As an example, say you want to migrate the data from column `foo` (containing a
big JSON blob) to column `bar` (containing a string). The process for this would
roughly be as follows:

1. Release A:
   1. Create a migration class that perform the migration for a row with a given ID.
   1. Deploy the code for this release, this should include some code that will
      schedule jobs for newly created data (e.g. using an `after_create` hook).
   1. Schedule jobs for all existing rows in a post-deployment migration. It's
      possible some newly created rows may be scheduled twice so your migration
      should take care of this.
1. Release B:
   1. Deploy code so that the application starts using the new column and stops
      scheduling jobs for newly created data.
   1. In a post-deployment migration use `finalize_background_migration` from
      `BackgroundMigrationHelpers` to ensure no jobs remain. This helper will:
         1. Use `Gitlab::BackgroundMigration.steal` to process any remaining
            jobs in Sidekiq.
         1. Reschedule the migration to be run directly (i.e. not through Sidekiq)
            on any rows that weren't migrated by Sidekiq. This can happen if, for
            instance, Sidekiq received a SIGKILL, or if a particular batch failed
            enough times to be marked as dead.
         1. Remove `Gitlab::Database::BackgroundMigrationJob` rows where
            `status = succeeded`. To retain diagnostic information that may
            help with future bug tracking you can skip this step by specifying
            the `delete_tracking_jobs: false` parameter.
   1. Remove the old column.

This may also require a bump to the [import/export version](../user/project/settings/import_export.md), if
importing a project from a prior version of GitLab requires the data to be in
the new format.

## Example

To explain all this, let's use the following example: the table `services` has a
field called `properties` which is stored in JSON. For all rows you want to
extract the `url` key from this JSON object and store it in the `services.url`
column. There are millions of services and parsing JSON is slow, thus you can't
do this in a regular migration.

To do this using a background migration we'll start with defining our migration
class:

```ruby
class Gitlab::BackgroundMigration::ExtractServicesUrl
  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def perform(service_id)
    # A row may be removed between scheduling and starting of a job, thus we
    # need to make sure the data is still present before doing any work.
    service = Service.select(:properties).find_by(id: service_id)

    return unless service

    begin
      json = JSON.load(service.properties)
    rescue JSON::ParserError
      # If the JSON is invalid we don't want to keep the job around forever,
      # instead we'll just leave the "url" field to whatever the default value
      # is.
      return
    end

    service.update(url: json['url']) if json['url']
  end
end
```

Next we'll need to adjust our code so we schedule the above migration for newly
created and updated services. We can do this using something along the lines of
the following:

```ruby
class Service < ActiveRecord::Base
  after_commit :schedule_service_migration, on: :update
  after_commit :schedule_service_migration, on: :create

  def schedule_service_migration
    BackgroundMigrationWorker.perform_async('ExtractServicesUrl', [id])
  end
end
```

We're using `after_commit` here to ensure the Sidekiq job is not scheduled
before the transaction completes as doing so can lead to race conditions where
the changes are not yet visible to the worker.

Next we'll need a post-deployment migration that schedules the migration for
existing data. Since we're dealing with a lot of rows we'll schedule jobs in
batches instead of doing this one by one:

```ruby
class ScheduleExtractServicesUrl < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    define_batchable_model('services').select(:id).in_batches do |relation|
      jobs = relation.pluck(:id).map do |id|
        ['ExtractServicesUrl', [id]]
      end

      BackgroundMigrationWorker.bulk_perform_async(jobs)
    end
  end

  def down
  end
end
```

Once deployed our application will continue using the data as before but at the
same time will ensure that both existing and new data is migrated.

In the next release we can remove the `after_commit` hooks and related code. We
will also need to add a post-deployment migration that consumes any remaining
jobs and manually run on any un-migrated rows. Such a migration would look like
this:

```ruby
class ConsumeRemainingExtractServicesUrlJobs < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    # This must be included
    Gitlab::BackgroundMigration.steal('ExtractServicesUrl')

    # This should be included, but can be skipped - see below
    define_batchable_model('services').where(url: nil).each_batch(of: 50) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::ExtractServicesUrl.new.perform(*range)
    end
  end

  def down
  end
end
```

The final step runs for any un-migrated rows after all of the jobs have been
processed. This is in case a Sidekiq process running the background migrations
received SIGKILL, leading to the jobs being lost. (See
[more reliable Sidekiq queue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/36791) for more information.)

If the application does not depend on the data being 100% migrated (for
instance, the data is advisory, and not mission-critical), then this final step
can be skipped.

This migration will then process any jobs for the ExtractServicesUrl migration
and continue once all jobs have been processed. Once done you can safely remove
the `services.properties` column.

## Testing

It is required to write tests for:

- The background migrations' scheduling migration.
- The background migration itself.
- A cleanup migration.

The `:migration` and `schema: :latest` RSpec tags are automatically set for
background migration specs.
See the
[Testing Rails migrations](testing_guide/testing_migrations_guide.md#testing-a-non-activerecordmigration-class)
style guide.

Keep in mind that `before` and `after` RSpec hooks are going
to migrate you database down and up, which can result in other background
migrations being called. That means that using `spy` test doubles with
`have_received` is encouraged, instead of using regular test doubles, because
your expectations defined in a `it` block can conflict with what is being
called in RSpec hooks. See [issue #35351](https://gitlab.com/gitlab-org/gitlab/-/issues/18839)
for more details.

## Best practices

1. Make sure to know how much data you're dealing with.
1. Make sure that background migration jobs are idempotent.
1. Make sure that tests you write are not false positives.
1. Make sure that if the data being migrated is critical and cannot be lost, the
   clean-up migration also checks the final state of the data before completing.
1. When migrating many columns, make sure it won't generate too many
   dead tuples in the process (you may need to directly query the number of dead tuples
   and adjust the scheduling according to this piece of data).
1. Make sure to discuss the numbers with a database specialist, the migration may add
   more pressure on DB than you expect (measure on staging,
   or ask someone to measure on production).
1. Make sure to know how much time it'll take to run all scheduled migrations.
1. Provide an estimation section in the description, estimating both the total migration
   run time and the query times for each background migration job. Explain plans for each query
   should also be provided.

   For example, assuming a migration that deletes data, include information similar to
   the following section:

   ```plaintext
   Background Migration Details:

   47600 items to delete
   batch size = 1000
   47600 / 1000 = 48 batches

   Estimated times per batch:
   - 820ms for select statement with 1000 items (see linked explain plan)
   - 900ms for delete statement with 1000 items (see linked explain plan)
   Total: ~2 sec per batch

   2 mins delay per batch (safe for the given total time per batch)

   48 batches * 2 min per batch = 96 mins to run all the scheduled jobs
   ```

   The execution time per batch (2 sec in this example) is not included in the calculation
   for total migration time. The jobs are scheduled 2 minutes apart without knowledge of
   the execution time.

## Additional tips and strategies

### Nested batching

A strategy to make the migration run faster is to schedule larger batches, and then use `EachBatch`
within the background migration to perform multiple statements.

The background migration helpers that queue multiple jobs such as
`queue_background_migration_jobs_by_range_at_intervals` use [`EachBatch`](iterating_tables_in_batches.md).
The example above has batches of 1000, where each queued job takes two seconds. If the query has been optimized
to make the time for the delete statement within the [query performance guidelines](query_performance.md),
1000 may be the largest number of records that can be deleted in a reasonable amount of time.

The minimum and most common interval for delaying jobs is two minutes. This results in two seconds
of work for each two minute job. There's nothing that prevents you from executing multiple delete
statements in each background migration job.

Looking at the example above, you could alternatively do:

```plaintext
Background Migration Details:

47600 items to delete
batch size = 10_000
47600 / 10_000 = 5 batches

Estimated times per batch:
- Records are updated in sub-batches of 1000 => 10_000 / 1000 = 10 total updates
- 820ms for select statement with 1000 items (see linked explain plan)
- 900ms for delete statement with 1000 items (see linked explain plan)
Sub-batch total: ~2 sec per sub-batch,
Total batch time: 2 * 10 = 20 sec per batch

2 mins delay per batch

5 batches * 2 min per batch = 10 mins to run all the scheduled jobs
```

The batch time of 20 seconds still fits comfortably within the two minute delay, yet the total run
time is cut by a tenth from around 100 minutes to 10 minutes! When dealing with large background
migrations, this can cut the total migration time by days.

When batching in this way, it is important to look at query times on the higher end
of the table or relation being updated. `EachBatch` may generate some queries that become much
slower when dealing with higher ID ranges.

### Delay time

When looking at the batch execution time versus the delay time, the execution time
should fit comfortably within the delay time for a few reasons:

- To allow for a variance in query times.
- To allow autovacuum to catch up after periods of high churn.

Never try to optimize by fully filling the delay window even if you are confident
the queries themselves have no timing variance.

### Background jobs tracking

`queue_background_migration_jobs_by_range_at_intervals` can create records for each job that is scheduled to run.
You can enable this behavior by passing `track_jobs: true`. Each record starts with a `pending` status. Make sure that your worker updates the job status to `succeeded` by calling `Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded` in the `perform` method of your background migration.

```ruby
# Background migration code

def perform(start_id, end_id)
  # do work here

  mark_job_as_succeeded(start_id, end_id)
end

private

# Make sure that the arguments passed here match those passed to the background
# migration
def mark_job_as_succeeded(*arguments)
 Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
    self.class.name.demodulize,
    arguments
  )
end
```

```ruby
# Post deployment migration
include Gitlab::Database::MigrationHelpers

MIGRATION = 'YourBackgroundMigrationName'
DELAY_INTERVAL = 2.minutes.to_i # can be different
BATCH_SIZE = 10_000 # can be different

disable_ddl_transaction!

def up
  queue_background_migration_jobs_by_range_at_intervals(
    define_batchable_model('name_of_the_table_backing_the_model'),
    MIGRATION,
    DELAY_INTERVAL,
    batch_size: BATCH_SIZE,
    track_jobs: true
  )
end

def down
  # no-op
end
```

See [`lib/gitlab/background_migration/drop_invalid_vulnerabilities.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/background_migration/drop_invalid_vulnerabilities.rb) for a full example.

#### Rescheduling pending jobs

You can reschedule pending migrations from the `background_migration_jobs` table by creating a post-deployment migration and calling `requeue_background_migration_jobs_by_range_at_intervals` with the migration name and delay interval.

```ruby
# Post deployment migration
include Gitlab::Database::MigrationHelpers

MIGRATION = 'YourBackgroundMigrationName'
DELAY_INTERVAL = 2.minutes

disable_ddl_transaction!

def up
  requeue_background_migration_jobs_by_range_at_intervals(MIGRATION, DELAY_INTERVAL)
end

def down
  # no-op
end
```

See [`db/post_migrate/20210604070207_retry_backfill_traversal_ids.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/db/post_migrate/20210604070207_retry_backfill_traversal_ids.rb) for a full example.
