---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Semantic Search
---

Semantic Search is a GitLab framework that uses vector embeddings to find semantically similar content based on meaning rather than keyword matching. This enables AI features like Duo Chat to retrieve relevant context for user queries.

## Overview

Semantic Search converts text into vector embeddings and stores them in a vector store. When a user makes a query, the query is also converted to an embedding and compared against stored vectors to find the most similar results. This approach captures semantic meaning, allowing searches to find relevant content even when exact keywords don't match.

## Semantic Code Search

Semantic Code Search is the first implementation of the Semantic Search framework. It enables Duo Chat and other AI features to find relevant code snippets from a repository. The feature is available as an [MCP tool (`semantic_code_search`)](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#semantic_code_search) that can be used by GitLab Duo Agent Platform and other AI platforms.

Please refer to the [Semantic Code Search Architecture](#semantic-code-search-architecture) for further details.

## Architecture

The Semantic Search framework is powered by the [`gitlab-active-context`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-active-context) gem. This gem provides a translation layer for different vector stores (Elasticsearch, OpenSearch, PostgreSQL with pgvector), allowing the same code to work with any supported vector store without needing vector store-specific implementations.

The framework is extensible and designed to support multiple types of semantic search. Each semantic search type is implemented using:

- **Collections** (`Ai::ActiveContext::Collections::<Type>`): Define what content is indexed and how it's stored
- **References** (`Ai::ActiveContext::References::<Type>`): Track and manage embeddings for content updates
- **Queries** (`Ai::ActiveContext::Queries::<Type>`): Retrieve similar content from the vector store
- **Queues** (`Ai::ActiveContext::Queues::<Type>`): Manage asynchronous processing of embedding generation
- **Migrations**: Execute schema changes and data transformations on the vector store

New semantic search types can be added by implementing these components for different content types (for example, merge requests or documentation).

### Embedding generation

Embeddings are generated asynchronously through a queue system using reference classes like `Ai::ActiveContext::References::Code`:

1. **References are tracked**: When content is created or updated, embedding references are tracked in the appropriate reference class
1. **Batch processing**: References are processed in batches by the `Ai::ActiveContext::BulkProcessWorker`
1. **Vector storage**: Generated embeddings are stored in the configured vector store

The `BulkProcessWorker` is a cron job that runs every minute and processes embedding references from the queue. It fetches references, generates embeddings, and removes them from the queue. If the queue is not empty after processing, the worker re-enqueues itself to continue processing. If embedding generation fails, it gets retried once and is then placed on a dead queue.

### Embedding models

Currently, semantic search uses **Vertex AI's `text-embedding-005` model** for generating embeddings. The model configuration is defined in the collection classes (for example, `Ai::ActiveContext::Collections::Code`).

Support for setting the embeddings model in a [Self-hosted AI Gateway](../../administration/gitlab_duo_self_hosted/_index.md)
setup is planned in [epic 20110](https://gitlab.com/groups/gitlab-org/-/epics/20110). Once available, administrators
in Self-Managed instances with a Self-hosted AI Gateway will be able to select their own embeddings model.

### Query execution

When a query is executed:

1. **Embedding generation**: The user's query is converted to an embedding using the same model as the indexed content
1. **Vector search**: The embedding is compared against stored vectors using k-nearest neighbors (KNN) search
1. **Filtering**: Results are filtered by relevant criteria (for example: project, file path)
1. **Authorization**: Results are filtered to only include content the user has access to
1. **Result limit**: By default, the 10 most similar results are returned

### Migrations

The Semantic Search framework uses a migration system to manage schema changes and data transformations for the connected vector store. Migrations are tracked in the database and executed asynchronously by a worker process.

`Ai::ActiveContext::MigrationWorker` runs as a cron job every 5 minutes to execute uncompleted migrations.

### Vector stores

An instance can use one of the following vector stores:

- **Elasticsearch**
- **OpenSearch**
- **PostgreSQL with pgvector**

A vector store connection must be created before semantic search can be used. There are two ways to configure the connection:

**Option 1: Using the GitLab UI**

For Elasticsearch or OpenSearch clusters used by Advanced Search:

1. Navigate to **Admin** > **Settings** > **Search**
1. Click the button to connect to the Advanced Search cluster
1. The connection is automatically created and configured

**Option 2: Using Rails console**

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "os",
  options: { url: ["http://localhost:9202"] },
  adapter_class: "ActiveContext::Databases::OpenSearch::Adapter"
)
connection.activate!
```

Supported adapter classes:

- `ActiveContext::Databases::Elasticsearch::Adapter`
- `ActiveContext::Databases::OpenSearch::Adapter`
- `ActiveContext::Databases::Postgres::Adapter`

The `options` hash should contain the connection details specific to your vector store (URL, credentials, etc.).

### Semantic Code Search Architecture

#### Indexing workflow

##### Initial indexing

When the Semantic Code Search tool is invoked for a project that hasn't been indexed yet:

1. **Repository record creation**: An `Ai::ActiveContext::Code::Repository` record is created with `pending` state
1. **Index worker**: The `Ai::ActiveContext::Code::RepositoryIndexWorker` processes the `pending` repository
1. **Initial indexing**:
   1. The `Ai::ActiveContext::Code::InitialIndexingService` calls the `Ai::ActiveContext::Code::Indexer`
   1. The `Indexer` runs the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to fetch the repository's files from Gitaly, chunk the code, and index the chunks in the vector store
   1. The `InitialIndexingService` enqueues the references/IDs of the indexed content for embeddings generation
1. **Async processing**: Queued content references are picked up for embeddings generation via the asynchronous `Ai::ActiveContext::BulkProcessWorker`.
1. **Tool not available**: The user is notified that indexing is in progress and should try again in a few minutes.
1. **Ready check**: The `Ai::ActiveContext::Code::MarkRepositoryAsReadyEventWorker` runs on a 10-minute cron schedule (via `SchedulingService`) and checks if all embeddings have been generated. Once all embeddings are ready, it marks the repository as `ready`
1. **Available for queries**: The next time the tool is invoked, the repository is ready and can be used for semantic search queries

##### Incremental indexing

When code is merged into the default branch:

1. **Push event**: A push event triggers the incremental indexing process through the `BranchPushService`
1. **Index worker**: The `Ai::ActiveContext::Code::RepositoryIndexWorker` processes the `ready` ActiveContext repository
1. **Incremental Indexing** - only the changed files are processed
   1. The `Ai::ActiveContext::Code::IncrementalIndexingService` calls the `Ai::ActiveContext::Code::Indexer`
   1. The `Indexer` runs the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to fetch the changed files from Gitaly, chunk the code, and index the chunks in the vector store. It also deletes orphaned data from the vector store.
   1. The `IncrementalIndexingService` enqueues the references/IDs of the indexed content for embeddings generation
1. **Async processing**: Queued content references are picked up for embeddings generation via the asynchronous `Ai::ActiveContext::BulkProcessWorker`.

#### Deletion workflow

When a namespace is no longer eligible for indexing, `Ai::ActiveContext::Code::ProcessInvalidEnabledNamespaceEventWorker` picks it up and deletes the `EnabledNamespace` record.

When a repository is no longer eligible for indexing, `Ai::ActiveContext::Code::MarkRepositoryAsPendingDeletionEventWorker` marks it as `pending_delete`. The `Ai::ActiveContext::Code::RepositoryIndexWorker` then processes the repository and calls the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to delete the project's documents from the vector store and delete the repository record.

#### `gitlab-elasticsearch-indexer`

The [`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) Go project handles:

- fetching the repository's files from Gitaly
- chunking the files
- indexing the chunked content on the vector store
- deleting orphaned data
- deleting all data for a project

**Chunking**

The `gitlab-elasticsearch-indexer` makes use of the [`gitlab-code-parser`](https://gitlab.com/gitlab-org/rust/gitlab-code-parser) library to split the code into logic chunks.

The chunking process uses a two-stage approach:

1. _AST-aware chunking_: The code chunker parses each file and identifies logical split points (function definitions, class definitions, etc.)
1. _Size-based fallback_: If no AST split points are available, the chunker falls back to splitting on line boundaries while respecting a maximum byte size

This approach ensures chunks are semantically meaningful while staying within size limits for embedding generation.

#### Namespace eligibility

Not all namespaces are eligible for Semantic Code Search. Eligibility is managed through two workers:

**`Ai::ActiveContext::Code::CreateEnabledNamespaceEventWorker`** (runs daily via `SchedulingService`)

- Identifies and enables eligible namespaces
- Creates `EnabledNamespace` records for qualifying namespaces

**On GitLab.com**, a namespace is eligible if:

- AI features are enabled in the namespace settings
- The namespace has a supported AI plan (Premium or higher)
- The subscription is not expired

**On self-managed instances**, all top-level group namespaces are eligible if:

- Instance-level AI beta features are enabled (`instance_level_ai_beta_features_enabled`)
- AI features are available in the license

**`Ai::ActiveContext::Code::MarkRepositoryAsPendingDeletionEventWorker`** marks repositories for deletion when they no longer meet eligibility criteria.

**`Ai::ActiveContext::Code::ProcessInvalidEnabledNamespaceEventWorker`** cleans up `EnabledNamespace` records for namespaces that no longer meet eligibility criteria.

#### Supported file types

Semantic Code Search indexes all files in a repository. Currently, results are post-filtered to exclude files matching the project's exclusion rules. Future versions will stop indexing excluded files entirely for improved efficiency.

#### MCP implementation

For more information about GitLab MCP implementation and available clients, see the [GitLab MCP documentation](../../user/gitlab_duo/model_context_protocol/mcp_clients.md) and the [runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/ai-active-context).

Currently, the Semantic Code Search tool is available in IDEs when GitLab MCP is configured. With the rollout of the `mcp_client` feature flag, it will be available on the web.

## Extending Semantic Search

For detailed information on extending the Semantic Search framework, see the [`gitlab-active-context` gem documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-active-context/doc/code_embeddings_indexing_pipeline.md).

To add a new semantic search type (for example, merge requests or documentation), implement the following components:

- **Collection** (`Ai::ActiveContext::Collections::<Type>`): Define the collection name, queue, reference class, and how to handle authorization
- **Reference** (`Ai::ActiveContext::References::<Type>`): Extend `ActiveContext::Reference` to track embeddings and define preprocessors for content and embedding generation
- **Query** (`Ai::ActiveContext::Queries::<Type>`): Implement query logic to search the vector store
- **Queue** (`Ai::ActiveContext::Queues::<Type>`): Define the queue for managing asynchronous processing
- **Workers**: Create workers for indexing, processing, and managing the lifecycle of the new semantic search type

See the Semantic Code Search implementation for a complete example of how these components work together.

## Enabling Semantic Code Search

### Prerequisites

- Vector store connection configured (Elasticsearch, OpenSearch, or PostgreSQL with pgvector)
- Vertex AI credentials configured for embedding generation
- Beta experiment features setting enabled for the instance

### Verifying prerequisites

**Vector store connection**

Test that the vector store connection is working:

```ruby
ActiveContext::adapter.search(
  user: current_user,
  collection: ::Ai::ActiveContext::Collections::Code,
  query: ActiveContext::Query.all
)
```

This should return results without errors.

**Vertex AI credentials**

Test that embedding generation is configured:

```ruby
::ActiveContext::Embeddings.generate_embeddings(
  "test",
  version: ::Ai::ActiveContext::Collections::Code::MODELS[1]
)
```

This should return a vector.

**Beta experiment features**

Verify that beta experiment features are enabled for the namespace:

```ruby
namespace.experiment_features_enabled?
```

This should return `true`.

## Disabling Semantic Code Search

WARNING: Disabling semantic code search can cause long database locks if there are many repository records to delete. Use with caution on production environments. Upcoming work will allow disabling safely. See [issue 582787](https://gitlab.com/gitlab-org/gitlab/-/issues/582787).

Delete the index and collection record:

```ruby
ActiveContext.adapter.executor.drop_collection(:code)
```

Delete the connection and associated records:

```ruby
::Ai::ActiveContext::Connection.active.destroy!
```

## Developer Guide

### Setting up MCP locally

To set up the MCP server locally for development and testing, see the [MCP server development guide](../mcp_server.md).

Tip: specifically ask for the `semantic_code_search` tool in your prompt to ensure the tool is used.

### Using Semantic Code Search

To invoke semantic search from your console, use the `Ai::ActiveContext::Queries::Code` class:

```ruby
# Check if semantic code search is available
Ai::ActiveContext::Queries::Code.available?

# Perform a semantic search
result = Ai::ActiveContext::Queries::Code.new(
  search_term: "user authentication logic",
  user: current_user
).filter(
  project_id: project.id,
  path: "app/controllers/",  # Optional: filter by directory
  knn_count: 10,             # Number of vectors to compare
  limit: 10                  # Number of results to return
)
```

### Managing queued items

View all queued items waiting to be processed:

```ruby
ActiveContext::Queues.all_queued_items
```

Immediately process all queued items without waiting for cron workers:

```ruby
ActiveContext.execute_all_queues!
```

### Searching the vector store

Find all items in the vector store:

```ruby
ActiveContext::adapter.search(
  user: current_user,
  collection: ::Ai::ActiveContext::Collections::Code,
  query: ActiveContext::Query.all
)
```

### Resetting the connection

To start fresh with a new connection, destroy all existing data and recreate:

```ruby
active_connection = ::Ai::ActiveContext::Connection.active
active_connection.migrations.destroy_all
active_connection.repositories.destroy_all
active_connection.enabled_namespaces.destroy_all
active_connection.collections.destroy_all
active_connection.destroy
```

Then create and activate a new connection. When creating a migration in Rails console, remember to run:

```ruby
connection.activate!
```

### Supporting a new embedding model

In order for a new embedding model to be supported for Semantic Search, it must be:

1. Evaluated
1. Supported in AI Gateway
1. Supported in the Rails LLM module
1. Registered in the ActiveContext Collection

#### Evaluation

Each new model must be evaluated properly. GitLab may refuse to support models for certain reasons (e.g. legal, performance, etc).

After the evaluation, you should have the following information:

- model provider - e.g. Vertex, Anthropic, Fireworks, etc
- specific model and version - e.g. `gemini-embedding-001`, `all-MiniLM-L6-v2`

See [epic 17749](https://gitlab.com/groups/gitlab-org/-/work_items/17749) for further details on model evaluation.

#### Add API support in AI Gateway

1. Check if the model provider already has an existing [proxy API](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway/api/v1/proxy) in AI Gateway
1. If the provider does not yet have a proxy API:
   - You can add a new proxy API for the new provider
   - OR, you may need to route this through a different API group, i.e.: introduce an `/embeddings/<provider>/<model>` API.

#### Add a request wrapper class in the Rails LLM module

The [`Gitlab::Llm`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/gitlab/llm) module in Rails have
wrapper classes that send requests to corresponding AI Gateway APIs.

For example, the [`Gitlab::Llm::VertexAi::Embeddings::Text`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/vertex_ai/embeddings/text.rb)
is a request wrapper class for different Vertex Text embedding models,
e.g. `textembedding-gecko-003` and `text-embedding-005`.
If applicable, you may reuse this for other Vertex embedding models.

If it does not exist yet, you need to add a request wrapper class in
`ee/lib/gitlab/llm/<provider>/embeddings/<model-base-name>.rb`
or simply `ee/lib/gitlab/llm/<provider>/embeddings/default.rb`.
Follow the standard interface of LLM request wrapper classes,
with an `initialize` and `execute` method, example:

```ruby
class Gitlab::Llm::Anthropic::Embeddings::Voyage
  def initialize(texts, unit_primitive:, tracking_context:, user: nil, model: nil)
    # initialize instance variables
  end

  def execute
    # code to send embeddings generation request to AIGW
  end
end
```

Where the `initialize` parameters are:

- `texts` - the array of text contents to generate embeddings for
- `unit_primitive` - a tracking identifier representing a specific operation
- `tracking_context` - additional information used for analytics and observability
- `user` - the user requesting the embeddings generation
- `model` - the specific model name and version, e.g. `voyage-code-3`

The `execute` method must:

- take care of error handling, propagating either generic errors or errors that are expected by the calling classes
- return an array of embeddings that follow the index of the given `texts` input. Example:

  ```ruby
  texts = ["one", "two", "three"]
  embeddings = Gitlab::Llm::Anthropic::Embeddings::Voyage.new(texts, ...).execute
  p embeddings
  => [
    [0.123, 0.456, 0.789], # embeddings for "one"
    [0.234, 0.567, 0.890], # embeddings for "two"
    [0.345, 0.678, 0.901] # embeddings for "three"
  ]
  ```

You may use the existing [`Gitlab::Llm::VertexAi::Embeddings::Text`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/vertex_ai/embeddings/text.rb)
class as an implementation reference.

#### Register the model to the ActiveContext Collection

1. Under `ee/lib/ai/active_context/embeddings/code`, add an ActiveContext Embeddings class to allow invocation of the `Gitlab::Llm` class from the ActiveContext pipeline. This class must have the `generate_embeddings` class method with the expected parameters.

   Example:

   ```ruby
   class Ai::ActiveContext::Embeddings::Code::AnthropicVoyage
     DEFAULT_UNIT_PRIMITIVE = 'generate_embeddings_codebase'

     def self.generate_embeddings(
       contents,
       unit_primitive: nil,
       model: nil,
       user: nil,
       batch_size: nil
       )
       embeddings = []
       contents.each_slice(batch_size) do |batch_contents|
         embeddings += Gitlab::Llm::Anthropic::Embeddings::Voyage.new(
           batch_contents,
           unit_primitive: unit_primitive || DEFAULT_UNIT_PRIMITIVE,
           tracking_context: { action: 'embedding' },
           user: user,
           model: model
         )
       end

       embeddings
     end
   end
   ```

   Notes:

   - The `batch_size` is specified when the model provider has a token limit per request. The embeddings generation request should be done in batches if this is given.
   - This class must return an array of embeddings that follow the index of the given `contents` input

   You may use the existing [`Ai::ActiveContext::Embeddings::Code::VertexText`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ai/active_context/embeddings/code/vertex_text.rb)
   class as an implementation reference.

1. Update the [`Ai::ActiveContext::Collections::Code::MODELS`](https://gitlab.com/gitlab-org/gitlab/-/blob/51012cde6a104d5e2482454c2da15a161529dd9c/ee/lib/ai/active_context/collections/code.rb#L16) constant to register the new embedding model.

   You must specify the following values:

   - `field` - the embedding field or column in the index
   - `class` - the ActiveContext Embeddings class from the previous step
   - `model` - the specific model and version
   - `batch_size` - the batch size of the content array sent to AI Gateway

   Examples:

   ```ruby
   MODELS = {
     # existing supported model
     1 => {
       field: :embeddings_v1,
       class: Ai::ActiveContext::Embeddings::Code::VertexText,
       model: 'text-embedding-005',
       batch_size: EMBEDDINGS_V1_BATCH_SIZE
     },
     # new Vertex AI textembedding-gecko model, using the existing embeddings class
     2 => {
       field: :embeddings_v2,
       class: Ai::ActiveContext::Embeddings::Code::VertexText, # existing class
       model: 'text-embedding-006',
       batch_size: 50
     },
     # new model under the Anthropic provider
     3 => {
       field: :embeddings_v3,
       class: Ai::ActiveContext::Embeddings::Code::AnthropicVoyage, # new class
       model: 'voyage-code-3',
       batch_size: nil # not specified, assuming that the provider has no token limits per request
     },
   }.freeze
   ```

### Troubleshooting

#### Semantic search returns no results

**Possible causes:**

1. Repository is not indexed yet (state is `embedding_indexing_in_progress`)
   - Check: `Ai::ActiveContext::Code::Repository.find_by(project_id: project.id).state`
   - Solution: Wait for indexing to complete or manually trigger processing by running `ActiveContext.execute_all_queues!`
1. Namespace is not eligible
   - Check: `Ai::ActiveContext::Code::EnabledNamespace.exists?(namespace_id: project.root_namespace.id)`
   - Solution: Verify namespace meets eligibility criteria
1. Vector store connection is not configured
   - Check: `Ai::ActiveContext::Connection.active.present?`
   - Solution: Configure vector store connection

#### Clearing dead queue items

If embedding generation fails repeatedly, items may be placed on a dead queue. Clear them using:

```ruby
# Clear all dead queue items
ActiveContext::DeadQueue.clear_tracking!

# Or clear a specific queue
Ai::ActiveContext::Queues::Code.clear_tracking!
```
