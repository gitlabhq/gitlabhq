---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Semantic Search
---

Semantic Search uses vector embeddings to find semantically similar content based on meaning rather than keyword matching, enabling AI features like Duo Chat to retrieve relevant context for user queries.

## Overview

Semantic Search converts text into vector embeddings and stores them in a vector store. When a user makes a query, the query is also converted to an embedding and compared against stored vectors to find the most similar results. This approach captures semantic meaning, allowing searches to find relevant content even when exact keywords don't match.

Semantic Search features are implemented using the Active Context framework.

[**Semantic Code Search**](semantic_code_search.md) is the first feature implemented with this framework.
You can add support for other [Semantic Search Collection types](adding_semantic_search_collections.md).

## How it works

For how Semantic Search works using the Active Context framework, see [Active Context](active_context.md).

## Developer Guide

### Configuring the Active Context initializer

Active Context is configured in
[`config/initializers/active_context.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/active_context.rb)
with these options:

- `enabled`: Turns on Active Context. When `false`, indexing is also turned off. Defaults to `false`.
- `indexing_enabled`: When `false`, queue processing exits early. Defaults to `false`.
- `re_enqueue_indexing_workers`: When `true`, each job re-enqueues itself every second until its queue shard is empty,
  which increases indexing throughput. Defaults to `false`.
- `logger`: The logger to use. GitLab uses `Gitlab::ActiveContext::Logger`. Defaults to `Logger.new($stdout)`.
- `queue_classes`: The [queue](active_context.md#queues) classes to process.
  Each class must include `ActiveContext::Concerns::Queue`. Defaults to `[]`.

### Creating a connection

A vector store connection must be created before semantic search can be used. There are two ways to configure the connection:

#### Option 1: Using the GitLab UI

To configure the connection in the **Admin** area, see [vector storage for semantic code search](../../../administration/semantic_code_search.md#vector-storage).

#### Option 2: Using Rails console

Use one of the following approaches. The `name` field is a user-defined label.

To connect with an explicit URL (for example, OpenSearch):

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "opensearch",
  options: { url: ["http://localhost:9202"] },
  adapter_class: "ActiveContext::Databases::Opensearch::Adapter"
)
connection.activate!
```

To reuse credentials from an existing advanced search cluster:

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elasticsearch",
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter",
  options: { use_advanced_search_config: true }
)
connection.activate!
```

For PostgreSQL, use the `pgvector` extension:

1. In the PostgreSQL database, create the extension:

   ```sql
   CREATE EXTENSION vector;
   ```

1. In the Rails console, create the connection:

   ```ruby
   connection = Ai::ActiveContext::Connection.create!(
     name: "postgres",
    options: { host: 'localhost', port: 5432, user: 'postgres', password: '<password>', database: 'postgres' },
     adapter_class: "ActiveContext::Databases::Postgresql::Adapter"
   )
   connection.activate!
   ```

For more information, see the [`pgvector` documentation](https://github.com/pgvector/pgvector).

For the supported adapters, see [vector stores](active_context.md#vector-stores).

The `options` hash holds the connection details for the adapter:

- Elasticsearch: `url`, `client_request_timeout`, `retry_on_failure`, `debug`, or `use_advanced_search_config`
  to reuse the advanced search cluster settings.
- OpenSearch: The Elasticsearch options, plus `aws`, `aws_region`, `aws_access_key`, and `aws_secret_access_key`.
- PostgreSQL: `host`, `port`, `user`, `password`, `database`, `pool_size`, and `connect_timeout`.

Only one connection can be active at a time.
`activate!` deactivates the current active connection and activates the new one.
Deactivation is destructive: a background worker drops the deactivated connection's collections from the vector store and deletes the connection record and its associated data.

### Writing a migration

For how migrations are applied, see [migrations](active_context.md#migrations).

To add a migration, create a file in `ee/active_context/migrate/` that subclasses `ActiveContext::Migration[1.0]`.
Set the `milestone` and implement `migrate!`.

For example, to create a collection:

```ruby
# frozen_string_literal: true

class CreateMergeRequests < ActiveContext::Migration[1.0]
  milestone '<milestone>'

  def migrate!
    create_collection :merge_requests, number_of_partitions: 3 do |c|
      c.bigint :issue_id, index: true
      c.bigint :namespace_id, index: true
      c.integer :iid, index: true
      c.smallint :priority, index: true
      c.boolean :is_draft
      c.keyword :traversal_ids
      c.text :description
      c.vector :embeddings, dimensions: 768
    end
  end
end
```

Collection schemas support these field types:

- `bigint`: Large numeric values. Accepts `index: true/false`, defaults to `false`.
- `integer`: Standard numeric values. Accepts `index: true/false`, defaults to `false`.
- `smallint`: Small numeric values. Accepts `index: true/false`, defaults to `false`.
- `boolean`: Boolean values. Accepts `index: true/false`, defaults to `false`.
- `keyword`: Exact-match searchable strings. Always indexed, no `index` option.
- `text`: Full-text searchable content. No `index` option.
- `vector`: Embedding vectors. Accepts `index: true/false`, defaults to `true`. Requires `dimensions:`.

To update a collection's metadata, use `update_collection_metadata(collection:, metadata:)`.

A migration can define `skip?` to skip execution under certain conditions.
For an example, see
[`20260521000000_set_default_chunk_strategy.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/active_context/migrate/20260521000000_set_default_chunk_strategy.rb).

To run outstanding migrations without waiting for the cron worker:

```ruby
Ai::ActiveContext::MigrationWorker.new.perform
```

### Resetting Semantic Search data

To start fresh with a new connection, destroy all existing data:

```ruby
active_connection = ::Ai::ActiveContext::Connection.active
active_connection.migrations.destroy_all
active_connection.repositories.destroy_all
active_connection.enabled_namespaces.destroy_all
active_connection.collections.destroy_all
active_connection.destroy
```

Then [create a connection](#creating-a-connection).

### Managing queued items

View all queued items waiting to be processed:

```ruby
ActiveContext::Queues.all_queued_items
```

Immediately process all queued items without waiting for cron workers:

```ruby
ActiveContext.execute_all_queues!
```

Remove all items from a queue:

```ruby
Ai::ActiveContext::Queues::Code.clear_tracking!
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

To search a collection, build a query with `ActiveContext::Query` and pass it to the collection's `search` method.
For example, to find the documents in a project that are closest to some text:

```ruby
collection = Ai::ActiveContext::Collections::Code
embedding_model = collection.search_embedding_model
vector = embedding_model.generate_embeddings('user authentication logic', user: current_user).first

query = ActiveContext::Query
  .filter(project_id: project.id)
  .knn(target: embedding_model.field, vector: vector, k: 10)
  .limit(10)

collection.search(user: current_user, query: query).to_a
```

To generate the query embedding from text with the collection's search embedding model, pass `content:` instead of `target:` and `vector:`:

```ruby
query = ActiveContext::Query.filter(project_id: project.id).knn(content: 'user authentication logic', k: 10)
```

`ActiveContext::Query` also supports `and`, `or`, and `prefix` conditions.
For more examples, see `Ai::ActiveContext::Queries::Code`.

### Setting or switching an embedding model

For how the switch works, see [model switching](active_context.md#model-switching).

To set or switch the embedding model for a collection, [update it in the Admin area](../../../administration/semantic_code_search.md#configure-an-embedding-model),
or run `EmbeddingModelActivationService` in the Rails console:

```ruby
::Ai::ActiveContext::EmbeddingModelActivationService.new(
  collection_class: ::Ai::ActiveContext::Collections::Code,
  model_type: 'gitlab_managed',
  model_ref: 'text_embedding_005_vertex',
  dimensions: 768,
  chunk_strategy: 'code_bytes',
  chunk_strategy_size: 1000,
  user: User.first
).execute!
```

- `collection_class`, `model_ref`, and `dimensions` are required.
- `model_type` is `gitlab_managed` or `self_hosted`.
  `model_type` and `user` are required when users select the embedding model, for example on GitLab Self-Managed.
- `embeddings_request_batch_size`, `chunk_strategy`, and `chunk_strategy_size` are optional.

### Semantic Search for Duo Self-hosted

1. [Set up your GDK for Duo Self-hosted](../developing_ai_features_for_duo_self_hosted.md)
1. Set up Self-hosted embedding models
   1. Make sure to clear the persisted embedding model metadata so that you are not using the metadata for SaaS

      ```ruby
      ::Ai::ActiveContext::Collections::Code.collection_record.update_metadata!(
        current_indexing_embedding_model: nil,
        search_embedding_model: nil,
        next_indexing_embedding_model: nil
      )
      ```

   1. [Set the embedding model](#setting-or-switching-an-embedding-model).

### Adding a new embedding model to the GitLab offering

To support a new GitLab-managed embedding model, add it to the Model Selection catalog in AI Gateway.

#### 1. Add to `models.yml`

In [`ai_gateway/model_selection/models.yml`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/model_selection/models.yml),
add a new entry for the model, and set the following fields:

- `gitlab_identifier`: the global model identifier used across all GitLab apps. This follows the format of `<model_name>_<provider>`
- `model_class_provider`: always `litellm_embedding`
- `family`: set `embedding` as one of the entries

For the full entry, refer to the following example:

```yaml
models:
  - name: "text-embedding-005"
    provider: "Gemini Enterprise Agent Platform"
    gitlab_identifier: "text_embedding_005_vertex"
    description: "Natural language processing technique that converts textual data into numerical vectors."
    cost_indicator: "$"
    max_context_tokens: 20000 # https://docs.cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings#api_limits
    model_class_provider: litellm_embedding
    family:
      - vertex
      - embedding
    params:
      model: "text-embedding-005"
      custom_llm_provider: vertex_ai
    prompt_params:
      vertex_location: global
```

#### 2. Add to `unit_primitives.yml`

In [`ai_gateway/model_selection/unit_primitives.yml`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/model_selection/unit_primitives.yml), add the new model as a selectable model under the relevant feature setting.

For Semantic Code Search, add the new model under the [`embeddings_code` feature setting](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/4acc4c57eae521583149a9feec169d847bed76aa/ai_gateway/model_selection/unit_primitives.yml#L332).

For new Semantic Search Collections, you must add a new feature setting entry.

### Embeddings generation on AI Gateway

The [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
generates embeddings by routing requests through the same `Prompt` object used for chat and completion prompts.
This approach lets embeddings reuse existing AI Gateway capabilities such as model selection,
prompt registry resolution and prompt invocation, and observability and instrumentation.

#### Overview of end-to-end flow

1. **Embeddings request:** a client sends an
   [embeddings request](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md#embeddings)
   to the AI Gateway.

   For Code Embeddings, the endpoint implementations are found in `ai_gateway/api/v1/embeddings/code_embeddings.py`.

1. **[Model Selection](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/model_selection.md):**
   A `ModelMetadata` object is resolved from the request parameters through the `create_model_metadata` method.

   The `ModelMetadata` carries the model metadata from the request parameters as well as the `llm_definition` object,
   which contains the `model_class_provider`. For embeddings, the `model_class_provider` is `'litellm_embedding'`
   (enum key: `ModelClassProvider.LITE_LLM_EMBEDDING`).

1. **[Prompt Registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/aigw_prompt_registry.md):**
   A `Prompt` object is created through `prompt_registry.get_on_behalf(...)`, with the parameters
   `prompt_id` (`"embeddings_code"`) and `model_metadata` (the created `ModelMetadata` object).

   The `Prompt` object contains the `model_factory` and `prompt_template_factory` based on the `model_class_provider`.

   For embeddings, the `model_factory` is `lite_llm_embedding_fn`, which specifies `EmbeddingLiteLLM` as the
   actual model class to invoke for embeddings generation.

   Unlike other models, embeddings generation does not require a prompt template, so the Prompt Registry
   uses a passthrough prompt template factory (`embedding_prompt_template_factory`).

1. **Invocation:** Embeddings generation is invoked through `prompt.ainvoke`, which under the hood invokes the
   actual model class (`EmbeddingLiteLLM`). Since embeddings uses a passthrough prompt template, the parameters
   passed to `prompt.ainvoke` (`contents`, `dimensions`, and so on) are passed directly to `EmbeddingLiteLLM.ainvoke`.

   `prompt.ainvoke` also handles retries, instrumentation, and internal events tracking.

1. **The `EmbeddingLiteLLM` class:** This implements the actual calls to
   [LiteLLM `/embeddings`](https://docs.litellm.ai/docs/embedding/supported_embedding), supporting
   async invocations (`litellm.aembedding`).

   This class translates the parameters from the `Prompt` invocation to the format expected by `litellm`,
   and in turn transforms the `litellm.aembedding` result to an object type expected by the `Prompt`.
   It also transforms expected `litellm` exception classes to types expected by endpoint implementation in
   `ai_gateway/api/v1/embeddings/code_embeddings.py`.

#### `model_metadata` for GitLab-managed vs self-hosted models

AI Gateway determines the type of model based on the request parameter's `model_metadata` payload.

For GitLab-managed models:

- `model_metadata['provider']='gitlab'`
- `model_metadata['name']` should not be specified
- `model_metadata['identifier']` refers to the `gitlab_identifier` in the `ai_gateway/model_selection/models.yml` lookup
- Additional model metadata such as custom parameters and model family are specified in the
  `ai_gateway/model_selection/models.yml` entry

For Self-hosted models:

- `model_metadata['provider']='litellm'`
- `model_metadata['name']='embedding'`
- `model_metadata['identifier']` refers to the [Self-hosted model identifier](../../../administration/gitlab_duo_self_hosted/offline_deployment.md#add-the-self-hosted-model)
- `model_metadata['endpoint']` is required
- `model_metadata['api_key']` can be set optionally

Any other `model_metadata` configuration is not accepted and will result in a `422` error.

## Troubleshooting

### Semantic search returns no results

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

### Managing dead queue items

If embedding generation fails repeatedly, items are placed on the dead queue. Use the Admin API to manage them without a Rails console.

**Check dead queue size**

The dead queue size is visible in the `Embedding Queues` section of the Rake task output:

```shell
sudo gitlab-rake gitlab:semantic_search:code:info
```

**Clear all dead queue items**

To discard all dead queue items:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_token>" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue"
```

Or through chatops:

```plaintext
/chatops gitlab run active_context dead_queue clear
```

**Replay dead queue items into a processing queue**

To move dead queue items back into a processing queue for another attempt:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --data "queue=retry_queue" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue/replay"
```

Or through chatops (recommended):

```plaintext
/chatops gitlab run active_context dead_queue replay --queue=retry_queue
```

Valid queue values are `retry_queue`, `second_retry_queue`, `third_retry_queue`,
`fourth_retry_queue`, `code`, and `code_backfill`. Use `retry_queue` to run items through
the full retry chain again. Use `code` to restart the full embedding pipeline from scratch.
