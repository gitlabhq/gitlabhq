---
type: reference, dev
stage: Enablement
group: Database
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Batched background migrations

Batched Background Migrations should be used to perform data migrations whenever a
migration exceeds [the time limits](migration_style_guide.md#how-long-a-migration-should-take)
in our guidelines. For example, you can use batched background
migrations to migrate data that's stored in a single JSON column
to a separate table instead.

## When to use batched background migrations

Use a batched background migration when you migrate _data_ in tables containing
so many rows that the process would exceed
[the time limits in our guidelines](migration_style_guide.md#how-long-a-migration-should-take)
if performed using a regular Rails migration.

- Batched background migrations should be used when migrating data in
  [high-traffic tables](migration_style_guide.md#high-traffic-tables).
- Batched background migrations may also be used when executing numerous single-row queries
  for every item on a large dataset. Typically, for single-record patterns, runtime is
  largely dependent on the size of the dataset. Split the dataset accordingly,
  and put it into background migrations.
- Don't use batched background migrations to perform schema migrations.

Background migrations can help when:

- Migrating events from one table to multiple separate tables.
- Populating one column based on JSON stored in another column.
- Migrating data that depends on the output of external services. (For example, an API.)

NOTE:
If the batched background migration is part of an important upgrade, it must be announced
in the release post. Discuss with your Project Manager if you're unsure if the migration falls
into this category.

## Isolation

Batched background migrations must be isolated and can not use application code. (For example,
models defined in `app/models`.). Because these migrations can take a long time to
run, it's possible for new versions to deploy while the migrations are still running.

## Idempotence

Batched background migrations are executed in a context of a Sidekiq process.
The usual Sidekiq rules apply, especially the rule that jobs should be small
and idempotent. Make sure that in case that your migration job is retried, data
integrity is guaranteed.

See [Sidekiq best practices guidelines](https://github.com/mperham/sidekiq/wiki/Best-Practices)
for more details.

## Batched background migrations for EE-only features

All the background migration classes for EE-only features should be present in GitLab CE.
For this purpose, create an empty class for GitLab CE, and extend it for GitLab EE
as explained in the guidelines for
[implementing Enterprise Edition features](ee_features.md#code-in-libgitlabbackground_migration).

Batched Background migrations are simple classes that define a `perform` method. A
Sidekiq worker then executes such a class, passing any arguments to it. All
migration classes must be defined in the namespace
`Gitlab::BackgroundMigration`. Place the files in the directory
`lib/gitlab/background_migration/`.

## Queueing

Queueing a batched background migration should be done in a post-deployment
migration. Use this `queue_batched_background_migration` example, queueing the
migration to be executed in batches. Replace the class name and arguments with the values
from your migration:

```ruby
queue_batched_background_migration(
  JOB_CLASS_NAME,
  TABLE_NAME,
  JOB_ARGUMENTS,
  JOB_INTERVAL
  )
```

Make sure the newly-created data is either migrated, or
saved in both the old and new version upon creation. Removals in
turn can be handled by defining foreign keys with cascading deletes.

### Requeuing batched background migrations

If one of the batched background migrations contains a bug that is fixed in a patch
release, you must requeue the batched background migration so the migration
repeats on systems that already performed the initial migration.

When you requeue the batched background migration, turn the original
queuing into a no-op by clearing up the `#up` and `#down` methods of the
migration performing the requeuing. Otherwise, the batched background migration is
queued multiple times on systems that are upgrading multiple patch releases at
once.

When you start the second post-deployment migration, delete the
previously batched migration with the provided code:

```ruby
Gitlab::Database::BackgroundMigration::BatchedMigration
  .for_configuration(MIGRATION_NAME, TABLE_NAME, COLUMN, JOB_ARGUMENTS)
  .delete_all
```

## Cleaning up

NOTE:
Cleaning up any remaining background migrations must be done in either a major
or minor release. You must not do this in a patch release.

Because background migrations can take a long time, you can't immediately clean
things up after queueing them. For example, you can't drop a column used in the
migration process, as jobs would fail. You must add a separate _post-deployment_
migration in a future release that finishes any remaining
jobs before cleaning things up. (For example, removing a column.)

To migrate the data from column `foo` (containing a big JSON blob) to column `bar`
(containing a string), you would:

1. Release A:
   1. Create a migration class that performs the migration for a row with a given ID.
   1. Update new rows using one of these techniques:
      - Create a new trigger for simple copy operations that don't need application logic.
      - Handle this operation in the model/service as the records are created or updated.
      - Create a new custom background job that updates the records.
   1. Queue the batched background migration for all existing rows in a post-deployment migration.
1. Release B:
   1. Add a post-deployment migration that checks if the batched background migration is completed.
   1. Deploy code so that the application starts using the new column and stops to update new records.
   1. Remove the old column.

Bump to the [import/export version](../user/project/settings/import_export.md) may
be required, if importing a project from a prior version of GitLab requires the
data to be in the new format.

## Example

The table `integrations` has a field called `properties`, stored in JSON. For all rows,
extract the `url` key from this JSON object and store it in the `integrations.url`
column. Millions of integrations exist, and parsing JSON is slow, so you can't
do this work in a regular migration.

1. Start by defining our migration class:

   ```ruby
   class Gitlab::BackgroundMigration::ExtractIntegrationsUrl
     class Integration < ActiveRecord::Base
       self.table_name = 'integrations'
     end

     def perform(start_id, end_id)
       Integration.where(id: start_id..end_id).each do |integration|
         json = JSON.load(integration.properties)

         integration.update(url: json['url']) if json['url']
       rescue JSON::ParserError
         # If the JSON is invalid we don't want to keep the job around forever,
         # instead we'll just leave the "url" field to whatever the default value
         # is.
         next
       end
     end
   end
   ```

   NOTE:
   To get a `connection` in the batched background migration,use an inheritance
   relation using the following base class `Gitlab::BackgroundMigration::BaseJob`.
   For example: `class Gitlab::BackgroundMigration::ExtractIntegrationsUrl < Gitlab::BackgroundMigration::BaseJob`

1. Add a new trigger to the database to update newly created and updated integrations,
   similar to this example:

   ```ruby
   execute(<<~SQL)
     CREATE OR REPLACE FUNCTION example() RETURNS trigger
     LANGUAGE plpgsql
     AS $$
     BEGIN
       NEW."url" := NEW.properties -> "url"
       RETURN NEW;
     END;
     $$;
   SQL
   ```

1. Create a post-deployment migration that queues the migration for existing data:

   ```ruby
   class QueueExtractIntegrationsUrl < Gitlab::Database::Migration[1.0]
     disable_ddl_transaction!

     MIGRATION = 'ExtractIntegrationsUrl'
     DELAY_INTERVAL = 2.minutes

     def up
       queue_batched_background_migration(
         MIGRATION,
         :migrations,
         :id,
         job_interval: DELAY_INTERVAL
       )
     end

     def down
       Gitlab::Database::BackgroundMigration::BatchedMigration
         .for_configuration(MIGRATION, :migrations, :id, []).delete_all
     end
   end
   ```

   After deployment, our application:
   - Continues using the data as before.
   - Ensures that both existing and new data are migrated.

1. In the next release, remove the trigger. We must also add a new post-deployment migration
   that checks that the batched background migration is completed. For example:

   ```ruby
   class FinalizeExtractIntegrationsUrlJobs < Gitlab::Database::Migration[1.0]
     MIGRATION = 'ExtractIntegrationsUrl'
     disable_ddl_transaction!

     def up
       ensure_batched_background_migration_is_finished(
         job_class_name: MIGRATION,
         table_name: :integrations,
         column_name: :id,
         job_arguments: []
       )
     end

     def down
       # no-op
     end
   end
   ```

   If the application does not depend on the data being 100% migrated (for
   instance, the data is advisory, and not mission-critical), then you can skip this
   final step. This step confirms that the migration is completed, and all of the rows were migrated.

After the batched migration is completed, you can safely remove the `integrations.properties` column.

## Testing

Writing tests is required for:

- The batched background migrations' queueing migration.
- The batched background migration itself.
- A cleanup migration.

The `:migration` and `schema: :latest` RSpec tags are automatically set for
background migration specs. Refer to the
[Testing Rails migrations](testing_guide/testing_migrations_guide.md#testing-a-non-activerecordmigration-class)
style guide.

Remember that `before` and `after` RSpec hooks
migrate your database down and up. These hooks can result in other batched background
migrations being called. Using `spy` test doubles with
`have_received` is encouraged, instead of using regular test doubles, because
your expectations defined in a `it` block can conflict with what is
called in RSpec hooks. Refer to [issue #35351](https://gitlab.com/gitlab-org/gitlab/-/issues/18839)
for more details.

## Best practices

1. Know how much data you're dealing with.
1. Make sure the batched background migration jobs are idempotent.
1. Confirm the tests you write are not false positives.
1. If the data being migrated is critical and cannot be lost, the
   clean-up migration must also check the final state of the data before completing.
1. Discuss the numbers with a database specialist. The migration may add
   more pressure on DB than you expect. Measure on staging,
   or ask someone to measure on production.
1. Know how much time is required to run the batched background migration.

## Additional tips and strategies

### Viewing failure error logs

You can view failures in two ways:

- Via GitLab logs:
  1. After running a batched background migration, if any jobs fail,
     view the logs in [Kibana](https://log.gprd.gitlab.net/goto/5f06a57f768c6025e1c65aefb4075694).
     View the production Sidekiq log and filter for:

     - `json.new_state: failed`
     - `json.job_class_name: <Batched Background Migration job class name>`
     - `json.job_arguments: <Batched Background Migration job class arguments>`

  1. Review the `json.exception_class` and `json.exception_message` values to help
     understand why the jobs failed.

  1. Remember the retry mechanism. Having a failure does not mean the job failed.
     Always check the last status of the job.

- Via database:

  1. Get the batched background migration `CLASS_NAME`.
  1. Execute the following query in the PostgreSQL console:

     ```sql
      SELECT migration.id, migration.job_class_name, transition_logs.exception_class, transition_logs.exception_message
      FROM batched_background_migrations as migration
      INNER JOIN batched_background_migration_jobs as jobs
      ON jobs.batched_background_migration_id = migration.id
      INNER JOIN batched_background_migration_job_transition_logs as transition_logs
      ON transition_logs.batched_background_migration_job_id = jobs.id
      WHERE transition_logs.next_status = '2' AND migration.job_class_name = "CLASS_NAME";
     ```
