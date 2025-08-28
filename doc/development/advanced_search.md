---
stage: AI-powered
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Advanced search development guidelines
---

This page includes information about developing and working with Advanced search, which is powered by Elasticsearch.

Information on how to enable Advanced search and perform the initial indexing is in
the [Elasticsearch integration documentation](../integration/advanced_search/elasticsearch.md#enable-advanced-search).

## Deep dive resources

These recordings and presentations provide in-depth knowledge about the Advanced search implementation:

|    Date     | Topic                                                                                                     |    Presenter     | Resources                                                                                                                                                                                                                                                                                                                                                                   | GitLab Version |
|:-----------:|-----------------------------------------------------------------------------------------------------------|:----------------:|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------:|
|  July 2024  | Advanced search basics, integration, indexing, and search                                                 |    Terri Chu     | <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[Recording on YouTube](https://youtu.be/5OXK1isDaks) (GitLab team members only)<br>[Google slides](https://docs.google.com/presentation/d/1Fy3pfFIGK_2ZCoB93EksRKhaS7uuNp81I3L5_joWa04/edit?usp=sharing_) (GitLab team members only)                                                                          |  GitLab 17.0   |
|  June 2021  | GitLabs data migration process for Advanced search                                                       |   Dmitry Gruzd   | [Blog post](https://about.gitlab.com/blog/2021/06/01/advanced-search-data-migrations/)                                                                                                                                                                                                                                                                                      |     GitLab 13.12      |
| August 2020 | [GitLab-specific architecture for multi-indices support](#zero-downtime-reindexing-with-multiple-indices) |    Mark Chao     | [Recording on YouTube](https://www.youtube.com/watch?v=0WdPR9oB2fg)<br>[Google slides](https://lulalala.gitlab.io/gitlab-elasticsearch-deepdive/)                                                                                                                                                                                                                           |  GitLab 13.3   |
|  June 2019  | GitLab [Elasticsearch integration](../integration/advanced_search/elasticsearch.md)                       | Mario de la Ossa | <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[Recording on YouTube](https://www.youtube.com/watch?v=vrvl-tN2EaA)<br>[Google slides](https://docs.google.com/presentation/d/1H-pCzI_LNrgrL5pJAIQgvLX8Ji0-jIKOg1QeJQzChug/edit)<br>[PDF](https://gitlab.com/gitlab-org/create-stage/uploads/c5aa32b6b07476fa8b597004899ec538/Elasticsearch_Deep_Dive.pdf) |  GitLab 12.0   |

## Elasticsearch configuration

### Supported versions

See [Version Requirements](../integration/advanced_search/elasticsearch.md#version-requirements).

Developers making significant changes to Elasticsearch queries should test their features against all our supported versions.

### Setting up your development environment

- See the [Elasticsearch GDK setup instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/elasticsearch.md)

- Ensure [Elasticsearch is running](#setting-up-your-development-environment):

  ```shell
  curl "http://localhost:9200"
  ```

<!-- vale gitlab_base.Spelling = NO -->

- [Run Kibana](https://www.elastic.co/guide/en/kibana/current/install.html#_install_kibana_yourself) to interact
  with your local Elasticsearch cluster. Alternatively, you can use [Cerebro](https://github.com/lmenezes/cerebro) or a
  similar tool.

<!-- vale gitlab_base.Spelling = YES -->

- To tail the logs for Elasticsearch, run this command:

  ```shell
  tail -f log/elasticsearch.log
  ```

### Helpful Rake tasks

- `gitlab:elastic:test:index_size`: Tells you how much space the current index is using, as well as how many documents
  are in the index.
- `gitlab:elastic:test:index_size_change`: Outputs index size, reindexes, and outputs index size again. Useful when
  testing improvements to indexing size.

Additionally, if you need large repositories or multiple forks for testing,
consider [following these instructions](rake_tasks.md#extra-project-seed-options)

## Development workflow

### Development tips

- [Creating indices from scratch](advanced_search/tips.md#creating-all-indices-from-scratch-and-populating-with-local-data)
- [Index data](advanced_search/tips.md#index-data)
- [Updating dependent associations in the index](advanced_search/tips.md#dependent-association-index-updates)
- [Kibana](advanced_search/tips.md#kibana)
- [Running tests with Elasticsearch](advanced_search/tips.md#testing)
- [Testing migrations](advanced_search/tips.md#advanced-search-migrations)
- [Viewing index status](advanced_search/tips.md#viewing-index-status)

### Debugging & troubleshooting

#### Debugging Elasticsearch queries

The `ELASTIC_CLIENT_DEBUG` environment variable enables
the [debug option for the Elasticsearch client](https://gitlab.com/gitlab-org/gitlab/-/blob/76bd885119795096611cb94e364149d1ef006fef/ee/lib/gitlab/elastic/client.rb#L50)
in development or test environments. If you need to debug Elasticsearch HTTP queries generated from
code or tests, it can be enabled before running specs or starting the Rails console:

```console
ELASTIC_CLIENT_DEBUG=1 bundle exec rspec ee/spec/workers/search/elastic/trigger_indexing_worker_spec.rb

export ELASTIC_CLIENT_DEBUG=1
rails console
```

#### Getting `flood stage disk watermark [95%] exceeded`

You might get an error such as

```plaintext
[2018-10-31T15:54:19,762][WARN ][o.e.c.r.a.DiskThresholdMonitor] [pval5Ct]
   flood stage disk watermark [95%] exceeded on
   [pval5Ct7SieH90t5MykM5w][pval5Ct][/usr/local/var/lib/elasticsearch/nodes/0] free: 56.2gb[3%],
   all indices on this node will be marked read-only
```

This is because you've exceeded the disk space threshold - it thinks you don't have enough disk space left, based on the
default 95% threshold.

In addition, the `read_only_allow_delete` setting will be set to `true`. It will block indexing, `forcemerge`, etc

```shell
curl "http://localhost:9200/gitlab-development/_settings?pretty"
```

Add this to your `elasticsearch.yml` file:

```yaml
# turn off the disk allocator
cluster.routing.allocation.disk.threshold_enabled: false
```

_or_

```yaml
# set your own limits
cluster.routing.allocation.disk.threshold_enabled: true
cluster.routing.allocation.disk.watermark.flood_stage: 5gb   # ES 6.x only
cluster.routing.allocation.disk.watermark.low: 15gb
cluster.routing.allocation.disk.watermark.high: 10gb
```

Restart Elasticsearch, and the `read_only_allow_delete` will clear on its own.

_from "Disk-based Shard Allocation | Elasticsearch
Reference" [5.6](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/disk-allocator.html#disk-allocator)
and [6.x](https://www.elastic.co/guide/en/elasticsearch/reference/6.7/disk-allocator.html)_

### Performance monitoring

#### Prometheus

GitLab exports [Prometheus metrics](../administration/monitoring/prometheus/gitlab_metrics.md)
relating to the number of requests and timing for all web/API requests and Sidekiq jobs,
which can help diagnose performance trends and compare how Elasticsearch timing
is impacting overall performance relative to the time spent doing other things.

##### Indexing queues

GitLab also exports [Prometheus metrics](../administration/monitoring/prometheus/gitlab_metrics.md)
for indexing queues, which can help diagnose performance bottlenecks and determine
whether your GitLab instance or Elasticsearch server can keep up with
the volume of updates.

#### Logs

All indexing happens in Sidekiq, so much of the relevant logs for the
Elasticsearch integration can be found in
[`sidekiq.log`](../administration/logs/_index.md#sidekiqlog). In particular, all
Sidekiq workers that make requests to Elasticsearch in any way will log the
number of requests and time taken querying/writing to Elasticsearch. This can
be useful to understand whether or not your cluster is keeping up with
indexing.

Searching Elasticsearch is done via ordinary web workers handling requests. Any
requests to load a page or make an API request, which then make requests to
Elasticsearch, will log the number of requests and the time taken to
[`production_json.log`](../administration/logs/_index.md#production_jsonlog). These
logs will also include the time spent on Database and Gitaly requests, which
may help to diagnose which part of the search is performing poorly.

There are additional logs specific to Elasticsearch that are sent to
[`elasticsearch.log`](../administration/logs/_index.md#elasticsearchlog)
that may contain information to help diagnose performance issues.

#### Performance Bar

Elasticsearch requests will be displayed in the
[`Performance Bar`](../administration/monitoring/performance/performance_bar.md), which can
be used both locally in development and on any deployed GitLab instance to
diagnose poor search performance. This will show the exact queries being made,
which is useful to diagnose why a search might be slow.

#### Correlation ID and `X-Opaque-Id`

Our [correlation ID](distributed_tracing.md#developer-guidelines-for-working-with-correlation-ids)
is forwarded by all requests from Rails to Elasticsearch as the
[`X-Opaque-Id`](https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html#_identifying_running_tasks)
header which allows us to track any
[tasks](https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html)
in the cluster back the request in GitLab.

## Architecture

The framework used to communicate to Elasticsearch is in the process of a refactor tracked in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/13873).

### Indexing Overview

Advanced search selectively indexes data. Each data type follows a specific indexing pipeline:

| Data type           | How is it queued                                                       | Where is it queued | Where does indexing occur                                                                                                                                                                                                                                                                                                                                   |
|---------------------|------------------------------------------------------------------------|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Database records    | Record changes through ActiveRecord callbacks and `Gitlab::EventStore` | Redis ZSET         | [`ElasticIndexInitialBulkCronWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/elastic_index_initial_bulk_cron_worker.rb), [`ElasticIndexBulkCronWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/elastic_index_bulk_cron_worker.rb) |
| Git repository data | Branch push service and default branch change worker                   | Sidekiq            | [`Search::Elastic::CommitIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/search/elastic/commit_indexer_worker.rb), [`ElasticWikiIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/elastic_wiki_indexer_worker.rb)     |
| Embeddings          | Record changes through ActiveRecord callbacks and `Gitlab::EventStore` | Redis ZSET         | [`ElasticEmbeddingBulkCronWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/search/elastic_index_embedding_bulk_cron_worker.rb)                                                                                                                                                                  |

### Indexing Components

#### External Indexer

For repository content, GitLab uses a
dedicated [indexer written in Go](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) to efficiently process
files.

#### Rails Indexing Lifecycle

1. **Initial Indexing**: Administrators trigger the first complete index via the Admin UI or a Rake task
1. **Ongoing Updates**: After initial setup, GitLab maintains index currency through:
   - Model callbacks (`after_create`, `after_update`, `after_destroy`) defined in [`/ee/app/models/concerns/elastic/application_versioned_search.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/models/concerns/elastic/application_versioned_search.rb)
   - A Redis [`ZSET`](https://redis.io/docs/latest/develop/data-types/#sorted-sets) that tracks all pending changes
   - Scheduled [Sidekiq workers](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/concerns/elastic/bulk_cron_worker.rb) that process these queues in batches using
     Elasticsearch's [Bulk Request API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)

### Search and Security

The [query builder framework](#query-builder-framework) generates search queries and handles access control logic. This
portion of the codebase requires particular attention during development and code review, as it has historically been a
source of security vulnerabilities.

The final step in returning search results is
to [redact unauthorized results](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/app/services/search_service.rb#L147)
for the current user to catch problems with the queries or race conditions.

### Migration framework

GitLabs Advanced search includes a robust migration framework that streamlines index maintenance and updates. This
system provides significant benefits:

- **Selective Reindexing**: Only updates specific document types when needed, avoiding full re-indexes
- **Automated Maintenance**: Updates proceed without requiring human intervention
- **Consistent Experience**: Provides the same migration path for both GitLab.com and GitLab Self-Managed instances

#### Framework Components

The migration system consists of:

- **Migration Runner**: A [cron worker](https://gitlab.com/gitlab-org/gitlab/-/blob/409b55d072b0008baca42dc53bda3e3dc56f588a/ee/app/workers/elastic/migration_worker.rb) that executes every 5 minutes to check for and process pending migrations.
- **Migration Files**: Similar to database migrations, these Ruby files define the migration steps with accompanying
  YAML documentation
- **Migration Status Tracking**: All migration states are stored in a dedicated Elasticsearch index
- **Migration Lifecycle States**: Each migration progresses through stages: pending → in progress → complete (or halted
  if issues arise)

#### Configuration Options

Migrations can be fine-tuned with various parameters:

- **Batching**: Control the document batch size for optimal performance
- **Throttling**: Adjust indexing speed to balance between migration speed and system load
- **Space Requirements**: Verify sufficient disk space before migrations begin to prevent interruptions
- **Skip condition**: Define a condition for skipping the migration

This framework makes index schema changes, field updates, and data migrations reliable and unobtrusive for all GitLab
installations.

### Search DSL

This section covers the Search DSL (Domain Specific Language) supported by GitLab, which is compatible with both
Elasticsearch and OpenSearch implementations.

#### Custom routing

[Custom routing](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-routing-field.html#_searching_with_custom_routing)
is used in Elasticsearch for document types. The routing format is usually `project_<project_id>` for project associated data
and `group_<root_namespace_id>` for group associated data. Routing is set during indexing and searching operations and tells
Elasticsearch what shards to put the data into. Some of the benefits and tradeoffs to using custom routing are:

- Project and group scoped searches are much faster since not all shards have to be hit.
- Routing is not used if too many shards would be hit for global and group scoped searches.
- Shard size imbalance might occur.

<!-- vale gitlab_base.Spelling = NO -->

#### Existing analyzers and tokenizers

The following analyzers and tokenizers are defined in
[`ee/lib/elastic/latest/config.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/ee/lib/elastic/latest/config.rb).

<!-- vale gitlab_base.Spelling = YES -->

##### Analyzers

###### `path_analyzer`

Used when indexing blobs' paths. Uses the `path_tokenizer` and the `lowercase` and `asciifolding` filters.

See the `path_tokenizer` explanation below for an example.

###### `sha_analyzer`

Used in blobs and commits. Uses the `sha_tokenizer` and the `lowercase` and `asciifolding` filters.

See the `sha_tokenizer` explanation later below for an example.

###### `code_analyzer`

Used when indexing a blob's filename and content. Uses the `whitespace` tokenizer
and the [`word_delimiter_graph`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-word-delimiter-graph-tokenfilter.html),
`lowercase`, and `asciifolding` filters.

The `whitespace` tokenizer was selected to have more control over how tokens are split. For example the string `Foo::bar(4)` needs to generate tokens like `Foo` and `bar(4)` to be properly searched.

See the `code` filter for an explanation on how tokens are split.

##### Tokenizers

###### `sha_tokenizer`

This is a custom tokenizer that uses the
[`edgeNGram` tokenizer](https://www.elastic.co/guide/en/elasticsearch/reference/5.5/analysis-edgengram-tokenizer.html)
to allow SHAs to be searchable by any sub-set of it (minimum of 5 chars).

Example:

`240c29dc7e` becomes:

- `240c2`
- `240c29`
- `240c29d`
- `240c29dc`
- `240c29dc7`
- `240c29dc7e`

###### `path_tokenizer`

This is a custom tokenizer that uses the
[`path_hierarchy` tokenizer](https://www.elastic.co/guide/en/elasticsearch/reference/5.5/analysis-pathhierarchy-tokenizer.html)
with `reverse: true` to allow searches to find paths no matter how much or how little of the path is given as input.

Example:

`'/some/path/application.js'` becomes:

- `'/some/path/application.js'`
- `'some/path/application.js'`
- `'path/application.js'`
- `'application.js'`

#### Common gotchas

- Searches can have their own analyzers. Remember to check when editing analyzers.
- `Character` filters (as opposed to token filters) always replace the original character. These filters can hinder exact searches.

## Implementation guide

### Add a new document type to Elasticsearch

If data cannot be added to one of the [existing indices in Elasticsearch](../integration/advanced_search/elasticsearch.md#advanced-search-index-scopes), follow these instructions to set up a new index and populate it.

#### Recommended process for adding a new document type

Have any MRs reviewed by a member of the Global Search team:

1. [Setup your development environment](#setting-up-your-development-environment)
1. [Create the index](#create-the-index).
1. [Validate expected queries](#validate-expected-queries)
1. [Create a new Elasticsearch reference](#create-a-new-elastic-reference).
1. Perform [continuous updates](#continuous-updates) behind a feature flag. Enable the flag fully before the backfill.
1. [Backfill the data](#backfilling-data).

After indexing is done, the index is ready for search.

#### Create the index

All new indexes must have:

- `project_id` and `namespace_id` fields (if available). One of the fields must be used for [custom routing](#custom-routing).
- A `traversal_ids` field for efficient global and group search. Populate the field with `object.namespace.elastic_namespace_ancestry`
- Fields for authorization:
  - For project data - `visibility_level`
  - For group data - `namespace_visibility_level`
  - Any required access level fields. These correspond to project feature access levels such as `issues_access_level` or `repository_access_level`
- A `schema_version` integer field in a `YYWW` (year/week) format. This field is used for data migrations.

1. Create a `Search::Elastic::Types::` class in `ee/lib/search/elastic/types/`.
1. Define the following class methods:
   - `index_name`: in the format `gitlab-<env>-<type>` (for example, `gitlab-production-work_items`).
   - `mappings`: a hash containing the index schema such as fields, data types, and analyzers.
   - `settings`: a hash containing the index settings such as replicas and tokenizers.
     The default is good enough for most cases.
1. Add a new [advanced search migration](search/advanced_search_migration_styleguide.md) to create the index
   by executing `scripts/elastic-migration` and following the instructions.
   The migration name must be in the format `Create<Name>Index`.
1. Use the [`Search::Elastic::MigrationCreateIndexHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationcreateindexhelper)
   helper and the `'migration creates a new index'` shared example for the specification file created.
1. Add the target class to `Gitlab::Elastic::Helper::ES_SEPARATE_CLASSES`.
1. To test the index creation, run `Elastic::MigrationWorker.new.perform` in a console and check that the index
   has been created with the correct mappings and settings:

   ```shell
   curl "http://localhost:9200/gitlab-development-<type>/_mappings" | jq .`
   ```

   ```shell
   curl "http://localhost:9200/gitlab-development-<type>/_settings" | jq .`
   ```

##### PostgreSQL to Elasticsearch mappings

Data types for primary and foreign keys must match the column type in the database. For example, the database column
type `integer` maps to `integer` and `bigint` maps to `long` in the mapping.

{{< alert type="warning" >}}

[Nested fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/nested.html#_limits_on_nested_mappings_and_objects) introduce significant overhead. A flattened multi-value approach is recommended instead.

{{< /alert >}}

| PostgreSQL type         | Elasticsearch mapping                                                                                                                                                                                                                                                                  |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| bigint                  | long                                                                                                                                                                                                                                                                                   |
| smallint                | short                                                                                                                                                                                                                                                                                  |
| integer                 | integer                                                                                                                                                                                                                                                                                |
| boolean                 | boolean                                                                                                                                                                                                                                                                                |
| array                   | keyword                                                                                                                                                                                                                                                                                |
| timestamp               | date                                                                                                                                                                                                                                                                                   |
| character varying, text | Depends on query requirements. Use [`text`](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/text) for full-text search and [`keyword`](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/keyword) for term queries, sorting, or aggregations |

##### Validate expected queries

Before creating a new index, it's crucial to validate that the planned mappings will support your expected queries.
Verifying mapping compatibility upfront helps avoid issues that would require index rebuilding later.

#### Create a new Elastic Reference

Create a `Search::Elastic::References::` class in `ee/lib/search/elastic/references/`.

The reference is used to perform bulk operations in Elasticsearch.
The file must inherit from `Search::Elastic::Reference` and define the following constant and methods:

```ruby
include Search::Elastic::Concerns::DatabaseReference # if there is a corresponding database record for every document

SCHEMA_VERSION = 24_46 # integer in YYWW format

override :serialize
def self.serialize(record)
   # a string representation of the reference
end

override :instantiate
def self.instantiate(string)
   # deserialize the string and call initialize
end

override :preload_indexing_data
def self.preload_indexing_data(refs)
   # remove this method if `Search::Elastic::Concerns::DatabaseReference` is included
   # otherwise return refs
end

def initialize
   # initialize with instance variables
end

override :identifier
def identifier
   # a way to identify the reference
end

override :routing
def routing
   # Optional: an identifier to route the document in Elasticsearch
end

override :operation
def operation
   # one of `:index`, `:upsert` or `:delete`
end

override :serialize
def serialize
   # a string representation of the reference
end

override :as_indexed_json
def as_indexed_json
   # a hash containing the document representation for this reference
end

override :index_name
def index_name
   # index name
end

def model_klass
   # set to the model class if `Search::Elastic::Concerns::DatabaseReference` is included
end
```

To add data to the index, an instance of the new reference class is called in
`Elastic::ProcessBookkeepingService.track!()` to add the data to a queue of
references for indexing.
A cron worker pulls queued references and bulk-indexes the items into Elasticsearch.

To test that the indexing operation works, call `Elastic::ProcessBookkeepingService.track!()`
with an instance of the reference class and run `Elastic::ProcessBookkeepingService.new.execute`.
The logs show the updates. To check the document in the index, run this command:

```shell
curl "http://localhost:9200/gitlab-development-<type>/_search"
```

##### Common gotchas

- Index operations actually perform an upsert. If the document exists, it performs a partial update by merging fields sent
  with the existing document fields. If you want to explicitly remove fields or set them to empty, the `as_indexed_json`
  must send `nil` or an empty array.

#### Data consistency

Now that we have an index and a way to bulk index the new document type into Elasticsearch, we need to add data into the index. This consists of doing a backfill and doing continuous updates to ensure the index data is up to date.

The backfill is done by calling `Elastic::ProcessInitialBookkeepingService.track!()` with an instance of `Search::Elastic::Reference` for every document that should be indexed.

The continuous update is done by calling `Elastic::ProcessBookkeepingService.track!()` with an instance of `Search::Elastic::Reference` for every document that should be created/updated/deleted.

##### Backfilling data

Add a new [Advanced Search migration](search/advanced_search_migration_styleguide.md) to backfill data by executing `scripts/elastic-migration` and following the instructions.

Use the [`MigrationDatabaseBackfillHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationdatabasebackfillhelper). The [`BackfillWorkItems` migration](https://gitlab.com/gitlab-org/search-team/migration-graveyard/-/blob/09354f497698037fc21f5a65e5c2d0a70edd81eb/lib/migrate/20240816132114_backfill_work_items.rb) can be used as an example.

To test the backfill, run `Elastic::MigrationWorker.new.perform` in a console a couple of times and see that the index was populated.

Tail the logs to see the progress of the migration:

```shell
tail -f log/elasticsearch.log
```

##### Continuous updates

For `ActiveRecord` objects, the `ApplicationVersionedSearch` concern can be included on the model to index data based on callbacks. If that's not suitable, call `Elastic::ProcessBookkeepingService.track!()` with an instance of `Search::Elastic::Reference` whenever a document should be indexed.

Always check for `Gitlab::CurrentSettings.elasticsearch_indexing?` and `use_elasticsearch?` because some GitLab Self-Managed instances do not have Elasticsearch enabled and [namespace limiting](../integration/advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index) can be enabled.

Also check that the index is able to handle the index request. For example, check that the index exists if it was added in the current major release by verifying that the migration to add the index was completed: `Elastic::DataMigrationService.migration_has_finished?`.

##### Transfers and deletes

Project and group transfers and deletes must make updates to the index to avoid orphaned data. Orphaned data may occur
when [custom routing](#custom-routing) changes due to a transfer. Data in the old shard must be cleaned up. Elasticsearch
updates for transfers are handled in the [`Projects::TransferService`](https://gitlab.com/gitlab-org/gitlab/-/blob/4d2a86ed035d3c2a960f5b89f2424bee990dc8ab/ee/app/services/ee/projects/transfer_service.rb)
and [`Groups::TransferService`](https://gitlab.com/gitlab-org/gitlab/-/blob/4d2a86ed035d3c2a960f5b89f2424bee990dc8ab/ee/app/services/ee/groups/transfer_service.rb).

Indexes that contain a `project_id` field must use the [`Search::Elastic::DeleteWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/ee/app/workers/search/elastic/delete_worker.rb).
Indexes that contain a `namespace_id` field and no `project_id` field must use [`Search::ElasticGroupAssociationDeletionWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/ee/app/workers/search/elastic_group_association_deletion_worker.rb).

1. Add the indexed class to `excluded_classes` in [`ElasticDeleteProjectWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/ee/app/workers/elastic_delete_project_worker.rb)
1. Create a new service in the `::Search::Elastic::Delete` namespace to delete documents from the index
1. Update the worker to use the new service

### Implementing search for a new document type

Search data is available in [`SearchController`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/controllers/search_controller.rb) and
[Search API](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/lib/api/search.rb). Both use the [`SearchService`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/services/search_service.rb) to return results.
The `SearchService` can be used to return results outside the `SearchController` and `Search API`.

#### Recommended process for implementing search for a new document type

Create the following MRs and have them reviewed by a member of the Global Search team:

1. [Enable the new scope](#search-scopes).
1. Create a [query builder](#creating-a-query).
1. Implement all [model requirements](#model-requirements).
1. [Add the new scope to `Gitlab::Elastic::SearchResults`](#results-classes) behind a feature flag.
1. Add support for the scope in [`Search::API`](https://gitlab.com/gitlab-org/gitlab/-/blob/bc063cd323323a7b27b7c9c9ddfc19591f49100c/lib/api/search.rb) (if applicable)
1. Add specs which must include [permissions tests](#permissions-tests)
1. [Test the new scope](#testing-scopes)
1. Update documentation for [Advanced search](../user/search/advanced_search.md), [Search API](../api/search.md) and,
   [Roles and permissions](../user/permissions.md) (if applicable)

#### Search scopes

The `SearchService` exposes searching at [global](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/services/search/global_service.rb),
[group](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/services/search/group_service.rb), and [project](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/services/search/project_service.rb) levels.

New scopes must be added to the following constants:

- `ALLOWED_SCOPES` (or override `allowed_scopes` method) in each EE `SearchService` file
- `ALLOWED_SCOPES` in `Gitlab::Search::AbuseDetection`
- `search_tab_ability_map` method in `Search::Navigation`. Override in the EE version if needed

{{< alert type="note" >}}

Global search can be disabled for a scope. You can do the following changes for disabling global search:

{{< /alert >}}

1. Add an application setting named `global_search_SCOPE_enabled` that defaults to `true` under the `search` jsonb accessor in [`app/models/application_setting.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/d52af9fafd5016ea25a665a9d5cb797b37a39b10/app/models/application_setting.rb#L738).
1. Add an entry in JSON schema validator file [`application_setting_search.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/d52af9fafd5016ea25a665a9d5cb797b37a39b10/app/validators/json_schemas/application_setting_search.json)
1. Add the setting checkbox in the Admin UI by creating an entry in `global_search_settings_checkboxes` method in [`ApplicationSettingsHelper`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/helpers/application_settings_helper.rb#L75`).
1. Add it to the `global_search_enabled_for_scope?` method in [`SearchService`](https://gitlab.com/gitlab-org/gitlab/-/blob/0105b56d6ad86e04ef46492dcf5537553505b678/app/services/search_service.rb#L106).
1. Remember that EE-only settings should be added in the EE versions of the files

#### Results classes

The search results class available are:

| Search type       | Search level | Class                                   |
|-------------------|--------------|-----------------------------------------|
| Basic search      | global       | `Gitlab::SearchResults`                 |
| Basic search      | group        | `Gitlab::GroupSearchResults`            |
| Basic search      | project      | `Gitlab::ProjectSearchResults`          |
| Advanced search   | global       | `Gitlab::Elastic::SearchResults`        |
| Advanced search   | group        | `Gitlab::Elastic::GroupSearchResults`   |
| Advanced search   | project      | `Gitlab::Elastic::ProjectSearchResults` |
| Exact code search | global       | `Search::Zoekt::SearchResults`          |
| Exact code search | group        | `Search::Zoekt::SearchResults`          |
| Exact code search | project      | `Search::Zoekt::SearchResults`          |
| All search types  | All levels   | `Search::EmptySearchResults`            |

The result class returns the following data:

1. `objects` - paginated from Elasticsearch transformed into database records or POROs
1. `formatted_count` - document count returned from Elasticsearch
1. `highlight_map` - map of highlighted fields from Elasticsearch
1. `failed?` - if a failure occurred
1. `error` - error message returned from Elasticsearch
1. `aggregations` - (optional) aggregations from Elasticsearch

New scopes must add support to these methods within `Gitlab::Elastic::SearchResults` class:

- `objects`
- `formatted_count`
- `highlight_map`
- `failed?`
- `error`

### Updating an existing scope

Updates may include adding and removing document fields or changes to authorization. To update an existing
scope, find the code used to generate queries and JSON for indexing.

- Queries are generated in `QueryBuilder` classes
- Indexed documents are built in `Reference` classes

We also support a legacy `Proxy` framework:

- Queries are generated in `ClassProxy` classes
- Indexed documents are built in `InstanceProxy` classes

Always aim to create new search filters in the `QueryBuilder` framework, even if they are used in the legacy framework.

#### Adding a field

##### Add the field to the index

1. Add the field to the index mapping to add it newly created indices and create a migration to add the field to existing indices in the same MR to avoid mapping schema drift. Use the [`MigrationUpdateMappingsHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationupdatemappingshelper)
1. Populate the new field in the document JSON. The code must check the migration is complete using
   `::Elastic::DataMigrationService.migration_has_finished?`
1. Bump the `SCHEMA_VERSION` for the document JSON. The format is year and week number: `YYYYWW`
1. Create a migration to backfill the field in the index. If it's a not-nullable field, use [`MigrationBackfillHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationbackfillhelper), or [`MigrationReindexBasedOnSchemaVersion`](search/advanced_search_migration_styleguide.md#searchelasticmigrationreindexbasedonschemaversion) if it's a nullable field.

##### If the new field is an associated record

1. Update specs for [`Elastic::ProcessBookkeepingService`](https://gitlab.com/gitlab-org/gitlab/blob/8ce9add3bc412a32e655322bfcd9dcc996670f82/ee/spec/services/elastic/process_bookkeeping_service_spec.rb)
   create associated records
1. Update N+1 specs for `preload_search_data` to create associated data records
1. Review [Updating dependent associations in the index](advanced_search/tips.md#dependent-association-index-updates)

##### Expose the field to the search service

1. Add the filter to the [`Search::Filter` concern](https://gitlab.com/gitlab-org/gitlab/-/blob/21bc3a986d27194c2387f4856ec1c5d5ef6fb4ff/app/services/concerns/search/filter.rb).
   The concern is used in the `Search::GlobalService`, `Search::GroupService` and `Search::ProjectService`.
1. Pass the field for the scope by updating the `scope_options` method. The method is defined in
   `Gitlab::Elastic::SearchResults` with overrides in `Gitlab::Elastic::GroupSearchResults` and
   `Gitlab::Elastic::ProjectSearchResults`.
1. Use the field in the [query builder](#creating-a-query) by adding [an existing filter](#available-filters)
   or [creating a new one](#creating-a-filter).
1. Track the filter usage in searches in the [`SearchController`](https://gitlab.com/gitlab-org/gitlab/-/blob/21bc3a986d27194c2387f4856ec1c5d5ef6fb4ff/app/controllers/search_controller.rb#L277)

#### Changing mapping of an existing field

1. Update the field type in the index mapping to change it for newly created indices
1. Bump the `SCHEMA_VERSION` for the document JSON. The format is year and week number: `YYYYWW`
1. Create a migration to reindex all documents
   using [Zero downtime reindexing](search/advanced_search_migration_styleguide.md#zero-downtime-reindex-migration).
   Use the [`Search::Elastic::MigrationReindexTaskHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationreindextaskhelper)

#### Changing field content

1. Update the field content in the document JSON
1. Bump the `SCHEMA_VERSION` for the document JSON. The format is year and week number: `YYYYWW`
1. Create a migration to update documents. Use the [`MigrationReindexBasedOnSchemaVersion`](search/advanced_search_migration_styleguide.md#searchelasticmigrationreindexbasedonschemaversion)

#### Cleaning up documents from an index

This may be used if documents are split from one index into separate indices or to remove data left in the index due to
bugs.

1. Bump the `SCHEMA_VERSION` for the document JSON. The format is year and week number: `YYYYWW`
1. Create a migration to index all records. Use the [`MigrationDatabaseBackfillHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationdatabasebackfillhelper)
1. Create a migration to remove all documents with the previous `SCHEMA_VERSION`. Use the [`MigrationDeleteBasedOnSchemaVersion`](search/advanced_search_migration_styleguide.md#searchelasticmigrationdeletebasedonschemaversion)

#### Removing a field

The removal must be split across multiple milestones to
support [multi-version compatibility](search/advanced_search_migration_styleguide.md#multi-version-compatibility).
To avoid dynamic mapping errors, the field must be removed from all documents before
a [Zero downtime reindexing](search/advanced_search_migration_styleguide.md#zero-downtime-reindex-migration).

Milestone `M`:

1. Remove the field from the index mapping to remove it from newly created indices
1. Stop populating the field in the document JSON
1. Bump the `SCHEMA_VERSION` for the document JSON. The format is year and week number: `YYYYWW`
1. Remove any [filters which use the field](#available-filters) from the [query builder](#creating-a-query)
1. Update the `scope_options` method to remove the field for the scope you are updating. The method is defined in
   `Gitlab::Elastic::SearchResults` with overrides in `Gitlab::Elastic::GroupSearchResults` and
   `Gitlab::Elastic::ProjectSearchResults`.

If the field is not used by other scopes:

1. Remove the field from the [`Search::Filter` concern](https://gitlab.com/gitlab-org/gitlab/-/blob/21bc3a986d27194c2387f4856ec1c5d5ef6fb4ff/app/services/concerns/search/filter.rb).
   The concern is used in the `Search::GlobalService`, `Search::GroupService`, and `Search::ProjectService`.
1. Remove filter tracking in searches in the [`SearchController`](https://gitlab.com/gitlab-org/gitlab/-/blob/21bc3a986d27194c2387f4856ec1c5d5ef6fb4ff/app/controllers/search_controller.rb#L277)

Milestone `M+1`:

1. Create a migration to remove the field from all documents in the index. Use the [`MigrationRemoveFieldsHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationremovefieldshelper)
1. Create a migration to reindex all documents with the field removed
   using [Zero downtime reindexing](search/advanced_search_migration_styleguide.md#zero-downtime-reindex-migration).
   Use the [`Search::Elastic::MigrationReindexTaskHelper`](search/advanced_search_migration_styleguide.md#searchelasticmigrationreindextaskhelper)

#### Updating authorization

In the `QueryBuilder` framework, authorization is handled at the project level with the
[`by_search_level_and_membership` filter](#by_search_level_and_membership) and at the group level
with the [`by_search_level_and_group_membership` filter](#by_search_level_and_group_membership).

In the legacy `Proxy` framework, the authorization is handled inside the class.

Both frameworks use `Search::GroupsFinder` and `Search::ProjectsFinder` to query the groups and projects a user
has direct access to search. Search relies upon group and project visibility level and feature access level settings
for each scope. See [roles and permissions documentation](../user/permissions.md) for more information.

## Query builder framework

The query builder framework is used to build Elasticsearch queries. We also support a legacy query framework implemented
in the `Elastic::Latest::ApplicationClassProxy` class and classes that inherit it.

{{< alert type="note" >}}

New document types must use the query builder framework.

{{< /alert >}}

### Creating a query

A query is built using:

- a query from `Search::Elastic::Queries`
- one or more filters from `::Search::Elastic::Filters`
- (optional) aggregations from `::Search::Elastic::Aggregations`
- one or more formats from `::Search::Elastic::Formats`

New scopes must create a new query builder class that inherits from `Search::Elastic::QueryBuilder`.

The query builder framework provides a collection of pre-built filters to handle common search scenarios. These filters
simplify the process of constructing complex query conditions without having to write raw Elasticsearch query DSL.

### Creating a filter

Filters are essential components in building effective Elasticsearch queries. They help narrow down search results
without affecting the relevance scoring.

- All filters must be documented.
- Filters are created as class level methods in `Search::Elastic::Filters`
- The method should start with `by_`.
- The method must take `query_hash` and `options` parameters only.
- `query_hash` is expected to contain a hash with this format.

  ```json
   { "query":
     { "bool":
       {
         "must": [],
         "must_not": [],
         "should": [],
         "filters": [],
         "minimum_should_match": null
       }
     }
   }
  ```

- Use `add_filter` to add the filter to the query hash. Filters should add to the `filters` to avoid calculating score.
  The score calculation is done by the query itself.
- Use `context.name(:filters)` around the filter to add a name to the filter. This helps identify which part of a query
  and filter have allowed a result to be returned by the search

  ```ruby
    def by_new_filter_type(query_hash:, options:)
        filter_selected_value = options[:field_value]

        context.name(:filters) do
          add_filter(query_hash, :query, :bool, :filter) do
            { term: { field_name: { _name: context.name(:field_name), value: filter_selected_value } } }
          end
        end
    end
  ```

### Understanding Queries vs Filters

Queries in Elasticsearch serve two key purposes: filtering documents and calculating relevance scores. When building
search functionality:

- **Queries** are essential when relevance scoring is required to rank results by how well they match search criteria.
  They use the Boolean query's `must`, `should`, and `must_not` clauses, all of which influence the document's final
  relevance score.

- **Filters** (within query context) determine whether documents appear in search results without affecting their score.
  For search operations where results only need to be included/excluded without ranking by relevance, using filters
  alone is more efficient and performs better at scale.

Choose the appropriate approach based on your search requirements - use queries with scoring clauses for ranked results,
and rely on filters for simple inclusion/exclusion logic.

### Filter Requirements and Usage

To use any filter:

1. The index mapping must include all required fields specified in each filter's documentation
1. Pass the appropriate parameters via the `options` hash when calling the filter
1. Each filter will generate the appropriate JSON structure and add it to your `query_hash`

Filters can be composed together to create sophisticated search queries while maintaining readable and maintainable
code.

### Sending queries to Elasticsearch

The queries are sent to `::Gitlab::Search::Client` from `Gitlab::Elastic::SearchResults`.
Results are parsed through a `Search::Elastic::ResponseMapper` to translate
the response from Elasticsearch.

#### Model requirements

The model must respond to the `to_ability_name` method so that the redaction logic can check if it has
`Ability.allowed?(current_user, :"read_#{object.to_ability_name}", object)?`. The method must be added if
it does not exist.

The model must define a `preload_search_data` scope to avoid N+1s.

### Available Queries

All query builders must return a standardized `query_hash` structure that conforms to Elasticsearch's Boolean query
syntax. The `Search::Elastic::BoolExpr` class provides an interface for constructing Boolean queries.

The required query hash structure is:

```json
{
  "query": {
    "bool": {
      "must": [],
      "must_not": [],
      "should": [],
      "filters": [],
      "minimum_should_match": null
    }
  }
}
```

#### `by_iid`

Query by `iid` field and document type. Requires `type` and `iid` fields.

```json
{
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "iid": {
              "_name": "milestone:related:iid",
              "value": 1
            }
          }
        },
        {
          "term": {
            "type": {
              "_name": "doc:is_a:milestone",
              "value": "milestone"
            }
          }
        }
      ]
    }
  }
}
```

#### `by_full_text`

Performs a full text search. This query will use `by_multi_match_query` or `by_simple_query_string` if Advanced search syntax is used in the query string.

#### `by_multi_match_query`

Uses `multi_match` Elasticsearch API. Can be customized with the following options:

- `count_only` - uses the Boolean query clause `filter`. Scoring and highlighting are not performed.
- `query` - if no query is passed, uses `match_all` Elasticsearch API
- `keyword_match_clause` - if `:should` is passed, uses the Boolean query clause `should`. Default: `must` clause

```json
{
  "query": {
    "bool": {
      "must": [
        {
          "bool": {
            "must": [],
            "must_not": [],
            "should": [
              {
                "multi_match": {
                  "_name": "project:multi_match:and:search_terms",
                  "fields": [
                    "name^10",
                    "name_with_namespace^2",
                    "path_with_namespace",
                    "path^9",
                    "description"
                  ],
                  "query": "search",
                  "operator": "and",
                  "lenient": true
                }
              },
              {
                "multi_match": {
                  "_name": "project:multi_match_phrase:search_terms",
                  "type": "phrase",
                  "fields": [
                    "name^10",
                    "name_with_namespace^2",
                    "path_with_namespace",
                    "path^9",
                    "description"
                  ],
                  "query": "search",
                  "lenient": true
                }
              }
            ],
            "filter": [],
            "minimum_should_match": 1
          }
        }
      ],
      "must_not": [],
      "should": [],
      "filter": [],
      "minimum_should_match": null
    }
  }
}
```

#### `by_simple_query_string`

Uses `simple_query_string` Elasticsearch API. Can be customized with the following options:

- `count_only` - uses the Boolean query clause `filter`. Scoring and highlighting are not performed.
- `query` - if no query is passed, uses `match_all` Elasticsearch API
- `keyword_match_clause` - if `:should` is passed, uses the Boolean query clause `should`. Default: `must` clause

```json
{
  "query": {
    "bool": {
      "must": [
        {
          "simple_query_string": {
            "_name": "project:match:search_terms",
            "fields": [
              "name^10",
              "name_with_namespace^2",
              "path_with_namespace",
              "path^9",
              "description"
            ],
            "query": "search",
            "lenient": true,
            "default_operator": "and"
          }
        }
      ],
      "must_not": [],
      "should": [],
      "filter": [],
      "minimum_should_match": null
    }
  }
}
```

#### `by_knn`

Requires options: `vectors_supported` (set to `:elasticsearch` or `:opensearch`) and `embedding_field`. Callers may optionally provide options: `embeddings`

Performs a hybrid search using embeddings. Uses `full_text_search` unless embeddings are supported.

{{< alert type="warning" >}}

Elasticsearch and OpenSearch DSL for `knn` queries is different. To support both, this query must be used with the `by_knn` filter.

{{< /alert >}}

The example below is for Elasticsearch.

```json
{
  "query": {
    "bool": {
      "must": [
        {
          "bool": {
            "must": [],
            "must_not": [],
            "should": [
              {
                "multi_match": {
                  "_name": "work_item:multi_match:and:search_terms",
                  "fields": [
                    "iid^50",
                    "title^2",
                    "description"
                  ],
                  "query": "test",
                  "operator": "and",
                  "lenient": true
                }
              },
              {
                "multi_match": {
                  "_name": "work_item:multi_match_phrase:search_terms",
                  "type": "phrase",
                  "fields": [
                    "iid^50",
                    "title^2",
                    "description"
                  ],
                  "query": "test",
                  "lenient": true
                }
              }
            ],
            "filter": [],
            "minimum_should_match": 1
          }
        }
      ],
      "must_not": [],
      "should": [],
      "filter": [],
      "minimum_should_match": null
    }
  },
  "knn": {
    "field": "embedding_0",
    "query_vector": [
      0.030752448365092278,
      -0.05360432341694832
    ],
    "boost": 5,
    "k": 25,
    "num_candidates": 100,
    "similarity": 0.6,
    "filter": []
  }
}
```

### Available Filters

The following sections detail each available filter, its required fields, supported options, and example output.

#### `by_type`

Requires `type` field. Query with `doc_type` in options.

```json
{
  "term": {
    "type": {
      "_name": "filters:doc:is_a:milestone",
      "value": "milestone"
    }
  }
}
```

#### `by_group_level_confidentiality`

Requires `current_user` and `group_ids` fields. Query based on the permissions to user to read confidential group entities.

```json
{
  "bool": {
    "must": [
      {
        "term": {
          "confidential": {
            "value": true,
            "_name": "confidential:true"
          }
        }
      },
      {
        "terms": {
          "namespace_id": [
            1
          ],
          "_name": "groups:can:read_confidential_work_items"
        }
      }
    ]
  },
  "should": {
    "term": {
      "confidential": {
        "value": false,
        "_name": "confidential:false"
      }
    }
  }
}
```

#### `by_project_confidentiality`

Requires `confidential`, `author_id`, `assignee_id`, `project_id` fields. Query with `confidential` in options.

```json
{
  "bool": {
    "should": [
      {
        "term": {
          "confidential": {
            "_name": "filters:confidentiality:projects:non_confidential",
            "value": false
          }
        }
      },
      {
        "bool": {
          "must": [
            {
              "term": {
                "confidential": {
                  "_name": "filters:confidentiality:projects:confidential",
                  "value": true
                }
              }
            },
            {
              "bool": {
                "should": [
                  {
                    "term": {
                      "author_id": {
                        "_name": "filters:confidentiality:projects:confidential:as_author",
                        "value": 1
                      }
                    }
                  },
                  {
                    "term": {
                      "assignee_id": {
                        "_name": "filters:confidentiality:projects:confidential:as_assignee",
                        "value": 1
                      }
                    }
                  },
                  {
                    "terms": {
                      "_name": "filters:confidentiality:projects:confidential:project:membership:id",
                      "project_id": [
                        12345
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    ]
  }
}
```

#### `by_combined_confidentiality`

Requires `search_level` field and at least one of `use_group_authorization` or `use_project_authorization`. Query with `confidential` in options.
This filter combines `by_project_confidentiality` and `by_group_level_confidentiality` into one query if both
`use_group_authorization` and `use_project_authorization` are provided. See those methods for required fields.

```json
[
  {
    "bool": {
      "should": [
        {
          "bool": {
            "filter": [
              {
                "bool": {
                  "should": [
                    {
                      "term": {
                        "confidential": {
                          "_name": "filters:confidentiality:projects:non_confidential",
                          "value": false
                        }
                      }
                    },
                    {
                      "bool": {
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "_name": "filters:confidentiality:projects:confidential",
                                "value": true
                              }
                            }
                          },
                          {
                            "bool": {
                              "should": [
                                {
                                  "term": {
                                    "author_id": {
                                      "_name": "filters:confidentiality:projects:confidential:as_author",
                                      "value": 278964
                                    }
                                  }
                                },
                                {
                                  "term": {
                                    "assignee_id": {
                                      "_name": "filters:confidentiality:projects:confidential:as_assignee",
                                      "value": 278964
                                    }
                                  }
                                },
                                {
                                  "terms": {
                                    "_name": "filters:confidentiality:projects:confidential:project:membership:id",
                                    "project_id": []
                                  }
                                }
                              ]
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
        },
        {
          "bool": {
            "filter": [
              {
                "bool": {
                  "should": [
                    {
                      "bool": {
                        "_name": "filters:confidentiality:groups:non_confidential:public",
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "value": false
                              }
                            }
                          },
                          {
                            "term": {
                              "namespace_visibility_level": {
                                "value": 20
                              }
                            }
                          }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "_name": "filters:confidentiality:groups:non_confidential:internal",
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "value": false
                              }
                            }
                          },
                          {
                            "term": {
                              "namespace_visibility_level": {
                                "value": 10
                              }
                            }
                          }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "_name": "filters:confidentiality:groups:non_confidential:private",
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "value": false
                              }
                            }
                          }
                        ],
                        "should": [
                          {
                            "prefix": {
                              "traversal_ids": {
                                "_name": "filters:confidentiality:groups:non_confidential:private:ancestry_filter:descendants",
                                "value": "9970-"
                              }
                            }
                          }
                        ],
                        "minimum_should_match": 1
                      }
                    },
                    {
                      "bool": {
                        "_name": "filters:confidentiality:groups:non_confidential:private",
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "value": false
                              }
                            }
                          },
                          {
                            "terms": {
                              "_name": "filters:confidentiality:groups:non_confidential:private:project:membership",
                              "namespace_id": [
                                9971
                              ]
                            }
                          }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "_name": "filters:confidentiality:groups:confidential:private",
                        "must": [
                          {
                            "term": {
                              "confidential": {
                                "value": true
                              }
                            }
                          }
                        ],
                        "should": [
                          {
                            "prefix": {
                              "traversal_ids": {
                                "_name": "filters:confidentiality:groups:confidential:private:ancestry_filter:descendants",
                                "value": "9970-"
                              }
                            }
                          }
                        ],
                        "minimum_should_match": 1
                      }
                    }
                  ],
                  "minimum_should_match": 1
                }
              }
            ]
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
]
```

#### `by_label_ids`

Requires `label_ids` field. Query with `label_names` in options.

```json
{
  "bool": {
    "must": [
      {
        "terms": {
          "_name": "filters:label_ids",
          "label_ids": [
            1
          ]
        }
      }
    ]
  }
}
```

#### `by_archived`

Requires `archived` field. Query with `search_level` and `include_archived` in options.

```json
{
  "bool": {
    "_name": "filters:non_archived",
    "should": [
      {
        "bool": {
          "filter": {
            "term": {
              "archived": {
                "value": false
              }
            }
          }
        }
      },
      {
        "bool": {
          "must_not": {
            "exists": {
              "field": "archived"
            }
          }
        }
      }
    ]
  }
}
```

#### `by_state`

Requires `state` field. Supports values: `all`, `opened`, `closed`, and `merged`. Query with `state` in options.

```json
{
  "match": {
    "state": {
      "_name": "filters:state",
      "query": "opened"
    }
  }
}
```

#### `by_not_hidden`

Requires `hidden` field. Not applied for admins.

```json
{
  "term": {
    "hidden": {
      "_name": "filters:not_hidden",
      "value": false
    }
  }
}
```

#### `by_work_item_type_ids`

Requires `work_item_type_id` field. Query with `work_item_type_ids` or `not_work_item_type_ids` in options.

```json
{
  "bool": {
    "must_not": {
      "terms": {
        "_name": "filters:not_work_item_type_ids",
        "work_item_type_id": [
          8
        ]
      }
    }
  }
}
```

#### `by_author`

Requires `author_id` field. Query with `author_username` or `not_author_username` in options.

```json
{
  "bool": {
    "should": [
      {
        "term": {
          "author_id": {
            "_name": "filters:author",
            "value": 1
          }
        }
      }
    ],
    "minimum_should_match": 1
  }
}
```

#### `by_target_branch`

Requires `target_branch` field. Query with `target_branch` or `not_target_branch` in options.

```json
{
  "bool": {
    "should": [
      {
        "term": {
          "target_branch": {
            "_name": "filters:target_branch",
            "value": "master"
          }
        }
      }
    ],
    "minimum_should_match": 1
  }
}
```

#### `by_source_branch`

Requires `source_branch` field. Query with `source_branch` or `not_source_branch` in options.

```json
{
  "bool": {
    "should": [
      {
        "term": {
          "source_branch": {
            "_name": "filters:source_branch",
            "value": "master"
          }
        }
      }
    ],
    "minimum_should_match": 1
  }
}
```

#### `by_search_level_and_group_membership`

Requires `current_user`, `group_ids`, `traversal_id`, `search_level` fields. Query with `search_level` and
filter on `namespace_visibility_level` based on permissions user has for each group.

{{< alert type="note" >}}

This filter can be used in place of `by_search_level_and_membership` if the data being searched does not contain the `project_id` field.

{{< /alert >}}

{{< alert type="note" >}}

Examples are shown for an authenticated user. The JSON may be different for users with authorizations, admins, external, or anonymous users

{{< /alert >}}

##### global

```json
{
  "bool": {
    "should": [
      {
        "bool": {
          "filter": [
            {
              "term": {
                "namespace_visibility_level": {
                  "value": 20,
                  "_name": "filters:namespace_visibility_level:public"
                }
              }
            }
          ]
        }
      },
      {
        "bool": {
          "filter": [
            {
              "term": {
                "namespace_visibility_level": {
                  "value": 10,
                  "_name": "filters:namespace_visibility_level:internal"
                }
              }
            }
          ]
        }
      },
      {
        "bool": {
          "filter": [
            {
              "term": {
                "namespace_visibility_level": {
                  "value": 0,
                  "_name": "filters:namespace_visibility_level:private"
                }
              }
            },
            {
              "terms": {
                "namespace_id": [
                  33,
                  22
                ]
              }
            }
          ]
        }
      }
    ],
    "minimum_should_match": 1
  }
}
```

##### group

```json
[
  {
    "bool": {
      "_name": "filters:level:group",
      "minimum_should_match": 1,
      "should": [
        {
          "prefix": {
            "traversal_ids": {
              "_name": "filters:level:group:ancestry_filter:descendants",
              "value": "22-"
            }
          }
        }
      ]
    }
  },
  {
    "bool": {
      "should": [
        {
          "bool": {
            "filter": [
              {
                "term": {
                  "namespace_visibility_level": {
                    "value": 20,
                    "_name": "filters:namespace_visibility_level:public"
                  }
                }
              }
            ]
          }
        },
        {
          "bool": {
            "filter": [
              {
                "term": {
                  "namespace_visibility_level": {
                    "value": 10,
                    "_name": "filters:namespace_visibility_level:internal"
                  }
                }
              }
            ]
          }
        },
        {
          "bool": {
            "filter": [
              {
                "term": {
                  "namespace_visibility_level": {
                    "value": 0,
                    "_name": "filters:namespace_visibility_level:private"
                  }
                }
              },
              {
                "terms": {
                  "namespace_id": [
                    22
                  ]
                }
              }
            ]
          }
        }
      ],
      "minimum_should_match": 1
    }
  },
  {
    "bool": {
      "_name": "filters:level:group",
      "minimum_should_match": 1,
      "should": [
        {
          "prefix": {
            "traversal_ids": {
              "_name": "filters:level:group:ancestry_filter:descendants",
              "value": "22-"
            }
          }
        }
      ]
    }
  }
]
```

#### `by_search_level_and_membership`

Requires `project_id`, `traversal_id` and project visibility (defaulting to `visibility_level` but can set with the `project_visibility_level_field` option) fields. Supports feature `*_access_level` fields. Query with `search_level`
 and optionally `project_ids`, `group_ids`, `features`, and `current_user` in options.

Filtering is applied for:

- search level for global, group, or project
- membership for direct membership to groups and projects or shared membership through direct access to a group
- any feature access levels passed through `features`

{{< alert type="note" >}}

Examples are shown for a logged in user. The JSON may be different for users with authorizations, admins, external, or anonymous users

{{< /alert >}}

##### global

```json
{
  "bool": {
    "_name": "filters:permissions:global",
    "should": [
      {
        "bool": {
          "must": [
            {
              "terms": {
                "_name": "filters:permissions:global:visibility_level:public_and_internal",
                "visibility_level": [
                  20,
                  10
                ]
              }
            }
          ],
          "should": [
            {
              "terms": {
                "_name": "filters:permissions:global:repository_access_level:enabled",
                "repository_access_level": [
                  20
                ]
              }
            }
          ],
          "minimum_should_match": 1
        }
      },
      {
        "bool": {
          "must": [
            {
              "bool": {
                "should": [
                  {
                    "terms": {
                      "_name": "filters:permissions:global:repository_access_level:enabled_or_private",
                      "repository_access_level": [
                        20,
                        10
                      ]
                    }
                  }
                ],
                "minimum_should_match": 1
              }
            }
          ],
          "should": [
            {
              "prefix": {
                "traversal_ids": {
                  "_name": "filters:permissions:global:ancestry_filter:descendants",
                  "value": "123-"
                }
              }
            },
            {
              "terms": {
                "_name": "filters:permissions:global:project:member",
                "project_id": [
                  456
                ]
              }
            }
          ],
          "minimum_should_match": 1
        }
      }
    ],
    "minimum_should_match": 1
  }
}
```

##### group

```json
[
  {
    "bool": {
      "_name": "filters:level:group",
      "minimum_should_match": 1,
      "should": [
        {
          "prefix": {
            "traversal_ids": {
              "_name": "filters:level:group:ancestry_filter:descendants",
              "value": "123-"
            }
          }
        }
      ]
    }
  },
  {
    "bool": {
      "_name": "filters:permissions:group",
      "should": [
        {
          "bool": {
            "must": [
              {
                "terms": {
                  "_name": "filters:permissions:group:visibility_level:public_and_internal",
                  "visibility_level": [
                    20,
                    10
                  ]
                }
              }
            ],
            "should": [
              {
                "terms": {
                  "_name": "filters:permissions:group:repository_access_level:enabled",
                  "repository_access_level": [
                    20
                  ]
                }
              }
            ],
            "minimum_should_match": 1
          }
        },
        {
          "bool": {
            "must": [
              {
                "bool": {
                  "should": [
                    {
                      "terms": {
                        "_name": "filters:permissions:group:repository_access_level:enabled_or_private",
                        "repository_access_level": [
                          20,
                          10
                        ]
                      }
                    }
                  ],
                  "minimum_should_match": 1
                }
              }
            ],
            "should": [
              {
                "prefix": {
                  "traversal_ids": {
                    "_name": "filters:permissions:group:ancestry_filter:descendants",
                    "value": "123-"
                  }
                }
              }
            ],
            "minimum_should_match": 1
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
]
```

##### project

```json
[
  {
    "bool": {
      "_name": "filters:level:project",
      "must": {
        "terms": {
          "project_id": [
            456
          ]
        }
      }
    }
  },
  {
    "bool": {
      "_name": "filters:permissions:project",
      "should": [
        {
          "bool": {
            "must": [
              {
                "terms": {
                  "_name": "filters:permissions:project:visibility_level:public_and_internal",
                  "visibility_level": [
                    20,
                    10
                  ]
                }
              }
            ],
            "should": [
              {
                "terms": {
                  "_name": "filters:permissions:project:repository_access_level:enabled",
                  "repository_access_level": [
                    20
                  ]
                }
              }
            ],
            "minimum_should_match": 1
          }
        },
        {
          "bool": {
            "must": [
              {
                "bool": {
                  "should": [
                    {
                      "terms": {
                        "_name": "filters:permissions:project:repository_access_level:enabled_or_private",
                        "repository_access_level": [
                          20,
                          10
                        ]
                      }
                    }
                  ],
                  "minimum_should_match": 1
                }
              }
            ],
            "should": [
              {
                "prefix": {
                  "traversal_ids": {
                    "_name": "filters:permissions:project:ancestry_filter:descendants",
                    "value": "123-"
                  }
                }
              }
            ],
            "minimum_should_match": 1
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
]
```

#### `by_combined_search_level_and_membership`

Requires `search_level` field and at least one of `use_group_authorization` or `use_project_authorization`. This filter combines
`by_search_level_and_membership` and `by_search_level_and_group_membership` into one query if both
`use_group_authorization` and `use_project_authorization` are provided. See those methods for required fields.

```json
[
  {
    "bool": {
      "should": [
        {
          "bool": {
            "filter": [
              {
                "bool": {
                  "should": [
                    {
                      "bool": {
                        "should": [
                          {
                            "prefix": {
                              "traversal_ids": {
                                "_name": "filters:permissions:global:private_access:ancestry_filter:descendants",
                                "value": "9970-"
                              }
                            }
                          }
                        ],
                        "filter": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:private_access:issues_access_level:enabled_or_private",
                              "issues_access_level": [
                                20,
                                10
                              ]
                            }
                          }
                        ],
                        "minimum_should_match": 1
                      }
                    },
                    {
                      "bool": {
                        "filter": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:private_access:issues_access_level:enabled_or_private",
                              "issues_access_level": [
                                20,
                                10
                              ]
                            }
                          },
                          {
                            "terms": {
                              "_name": "filters:permissions:global:private_access:project:member",
                              "project_id": [
                                278964
                              ]
                            }
                          }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "should": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:issues_access_level:enabled",
                              "issues_access_level": [
                                20
                              ]
                            }
                          }
                        ],
                        "filter": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:project_visibility_level:public_and_internal",
                              "project_visibility_level": [
                                20,
                                10
                              ]
                            }
                          }
                        ],
                        "minimum_should_match": 1
                      }
                    }
                  ],
                  "minimum_should_match": 1
                }
              }
            ]
          }
        },
        {
          "bool": {
            "filter": [
              {
                "bool": {
                  "_name": "filters:permissions:global",
                  "should": [
                    {
                      "bool": {
                        "filter": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:namespace_visibility_level:public_and_internal",
                              "namespace_visibility_level": [
                                20,
                                10
                              ]
                            }
                          }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "must": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:namespace_visibility_level:private",
                              "namespace_visibility_level": [
                                0
                              ]
                            }
                          }
                        ],
                        "should": [
                          {
                            "prefix": {
                              "traversal_ids": {
                                "_name": "filters:permissions:global:ancestry_filter:descendants",
                                "value": "9970-"
                              }
                            }
                          }
                        ],
                        "minimum_should_match": 1
                      }
                    },
                    {
                      "bool": {
                        "must": [
                          {
                            "terms": {
                              "_name": "filters:permissions:global:namespace_visibility_level:private",
                              "namespace_visibility_level": [
                                0
                              ]
                            }
                          },
                          {
                            "terms": {
                              "_name": "filters:permissions:global:project:membership",
                              "namespace_id": [
                                9971
                              ]
                            }
                          }
                        ]
                      }
                    }
                  ],
                  "minimum_should_match": 1
                }
              }
            ]
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
]
```

#### `by_knn`

Requires options: `vectors_supported` (set to `:elasticsearch` or `:opensearch`) and `embedding_field`. Callers may optionally provide options: `embeddings`

{{< alert type="warning" >}}

Elasticsearch and OpenSearch DSL for `knn` queries is different. To support both, this filter must be used with the
`by_knn` query.

{{< /alert >}}

#### `by_noteable_type`

Requires `noteable_type` field. Query with `noteable_type` in options. Sets `_source` to only return `noteable_id` field.

```json
{
  "term": {
    "noteable_type": {
      "_name": "filters:related:issue",
      "value": "Issue"
    }
  }
}
```

## Testing scopes

Test any scope in the Rails console

```ruby
search_service = ::SearchService.new(User.first, { search: 'foo', scope: 'SCOPE_NAME' })
search_service.search_objects
```

### Permissions tests

Search code has a final security check in `SearchService#redact_unauthorized_results`. This prevents
unauthorized results from being returned to users who don't have permission to view them. The check is
done in Ruby to handle inconsistencies in Elasticsearch permissions data due to bugs or indexing delays.

New scopes must add visibility specs to ensure proper access control.
To test that permissions are properly enforced, add tests using the [`'search respects visibility'` shared example](https://gitlab.com/gitlab-org/gitlab/-/blob/a489ad0fe4b4d1e392272736b020cf9bd43646da/ee/spec/support/shared_examples/services/search_service_shared_examples.rb)
in the EE specs:

- `ee/spec/services/ee/search/global_service_spec.rb`
- `ee/spec/services/ee/search/group_service_spec.rb`
- `ee/spec/services/ee/search/project_service_spec.rb`

## Zero-downtime reindexing with multiple indices

{{< alert type="note" >}}

This is not applicable yet as multiple indices functionality is not fully implemented.

{{< /alert >}}

Currently, GitLab can only handle a single version of setting. Any setting/schema changes would require reindexing everything from scratch. Since reindexing can take a long time, this can cause search functionality downtime.

To avoid downtime, GitLab is working to support multiple indices that
can function at the same time. Whenever the schema changes, the administrator
will be able to create a new index and reindex to it, while searches
continue to go to the older, stable index. Any data updates will be
forwarded to both indices. Once the new index is ready, an administrator can
mark it active, which will direct all searches to it, and remove the old
index.

This is also helpful for migrating to new servers, for example, moving to/from AWS.

Currently, we are on the process of migrating to this new design. Everything is hardwired to work with one single version for now.
