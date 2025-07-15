---
stage: AI-powered
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Advanced search migration style guide
---

## Create a new advanced search migration

{{< alert type="note" >}}

This functionality is only supported for indices created in GitLab 13.0 and later.

{{< /alert >}}

### With a script

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414674) in GitLab 16.3.

{{< /history >}}

Execute `scripts/elastic-migration` and follow the prompts to create:

- A migration file to define the migration: `ee/elastic/migrate/YYYYMMDDHHMMSS_migration_name.rb`
- A spec file to test the migration: `ee/spec/elastic/migrate/YYYYMMDDHHMMSS_migration_name_spec.rb`
- A dictionary file to identify the migration: `ee/elastic/docs/YYYYMMDDHHMMSS_migration_name.yml`

### Manually

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/234046) in GitLab 13.6.

{{< /history >}}

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

### Skipped migrations

You can skip a migration by adding a `skip_if` proc which evaluates to `true` or `false`:

```ruby
class MigrationName < Elastic::Migration
  skip_if ->() { true|false }
```

The migration is executed only if the condition is `false`. Skipped migrations will not be shown as part of pending migrations.

Skipped migrations can be marked as obsolete, but the `skip_if` condition must be kept so that these migrations are always skipped.
Once a skipped migration is obsolete, the only way to apply the change is by [recreating the index from scratch](../../integration/elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).

Update the skipped migration's documentation file with the following attributes:

```yaml
skippable: true
skip_condition: '<description>'
```

### Migrations for index settings and mappings changes

Changes to index settings and mappings are not immediately available to an existing index but are applied to newly created indices.

To apply setting changes, for example adding an analyzer, either:

- Use a [zero-downtime reindexing migration](#zero-downtime-reindex-migration)
- Add release notes to the feature issue, alerting users to apply the changes by either using [zero-downtime reindexing](../../integration/advanced_search/elasticsearch.md#zero-downtime-reindexing) or [re-create the index](../../integration/advanced_search/elasticsearch.md#index-the-instance).

To apply mapping changes, either:

- Use a [zero-downtime reindexing migration](#zero-downtime-reindex-migration).
- Use an [update mapping migration](#searchelasticmigrationupdatemappingshelper) to change the mapping for the existing index and optionally a follow-up [backfill migration](#searchelasticmigrationbackfillhelper) to ensure all documents in the index has this field populated.

#### Zero-downtime reindex migration

Creates a new index for the targeted index and copies existing documents over.

```ruby
class MigrationName < Elastic::Migration
  def migrate
    Elastic::ReindexingTask.create!(targets: %w[Issue], options: { skip_pending_migrations_check: true })
  end

  def completed?
    true
  end
end
```

### Spec support helpers

The following helper methods are available in `ElasticsearchHelpers` in `ee/spec/support/helpers/elasticsearch_helpers.rb`.
`ElasticsearchHelpers` is automatically included when using any of
the [Elasticsearch specs metadata](../testing_guide/best_practices.md#elasticsearch-specs)

#### `assert_names_in_query`

Validate that [named queries](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-bool-query.html#named-queries)
exist (`with`) or do not exist (`without`) in an Elasticsearch query.

#### `assert_fields_in_query`

Validate that an Elasticsearch query contains the specified fields.

#### `assert_named_queries`

{{< alert type="warning" >}}

This method requires sending a search request to Elasticsearch. Use `assert_names_in_query` to test
the queries generated directly.

{{< /alert >}}

Validate that a request was made to Elasticsearch with [named queries](https://www.elastic.co/guide/en/elasticsearch/reference/8.18/query-dsl-bool-query.html#named-queries)
Use `without` to validate the named query was not in the request.

#### `assert_routing_field`

Validate that a request was made to Elasticsearch
with [a specific routing](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/mapping-routing-field).

#### `ensure_elasticsearch_index!`

Runs `execute` for all `Elastic::ProcessBookkeepingService` classes and calls `refresh_index!`. This method indexes any
records that have been queued for indexing using the `track!` method.

#### `refresh_index!`

Performs an Elasticsearch index refresh on all indices (including the migrations index). This makes recent operations
performed on an index available for search.

#### `set_elasticsearch_migration_to`

Set the current migration in the migrations index to a specific migration (by name or version). The migration is
marked as completed by default and can set to pending by sending `including: false`.

#### `es_helper`

Provides an instance of `Gitlab::Elastic::Helper.default`

#### `warm_elasticsearch_migrations_cache!`

Primes the `::Elastic::DataMigrationService` migration cache by calling `migration_has_finished?` for each migration.

#### `elastic_wiki_indexer_worker_random_delay_range`

Returns a random delay between 0 and `ElasticWikiIndexerWorker::MAX_JOBS_PER_HOUR`

#### `elastic_delete_group_wiki_worker_random_delay_range`

Returns a random delay between 0 and `Search::Wiki::ElasticDeleteGroupWikiWorker::MAX_JOBS_PER_HOUR`

#### `elastic_group_association_deletion_worker_random_delay_range`

Returns a random delay between 0 and `Search::ElasticGroupAssociationDeletionWorker::MAX_JOBS_PER_HOUR`

#### `items_in_index`

Returns an array of `id` that exist in the provided index name.

### Migration helpers

The following migration helpers are available in `ee/app/workers/concerns/elastic/`:

#### `Search::Elastic::MigrationBackfillHelper`

Backfills a specific field in an index.

Requirements:

- The mapping for the field should already be added
- The field must always have a value. If the field can be null, use `Search::Elastic::MigrationReindexBasedOnSchemaVersion`
- For single fields, define `field_name` method and `DOCUMENT_TYPE` constant
- For multiple fields, define`field_names` method and `DOCUMENT_TYPE` constant

Single field example:

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationBackfillHelper

  DOCUMENT_TYPE = Issue

  private

  def field_name
    :schema_version
  end
end
```

Multiple fields example:

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationBackfillHelper

  DOCUMENT_TYPE = Issue

  private

  def field_names
    %w[schema_version visibility_level]
  end
end
```

You can test this migration with the `'migration backfills fields'` shared examples.

```ruby
describe 'migration', :elastic_delete_by_query, :sidekiq_inline do
  include_examples 'migration backfills fields' do
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
    let(:objects) { create_list(:issues, 3) }
    let(:expected_fields) { schema_version: '25_09' }
  end
end
```

#### `Search::Elastic::MigrationUpdateMappingsHelper`

Updates a mapping in an index by calling `put_mapping` with the mapping specified.

Requires the `new_mappings` method and `DOCUMENT_TYPE` constant.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationUpdateMappingsHelper

  DOCUMENT_TYPE = Issue

  private

  def new_mappings
    {
      schema_version: {
        type: 'short'
      }
    }
  end
end
```

You can test this migration with the `'migration adds mapping'` shared examples.

```ruby
describe 'migration', :elastic, :sidekiq_inline do
  include_examples 'migration adds mapping'
end
```

#### `Search::Elastic::MigrationRemoveFieldsHelper`

Removes specified fields from an index.

Requires the `index_name` method and `DOCUMENT_TYPE` constant. If there is one field to remove, add the `field_to_remove` method, otherwise add `fields_to_remove` with an array of fields.

Checks in batches if any documents that match `document_type` have the fields specified in Elasticsearch. If documents exist, uses a Painless script to perform `update_by_query`.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationRemoveFieldsHelper

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
  include ::Search::Elastic::MigrationRemoveFieldsHelper

  batched!
  BATCH_SIZE = 100

  ...
end
```

You can test this migration with the `'migration removes field'` shared examples.

```ruby
include_examples 'migration removes field' do
  let(:expected_throttle_delay) { 1.minute }
  let(:objects) { create_list(:work_item, 6) }
  let(:index_name) { ::Search::Elastic::Types::WorkItem.index_name }
  let(:field) { :correct_work_item_type_id }
  let(:type) { 'long' }
end
```

If the mapping contains more than a `type`, omit the `type` variable and define `mapping` instead:

```ruby
include_examples 'migration removes field' do
  let(:expected_throttle_delay) { 1.minute }
  let(:objects) { create_list(:work_item, 6) }
  let(:index_name) { ::Search::Elastic::Types::WorkItem.index_name }
  let(:field) { :embedding_0 }
  let(:mapping) { { type: 'dense_vector', dims: 768, index: true, similarity: 'cosine' } }
end
```

If you get an `expecting token of type [VALUE_NUMBER] but found [FIELD_NAME]` error, define the `value` variable:

```ruby
include_examples 'migration removes field' do
  let(:expected_throttle_delay) { 1.minute }
  let(:objects) { create_list(:work_item, 6) }
  let(:index_name) { ::Search::Elastic::Types::WorkItem.index_name }
  let(:field) { :embedding_0 }
  let(:mapping) { { type: 'dense_vector', dims: 768, index: true, similarity: 'cosine' } }
  let(:value) { Array.new(768, 1) }
end
```

#### `Search::Elastic::MigrationObsolete`

Marks a migration as obsolete when it's no longer required.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationObsolete
end
```

When marking a skippable migration as obsolete, you must keep the `skip_if` condition.

You can test this migration with the `'a deprecated Advanced Search migration'`
shared examples. Follow the [process for marking migrations as obsolete](#process-for-marking-migrations-as-obsolete).

#### `Search::Elastic::MigrationCreateIndexHelper`

Creates a new index.

Requires:

- The `target_class` and `document_type` methods
- Mappings and index settings for the class

{{< alert type="warning" >}}

You must perform a follow-up migration to populate the index in the same milestone.

{{< /alert >}}

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationCreateIndexHelper

  retry_on_failure

  def document_type
    :epic
  end

  def target_class
    Epic
  end
end
```

You can test this migration with the `'migration creates a new index'` shared examples.

```ruby
it_behaves_like 'migration creates a new index', 20240501134252, WorkItem
```

#### `Search::Elastic::MigrationReindexTaskHelper`

Creates a reindex task which creates a new index and copies data over to the new index.

Requires:

- The `targets` method.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationReindexTaskHelper

  def targets
    %w[MergeRequest]
  end
end
```

You can test this migration with the following specs.

```ruby
let(:migration) { described_class.new(version) }
let(:task) { Search::Elastic::ReindexingTask.last }
let(:targets) { %w[MergeRequest] }

it 'does not have migration options set', :aggregate_failures do
  expect(migration).not_to be_batched
  expect(migration).not_to be_retry_on_failure
end

describe '#migrate', :aggregate_failures do
  it 'creates reindexing task with correct target and options' do
    expect { migration.migrate }.to change { Search::Elastic::ReindexingTask.count }.by(1)
    expect(task.targets).to eq(targets)
    expect(task.options).to eq('skip_pending_migrations_check' => true)
  end
end

describe '#completed?' do
  it 'always returns true' do
    expect(migration.completed?).to be(true)
  end
end
```

#### `Search::Elastic::MigrationReindexBasedOnSchemaVersion`

Reindexes all documents in the index that stores the specified document type and updates `schema_version`.

Requires the `DOCUMENT_TYPE` and `NEW_SCHEMA_VERSION` constants.
The index mapping must have a `schema_version` integer field in a `YYWW` (year/week) format.

{{< alert type="note" >}}

Previously index mapping `schema_version` used `YYMM` format. New versions should use the `YYWW` format.

{{< /alert >}}

```ruby
class MigrationName < Elastic::Migration
  include Search::Elastic::MigrationReindexBasedOnSchemaVersion

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = WorkItem
  NEW_SCHEMA_VERSION = 24_46
  UPDATE_BATCH_SIZE = 100
end
```

You can test this migration with the `'migration reindex based on schema_version'` shared examples.

```ruby
include_examples 'migration reindex based on schema_version' do
  let(:expected_throttle_delay) { 1.minute }
  let(:expected_batch_size) { 9_000 }
  let(:objects) { create_list(:project, 3) }
end
```

#### `Search::Elastic::MigrationDeleteBasedOnSchemaVersion`

Deletes all documents in the index that stores the specified document type and has `schema_version` less than the given value.

Requires the `DOCUMENT_TYPE` constant and `schema_version` method.
The index mapping must have a `schema_version` integer field in a `YYWW` (year/week) format.

{{< alert type="note" >}}

Previously index mapping `schema_version` used `YYMM` format. New versions should use the `YYWW` format.

{{< /alert >}}

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationDeleteBasedOnSchemaVersion

  DOCUMENT_TYPE = Issue

  batch_size 10_000
  batched!
  throttle_delay 1.minute
  retry_on_failure

  def schema_version
    23_12
  end
end
```

You can test this migration with the `'migration deletes documents based on schema version'` shared examples.

```ruby
include_examples 'migration deletes documents based on schema version' do
  let(:objects) { create_list(:issue, 3) }
  let(:expected_throttle_delay) { 1.minute }
  let(:expected_batch_size) { 20000 }
end
```

#### `Search::Elastic::MigrationDatabaseBackfillHelper`

Reindexes all documents in the database to the elastic search index respecting the `limited_indexing` setting.

Requires the `DOCUMENT_TYPE` constant and `respect_limited_indexing?` method.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationDatabaseBackfillHelper

  batch_size 10_000
  batched!
  throttle_delay 1.minute
  retry_on_failure

  DOCUMENT_TYPE = Issue

  def respect_limited_indexing?
    true
  end
end
```

#### `Search::Elastic::MigrationHelper`

Contains methods you can use when a migration doesn't fit the previous examples.

```ruby
class MigrationName < Elastic::Migration
  include ::Search::Elastic::MigrationHelper

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
  must be handled in a custom `migrate` method or by using the [`Search::Elastic::MigrationBackfillHelper`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/concerns/elastic/migration_backfill_helper.rb)
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

## Avoiding downtime in migrations

### Reverting a migration

If a migration fails or is halted on GitLab.com, we prefer to revert the change that introduced the migration. This
prevents self-managed customers from receiving a broken migration and reduces the need for backports.

### When to merge

We prefer not to merge migrations within 1 week of the release. This allows time for a revert if a migration fails or
doesn't work as expected. Migrations still in development or review during the final week of the release should be pushed
to the next milestone.

### Multi-version compatibility

Advanced search migrations, like any other GitLab changes, need to support the case where
[multiple versions of the application are running at the same time](../multi_version_compatibility.md).

Depending on the order of deployment, it's possible that the migration
has started or finished and there's still a server running the application code from before the
migration. We need to take this into consideration until we can
[ensure all advanced search migrations start after the deployment has finished](https://gitlab.com/gitlab-org/gitlab/-/issues/321619).

### High risk migrations

Because Elasticsearch does not support transactions, we always need to design our
migrations to accommodate a situation where the application
code is reverted after the migration has started or after it is finished.

For this reason we generally defer destructive actions (for example, deletions after
some data is moved) to a later merge request after the migrations have
completed successfully. To be safe, for self-managed customers we should also
defer it to another release if there is risk of important data loss.

## Calculating migration runtime

It's important to understand how long a migration might take to run on GitLab.com. Derive the number of documents that
will be processed by the migration. This number may come from querying the database or an existing Elasticsearch index.
Use the following formula to calculate the runtime:

```ruby
> batch_size = 9_000
=> 9000
> throttle_delay = 1.minute
=> 1 minute
> number_of_documents = 15_536_906
=> 15536906
> (number_of_documents / batch_size) * throttle_delay
=> 1726 minutes
> (number_of_documents / batch_size) * throttle_delay / 1.hour
=> 28
```

## Best practices for advanced search migrations

Follow these best practices for best results:

- Order all migrations for each document type so that any migrations that use
  [`Search::Elastic::MigrationUpdateMappingsHelper`](#searchelasticmigrationupdatemappingshelper)
  are executed before migrations that use the
  [`Search::Elastic::MigrationBackfillHelper`](#searchelasticmigrationbackfillhelper). This avoids
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

## Cleaning up advanced search migrations

Because advanced search migrations usually require us to support multiple
code paths for a long period of time, it's important to clean those up when we
safely can.

We choose to use GitLab [required stops](../database/required_stops.md) as a safe time to remove
backwards compatibility for indices that have not been fully migrated. We
[document this in our upgrade documentation](../../update/plan_your_upgrade.md).

[GitLab Housekeeper](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-housekeeper/README.md)
is used to automate the cleanup process. This process includes
marking existing migrations as obsolete and deleting obsolete migrations.
When a migration is marked as obsolete, the migration code is replaced with
obsolete migration code and tests are replaced with obsolete migration shared
examples so that:

- We don't need to maintain any code that is called from our advanced search
  migrations.
- We don't waste CI time running tests for migrations that we don't support
  anymore.
- Operators who have not run this migration and who upgrade directly to the
  target version see a message prompting them to reindex from scratch.

To be extra safe, we do not clean up migrations that were created in the last
minor version before the last required stop. For example, if the last required stop
was `%14.0`, we should not clean up migrations that were only added in `%13.12`.
This extra safety net allows for migrations that might take multiple weeks to
finish on GitLab.com. Because our deployments to GitLab.com
are automated and we do not have automated checks to prevent this cleanup,
the extra precaution is warranted.
Additionally, even if we did have automated checks to prevent it, we wouldn't
actually want to hold up GitLab.com deployments on advanced search migrations,
as they may still have another week to go, and that's too long to block
deployments.

### Process for marking migrations as obsolete

Run the [`Keeps::MarkOldAdvancedSearchMigrationsAsObsolete` Keep](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-housekeeper/README.md#running-for-real)
manually to mark migrations as obsolete.

For every migration that was created two versions before the last required stop,
the Keep:

1. Retains the content of the migration and adds a prepend to the bottom:

   ```ruby
    ClassName.prepend ::Search::Elastic::MigrationObsolete
   ```

1. Replaces the spec file content with the `'a deprecated Advanced Search migration'` shared example.
1. Randomly selects a Global Search backend engineer as an assignee.
1. Updates the dictionary file to mark the migration as obsolete.

The MR assignee must:

1. Ensure the dictionary file has the correct `marked_obsolete_by_url` and `marked_obsolete_in_milestone`.
1. Verify that no references to the migration or spec files exist in the `.rubocop_todo/` directory.
1. Remove any logic-handling backwards compatibility for this migration by
   looking for `Elastic::DataMigrationService.migration_has_finished?(:migration_name_in_lowercase)`.
1. Push any required changes to the merge request.

### Process for removing obsolete migrations

Run the [`Keeps::DeleteObsoleteAdvancedSearchMigrations` Keep](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-housekeeper/README.md#running-for-real)
manually to remove obsolete migrations and specs. The Keep removes all but the most
recent obsolete migration.

1. Select obsolete migrations that were marked as obsolete before the last required stop.
1. If the first step includes all obsolete migrations, keep one obsolete migration as a safeguard for customers with unapplied migrations.
1. Delete migration files and spec files for those migrations.
1. Create a merge request and assign it to a Global Search team member.

The MR assignee must:

1. Backup migrations from the default branch to the [migration graveyard](https://gitlab.com/gitlab-org/search-team/migration-graveyard)
1. Verify that no references to the migration or spec files exist in the `.rubocop_todo/` directory.
1. Push any required changes to the merge request.

## ChatOps commands for monitoring migrations

You can check migration status from Slack (or any ChatOps‑enabled channel) at any time:

```plaintext
/chatops run search_migrations --help
/chatops run search_migrations list
/chatops run search_migrations get MigrationName
/chatops run search_migrations get VersionNumber
```

The above uses the [search_migrations](https://gitlab.com/gitlab-com/chatops/-/blob/master/lib/chatops/commands/search_migrations.rb) ChatOps plugin to fetch current migration state.
