---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Active Context
---

Semantic Search is powered by the Active Context framework implemented through the [`gitlab-active-context`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-active-context) gem. This framework provides a translation layer for different vector stores (Elasticsearch, OpenSearch, PostgreSQL with pgvector), allowing the same code to work with any supported vector store without needing vector store-specific implementations.

The framework is extensible and designed to support different types of **Semantic Search Collections**. Each Semantic Search Collection is implemented using:

- **Collections** (`Ai::ActiveContext::Collections::<Type>`): Define what content is indexed and how it's stored
- **References** (`Ai::ActiveContext::References::<Type>`): Represent an item of content to index, and define the preprocessors and operation that write it to the vector store
- **Queues** (`Ai::ActiveContext::Queues::<Type>`): Hold tracked references in sharded Redis queues until background jobs process them in batches
- **Queries** (`Ai::ActiveContext::Queries::<Type>`): Retrieve similar content from the vector store
- **Migrations**: Execute schema changes and data transformations on the vector store

To support a new type of content, such as merge requests or documentation, implement these components for a new collection.
For more information, see [adding Semantic Search Collections](adding_semantic_search_collections.md).

## Reference processing

A reference represents one item of content to index, for example a chunk of code.
When content changes, the collection tracks references for it with `track!`, which pushes the references onto the collection's [queue](#queues).

A `BulkProcessWorker` job processes a batch of references from one queue shard:

1. Reads the due references from the shard and deserializes them.
1. Runs the [preprocessors](#preprocessors) of the reference class in order.
   Each preprocessor receives only the references that succeeded in the previous step.
1. Sends references that pass every preprocessor to the bulk processor,
   which applies each reference's [operation](#operations) and writes to the vector store in bulk.
1. Removes the processed references from the queue.
   Failed references go to the queue's failure queue.
   For more information, see [retries and the dead queue](#retries-and-the-dead-queue).

The batch logic is in `ActiveContext::BulkProcessQueue`.

### Preprocessors

Preprocessors prepare references before their [operations](#operations) are applied to the vector store.
A reference class declares its preprocessors with `add_preprocessor`, and they run in the order they are declared.
A preprocessor can have a `should_run` condition, and is skipped when the condition is `false`.
Each preprocessor returns its successful, failed, and infinite-retry references.

The `gitlab-active-context` gem provides these preprocessors:

- `EmbeddedSkipper`: Drops references whose documents already have embeddings in the selected embedding fields,
  so later preprocessors don't request them again.
- `ContentFetcher`: Reads the content of existing documents from the vector store.
- `Embeddings`: Generates embeddings for all references in bulk, either from a content field on existing documents
  or from a method on the reference.

### Operations

Each reference defines an operation that determines how its documents are written to the vector store:

- `upsert`: Creates or updates the reference's documents.
  If the reference now has fewer documents than before, the leftover documents are deleted.
- `update`: Updates documents that already exist.
  `Ai::ActiveContext::References::Code` uses `update` because the indexer creates the documents.
- `delete`: Deletes all documents for the reference.

## Queues

Queues hold tracked references until a `BulkProcessWorker` job processes them.
Queues are stored in Redis.
Each queue is split into shards, and each shard is a Redis sorted set.
When a reference is tracked, a consistent hash of the reference picks its shard.
`ActiveContext.raw_queues` returns one entry for each shard, and each shard is processed by its own job.

Queue classes are registered in `config.queue_classes` in `config/initializers/active_context.rb`.

The `Ai::ActiveContext::BulkProcessWorker` cron job runs every minute and enqueues one job for each queue shard.
For what each job does with its batch, see [reference processing](#reference-processing).

When `re_enqueue_indexing_workers` is turned on in `config/initializers/active_context.rb`,
a job re-enqueues itself after it processes a batch, so the shard keeps draining between cron runs.
A job stops re-enqueueing early when the whole batch fails or when the queue limits throughput
([`limit_throughput?`](#queue-properties)).

### Queue properties

A queue class includes `ActiveContext::Concerns::Queue` and can define these properties:

- `number_of_shards`: Number of shards.
  Each shard is processed by a separate job, so this value sets how many jobs process the queue in parallel.
  Required.
- `shard_limit`: Maximum number of references a job reads from a shard in one run. Defaults to `1000`.
- `processing_delay`: Delay before items can be processed.
  When set, the queue is time-based, and a job processes items only after the delay passes.
  Other reads, such as `ActiveContext::Queues.all_queued_items`, return every item regardless of the delay.
  When not set, the queue is first-in, first-out (FIFO).
- `failure_queue`: Queue that receives failed references. Defaults to `RetryQueue`.
- `infinite_retry_queue`: Queue that receives references that failed with a temporary error, such as a rate limit.
  Defaults to `RetryQueue`.
- `limit_throughput?`: When `true`, a job doesn't re-enqueue itself after it processes a batch. Defaults to `false`.
- `extra_preprocess_options`: Options passed to every preprocessor, in addition to the `queue_name`.

### Retries and the dead queue

If embedding generation fails, the references move through a chain of retry queues with increasing delays:

1. `RetryQueue`: 5 minutes
1. `SecondRetryQueue`: 30 minutes
1. `ThirdRetryQueue`: 2 hours
1. `FourthRetryQueue`: 8 hours

Each stage gives one retry, so transient errors, such as AI Gateway timeouts, have time to clear between attempts.
References that fail every stage are placed on a dead queue, which is never processed automatically.
Each queue class defines its `failure_queue`, so the retry count comes from the queue chain and references carry no extra state.

Rate limit errors are the exception. Rate-limited references return to the first
retry queue from any stage. They retry every 5 minutes until the rate limit
clears. They never reach the dead queue.

## Migrations

The Active Context framework uses a migration system to manage schema changes and data transformations for the connected vector store. Migrations are tracked in the database and executed asynchronously by a worker process.

`Ai::ActiveContext::MigrationWorker` runs as a cron job every 5 minutes to execute incomplete migrations.
The worker applies only the migrations for the active connection.
When a different connection becomes active, the worker applies that connection's outstanding migrations.

Migration files are in `ee/active_context/migrate/`.

## Tasks

> [!note]
> For in-depth architecture details, see the [Active Context Tasks](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_abstraction_layer/active_context_tasks/) design document.

The Active Context framework uses a task execution system for managing long-running asynchronous operations. The Active Context Tasks system handles complex workflows like embedding model activation, incremental indexing, and data migrations. It includes built-in support for retries, error handling, and state persistence, ensuring reliable execution of critical operations.

## Embedding models

> [!note]
> For in-depth architecture details, see the [Embedding Models design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_abstraction_layer/embedding_models/).

### Model metadata

Semantic Search uses embedding models to generate the embeddings used for indexing and search.

The embedding models are stored in the `Ai::ActiveContext::Collection` record `metadata` as
`current_indexing_embedding_model`, `next_indexing_embedding_model`, and `search_embedding_model`.

Each embedding model metadata has the following information:

- `model_type`: Either `gitlab_managed` or `self_hosted`
- `model_ref`: The model identifier (for example, `text_embedding_005_vertex` or the `Ai::SelfHostedModel` ID)
- `field`: The vector store field where embeddings are stored
- `dimensions`: The embedding vector dimensions, used when creating the vector store field and for generating embeddings

### `ActiveContext::EmbeddingModel` object and embeddings generation

From a Collection class (for example, `Ai::ActiveContext::Collections::Code`), the embedding models are exposed as
`ActiveContext::EmbeddingModel` objects through the `Ai::ActiveContext::Embeddings::ModelFactory`.

Embeddings are generated by invoking `generate_embeddings` on the created `ActiveContext::EmbeddingModel` object. For example:

```ruby
ac_embedding_model = Ai::ActiveContext::Collections::Code.current_indexing_embedding_model # this returns an ActiveContext::EmbeddingModel
ac_embedding_model.generate_embeddings(<array_of_content>, user: <optional_user>)
```

Under the hood, `ActiveContext::EmbeddingModel#generate_embeddings` executes a `Gitlab::Llm::Embeddings::*` class which sends an embeddings request to the AI Gateway.

### Model switching

`Ai::ActiveContext::EmbeddingModelActivationService` sets the first embedding model for a collection
or switches it to a new one.

The service first validates the request. It checks that no switch is already in progress,
that the model is different from the current model, and that the model and batch size are valid.
Unless told to skip it, the service also sends a test embeddings request.

The service then sets the new model as `next_indexing_embedding_model`, with a new versioned field name,
and starts a chain of [Active Context Tasks](#tasks):

1. `AddEmbeddingsField`: Adds the vector field for the new model.
1. `BackfillEmbeddings`: Runs only when switching from an existing model.
   Finds documents that are missing the new field and tracks them on the collection's backfill queue.
   The task completes when the queue is empty and no documents are missing the field.
1. `UpdateCollectionMetadata`: Makes the new model the `current_indexing_embedding_model` and `search_embedding_model`,
   and clears `next_indexing_embedding_model`.
1. `SyncFeatureSettings`: Runs only when users select the embedding model and the collection has a matching feature setting.
1. `NullifyField`: Runs only when switching from an existing model. Clears the old field from all documents.

Search keeps using the old model until `UpdateCollectionMetadata` runs, so a switch doesn't interrupt search.

## Vector stores

Active Context reads from and writes to the vector store through an adapter.
Each adapter implements the same interface, so collections, queries, and migrations work the same way on every supported vector store.

Active Context provides these adapters:

- `ActiveContext::Databases::Elasticsearch::Adapter`: Elasticsearch.
- `ActiveContext::Databases::Opensearch::Adapter`: OpenSearch.
- `ActiveContext::Databases::Postgresql::Adapter`: PostgreSQL with the `pgvector` extension.

Each adapter is built from vector store-specific classes:

- **Client**: Runs searches against the vector store.
- **Indexer**: Collects processed references and writes them to the vector store in bulk.
- **Executor**: Applies schema changes, such as creating a collection or adding a field. [Migrations](#migrations) use the executor.

Active Context uses the adapter of the active connection, an `Ai::ActiveContext::Connection` record that stores the adapter class and its connection options.
Only one connection can be active at a time.

## Query execution

When a query is executed:

1. **Embedding generation**: The user's query is converted to an embedding using the same model as the indexed content
1. **Vector search**: The embedding is compared against stored vectors using k-nearest neighbors (KNN) search
1. **Filtering**: Results are filtered by relevant criteria (for example, project, file path)
1. **Authorization**: Results are filtered to only include content the user has access to
1. **Result limit**: Each query class sets its own limit. `Ai::ActiveContext::Queries::Code` returns the 20 most similar results by default.
