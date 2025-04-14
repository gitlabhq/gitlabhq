---
stage: Foundations
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Advanced search development tips
---

## Kibana

Use Kibana to interact with your Elasticsearch cluster.

See the [download instructions](https://www.elastic.co/guide/en/kibana/8.11/install.html).

## Viewing index status

Run

```shell
bundle exec rake gitlab:elastic:info
```

to see the status and information about your cluster.

## Creating all indices from scratch and populating with local data

### Option 1: Rake task

Run

```shell
bundle exec rake gitlab:elastic:index
```

which triggers `Search::Elastic::TriggerIndexingWorker` to run async.

Run

```ruby
Elastic::ProcessInitialBookkeepingService.new.execute
```

until it shows `[0, 0]` meaning there are no more refs in the queue.

### Option 2: manual

Manually execute the steps in `Search::Elastic::TriggerIndexingWorker`.

Sometimes Sidekiq doesn't pick up jobs correctly, so you might need to restart Sidekiq or if you prefer to run through the steps in a Rails console:

```ruby
task_executor_service = Search::RakeTaskExecutorService.new(logger: ::Gitlab::Elasticsearch::Logger.build)
task_executor_service.execute(:recreate_index)
task_executor_service.execute(:clear_index_status)
task_executor_service.execute(:clear_reindex_status)
task_executor_service.execute(:resume_indexing)
task_executor_service.execute(:index_namespaces)
task_executor_service.execute(:index_projects)
task_executor_service.execute(:index_snippets)
task_executor_service.execute(:index_users)
```

Run

```ruby
Elastic::ProcessInitialBookkeepingService.new.execute
```

until it shows `[0, 0]` meaning there are no more refs in the queue.

### Option 3: reindexing task

First delete the existing index, then create a `ReindexingTask` for the index you want to target. This creates a new index based on the current configuration, then copies the data over.

```ruby
Search::Elastic::ReindexingTask.create!(targets: %w[MergeRequest])
```

Run

```ruby
ElasticClusterReindexingCronWorker.new.perform
```

On repeat until

```ruby
Search::Elastic::ReindexingTask.last.state
```

is `success`.

## Index data

To add and index database records, call the `track!` method and execute the book keeper:

```ruby
Elastic::ProcessBookkeepingService.track!(MergeRequest.first)
Elastic::ProcessBookkeepingService.track!(*MergeRequest.all)

Elastic::ProcessBookkeepingService.new.execute
```

## Testing

{{< alert type="warning" >}}

Elasticsearch tests do not run on every merge request. Add `~pipeline:run-search-tests` or `~group::global search` labels to the merge
request to run tests with the production versions of Elasticsearch and PostgreSQL. 

{{< /alert >}}

### Advanced search migrations

#### Testing a migration that changes a mapping of an index

1. Make sure the index doesn't already have the changes applied. Remember the migration cron worker runs in the background so it's possible the migration was already applied.
   - You can consider disabling the migration worker to have more control: `Feature.disable(:elastic_migration_worker)`.
   - See if the migration is pending: `::Elastic::DataMigrationService.pending_migrations`.
   - Check that the migration is not completed: `Elastic::DataMigrationService.pending_migrations.first.completed?`.
   - Make sure the mappings aren't already applied by checking in Kibana: `GET gitlab-development-some-index/_mapping`.
1. Tail the logs to see logged messages: `tail -f log/elasticsearch.log`.
1. Execute the migration in one of the following ways:
   - Run the migration worker: `Elastic::MigrationWorker.new.perform` (remember the flag should be enabled).
   - Use pending migrations: `::Elastic::DataMigrationService.pending_migrations.first.migrate`.
   - Use the version: `Elastic::DataMigrationService[20250220214819].migrate`, replacing the version with the migration version.
1. View the status of the migration.
   - View the migration record in Kibana: `GET gitlab-development-migrations/_doc/20250220214819` (changing the version). This contains information like when it started and what the status is.
   - See if the mappings are changed in Kibana: `GET gitlab-development-some-index/_mapping`.
