---
stage: AI-powered
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

## Dependent association index updates

You can use elastic_index_dependant_association to automatically update associated records in the index
when specific fields change. For example, to reindex all work items when a project's `visibility_level` changes

```ruby
  elastic_index_dependant_association :work_items, on_change: :visibility_level, depends_on_finished_migration: :add_mapping_migration
```

The `depends_on_finished_migration` parameter is optional and ensures the update only occurs after the specified advanced
search migration has completed (such as a migration that added the necessary field to the mapping).

## Testing

{{< alert type="warning" >}}

Elasticsearch tests do not run on every merge request. Add `~pipeline:run-search-tests` or `~group::global search` labels to the merge
request to run tests with the production versions of Elasticsearch and PostgreSQL.

{{< /alert >}}

### Advanced search migrations

#### Testing a migration that changes a mapping of an index

1. Make sure the index doesn't already have the changes applied. Remember the migration cron worker runs in the background so it's possible the migration was already applied.
   - Optional. [In GitLab 18.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/352424),
     to disable the migration worker, run the following commands:

     ```ruby
       settings = ApplicationSetting.last # Ensure this setting does not return `nil`
       settings.elastic_migration_worker_enabled = false
       settings.save!
     ```

   - See if the migration is pending: `::Elastic::DataMigrationService.pending_migrations`.
   - Check that the migration is not completed: `Elastic::DataMigrationService.pending_migrations.first.completed?`.
   - Make sure the mappings aren't already applied
      - either by checking in Kibana `GET gitlab-development-some-index/_mapping`
      - or sending a curl request `curl "http://localhost:9200/gitlab-development-some-index/_mappings" | jq`
1. Tail the logs to see logged messages: `tail -f log/elasticsearch.log`.
1. Execute the migration in one of the following ways:
   - Run the `Elastic::MigrationWorker.new.perform` migration worker.
     [In GitLab 18.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/352424), the `elastic_migration_worker_enabled` application setting must be enabled.
   - Use pending migrations: `::Elastic::DataMigrationService.pending_migrations.first.migrate`.
   - Use the version: `Elastic::DataMigrationService[20250220214819].migrate`, replacing the version with the migration version.
1. View the status of the migration.
   - View the migration record in Kibana: `GET gitlab-development-migrations/_doc/20250220214819` (changing the version). This contains information like when it started and what the status is.
   - See if the mappings are changed in Kibana: `GET gitlab-development-some-index/_mapping`.

## Analyze query changes

Developers can use the [GitLab staging rails console](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/teleport/Connect_to_Rails_Console_via_Teleport.md) to help in code reviews to compare before and after queries.

On the Rails console we can use the `Gitlab::Search::Client` to construct the queries.

An example query using the helper looks like:

```ruby
  Gitlab::Search::Client.new.search(
    index: 'gitlab-production-vulnerabilities',
    routing: 'group_110', # data is distributed across shards and the query builder passes routing information.
    body: {
      query: {
        term: { vulnerability_id: 4356 }
      }
    }
  )
```
