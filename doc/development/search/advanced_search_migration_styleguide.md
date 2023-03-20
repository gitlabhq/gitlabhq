---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Advanced search migration style guide

## Creating a new advanced search migration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/234046) in GitLab 13.6.

NOTE:
This functionality is only supported for indices created in GitLab 13.0 and later.

In the [`ee/elastic/migrate/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/elastic/migrate) folder, create a new file with the filename format `YYYYMMDDHHMMSS_migration_name.rb`. This format is the same for Rails database migrations.

```ruby
# frozen_string_literal: true

class MigrationName < Elastic::Migration
  # Important: Any updates to the Elastic index mappings must be replicated in the respective
  # configuration files:
  #   - `Elastic::Latest::Config`, for the main index.
  #   - `Elastic::Latest::<Type>Config`, for standalone indices.

  def migrate
  end

  # Check if the migration has completed
  # Return true if completed, otherwise return false
  def completed?
  end
end
```

Applied migrations are stored in `gitlab-#{RAILS_ENV}-migrations` index. All migrations not executed
are applied by the [`Elastic::MigrationWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic/migration_worker.rb)
cron worker sequentially.

To update Elastic index mappings, apply the configuration to the respective files:

- For the main index: [`Elastic::Latest::Config`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/elastic/latest/config.rb).
- For standalone indices: `Elastic::Latest::<Type>Config`.

Migrations can be built with a retry limit and have the ability to be [failed and marked as halted](https://gitlab.com/gitlab-org/gitlab/-/blob/66e899b6637372a4faf61cfd2f254cbdd2fb9f6d/ee/lib/elastic/migration.rb#L40).
Any data or index cleanup needed to support migration retries should be handled in the migration.

### Migration helpers

The following migration helpers are available in `ee/app/workers/concerns/elastic/`:

#### `Elastic::MigrationBackfillHelper`

Backfills a specific field in an index. In most cases, the mapping for the field should already be added.

Requires the `index_name` and `field_name` methods.

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  private

  def index_name
    Issue.__elasticsearch__.index_name
  end

  def field_name
    :schema_version
  end
end
```

#### `Elastic::MigrationUpdateMappingsHelper`

Updates a mapping in an index by calling `put_mapping` with the mapping specified.

Requires the `index_name` and `new_mappings` methods.

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Issue.__elasticsearch__.index_name
  end

  def new_mappings
    {
      schema_version: {
        type: 'short'
      }
    }
  end
end
```

#### `Elastic::MigrationRemoveFieldsHelper`

Removes specified fields from an index.

Requires the `index_name`, `document_type` methods. If there is one field to remove, add the `field_to_remove` method, otherwise add `fields_to_remove` with an array of fields.

Checks in batches if any documents that match `document_type` have the fields specified in Elasticsearch. If documents exist, uses a Painless script to perform `update_by_query`.

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationRemoveFieldsHelper

  batched!
  throttle_delay 1.minute

  private

  def index_name
    User.__elasticsearch__.index_name
  end

  def document_type
    'user'
  end

  def fields_to_remove
    %w[two_factor_enabled has_projects]
  end
end
```

The default batch size is `10_000`. You can override this value by specifying `BATCH_SIZE`:

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationRemoveFieldsHelper

  batched!
  BATCH_SIZE = 100

  ...
end
```

#### `Elastic::MigrationObsolete`

Marks a migration as obsolete when it's no longer required.

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationObsolete
end
```

#### `Elastic::MigrationHelper`

Contains methods you can use when a migration doesn't fit the previous examples.

```ruby
class MigrationName < Elastic::Migration
  include Elastic::MigrationHelper

  def migrate
  ...
  end

  def completed?
  ...
  end
end
```

### Migration options supported by the `Elastic::MigrationWorker`

[`Elastic::MigrationWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic/migration_worker.rb) supports the following migration options:

- `batched!` - Allow the migration to run in batches. If set, [`Elastic::MigrationWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic/migration_worker.rb)
  re-enqueues itself with a delay which is set using the `throttle_delay` option described below. The batching
  must be handled in the `migrate` method. This setting controls the re-enqueuing only.

- `batch_size` - Sets the number of documents modified during a `batched!` migration run. This size should be set to a value which allows the updates
  enough time to finish. This can be tuned in combination with the `throttle_delay` option described below. The batching
  must be handled in a custom `migrate` method or by using the [`Elastic::MigrationBackfillHelper`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/concerns/elastic/migration_backfill_helper.rb)
  `migrate` method which uses this setting. Default value is 1000 documents.

- `throttle_delay` - Sets the wait time in between batch runs. This time should be set high enough to allow each migration batch
  enough time to finish. Additionally, the time should be less than 5 minutes because that is how often the
  [`Elastic::MigrationWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic/migration_worker.rb)
  cron worker runs. The default value is 3 minutes.

- `pause_indexing!` - Pause indexing while the migration runs. This setting records the indexing setting before
  the migration runs and set it back to that value when the migration is completed.

- `space_requirements!` - Verify that enough free space is available in the cluster when the migration runs. This setting
  halts the migration if the storage required is not available when the migration runs. The migration must provide
  the space required in bytes by defining a `space_required_bytes` method.

- `retry_on_failure` - Enable the retry on failure feature. By default, it retries
  the migration 30 times. After it runs out of retries, the migration is marked as halted.
  To customize the number of retries, pass the `max_attempts` argument:
  `retry_on_failure max_attempts: 10`

```ruby
# frozen_string_literal: true

class BatchedMigrationName < Elastic::Migration
  # Declares a migration should be run in batches
  batched!
  throttle_delay 10.minutes
  pause_indexing!
  space_requirements!
  retry_on_failure

  # ...
end
```

### Multi-version compatibility

These advanced search migrations, like any other GitLab changes, need to support the case where
[multiple versions of the application are running at the same time](../multi_version_compatibility.md).

Depending on the order of deployment, it's possible that the migration
has started or finished and there's still a server running the application code from before the
migration. We need to take this into consideration until we can
[ensure all advanced search migrations start after the deployment has finished](https://gitlab.com/gitlab-org/gitlab/-/issues/321619).

### Reverting a migration

Because Elasticsearch does not support transactions, we always need to design our
migrations to accommodate a situation where the application
code is reverted after the migration has started or after it is finished.

For this reason we generally defer destructive actions (for example, deletions after
some data is moved) to a later merge request after the migrations have
completed successfully. To be safe, for self-managed customers we should also
defer it to another release if there is risk of important data loss.

### Best practices for advanced search migrations

Follow these best practices for best results:

- Order all migrations for each document type so that any migrations that use
  [`Elastic::MigrationUpdateMappingsHelper`](#elasticmigrationupdatemappingshelper)
  are executed before migrations that use the
  [`Elastic::MigrationBackfillHelper`](#elasticmigrationbackfillhelper). This avoids
  reindexing the same documents multiple times if all of the migrations are unapplied
  and reduces the backfill time.
- When working in batches, keep the batch size under 9,000 documents.
  The bulk indexer is set to run every minute and process a batch
  of 10,000 documents. This way, the bulk indexer has time to
  process records before another migration batch is attempted.
- To ensure that document counts are up to date, you should refresh
  the index before checking if a migration is completed.
- Add logging statements to each migration when the migration starts, when a
  completion check occurs, and when the migration is completed. These logs
  are helpful when debugging issues with migrations.
- Pause indexing if you're using any Elasticsearch Reindex API operations.
- Consider adding a retry limit if there is potential for the migration to fail.
  This ensures that migrations can be halted if an issue occurs.

## Deleting advanced search migrations in a major version upgrade

Because our advanced search migrations usually require us to support multiple
code paths for a long period of time, it's important to clean those up when we
safely can.

We choose to use GitLab major version upgrades as a safe time to remove
backwards compatibility for indices that have not been fully migrated. We
[document this in our upgrade documentation](../../update/index.md#upgrading-to-a-new-major-version).
We also choose to replace the migration code with the halted migration
and remove tests so that:

- We don't need to maintain any code that is called from our advanced search
  migrations.
- We don't waste CI time running tests for migrations that we don't support
  anymore.
- Operators who have not run this migration and who upgrade directly to the
  target version see a message prompting them to reindex from scratch.

To be extra safe, we do not delete migrations that were created in the last
minor version before the major upgrade. So, if we are upgrading to `%14.0`,
we should not delete migrations that were only added in `%13.12`. This
extra safety net allows for migrations that might
take multiple weeks to finish on GitLab.com. It would be bad if we upgraded
GitLab.com to `%14.0` before the migrations in `%13.12` were finished. Because
our deployments to GitLab.com are automated and we don't have
automated checks to prevent this, the extra precaution is warranted.
Additionally, even if we did have automated checks to prevent it, we wouldn't
actually want to hold up GitLab.com deployments on advanced search migrations,
as they may still have another week to go, and that's too long to block
deployments.

### Process for removing migrations

For every migration that was created 2 minor versions before the major version
being upgraded to, we do the following:

1. Confirm the migration has actually completed successfully for GitLab.com.
1. Replace the content of the migration with:

   ```ruby
   include Elastic::MigrationObsolete
   ```

1. Delete any spec files to support this migration.
1. Remove any logic handling backwards compatibility for this migration. You
   can find this by looking for
   `Elastic::DataMigrationService.migration_has_finished?(:migration_name_in_lowercase)`.
1. Create a merge request with these changes. Noting that we should not
   accidentally merge this before the major release is started.
