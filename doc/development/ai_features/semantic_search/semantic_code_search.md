---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Semantic Code Search
---

## Overview

Semantic Code Search is the first feature offered under Semantic Search. It enables Duo Chat and other AI features to find relevant code snippets from a repository. The feature is available as an [MCP tool (`semantic_code_search`)](../../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#semantic_code_search) that can be used by GitLab Duo Agent Platform and other AI platforms.

## Architecture

### Semantic Code Search embedding model

The Semantic Code Search embedding model depends on the GitLab instance.

For SaaS, Dedicated, and Self-Managed instances without Duo Self-hosted, the model used for embeddings generation is
`text-embedding-005` provided by Gemini Enterprise Agent Platform.

For Self-Managed instances with Duo Self-hosted, administrators must select their own Self-hosted embedding model.

### Indexing workflow

#### Initial indexing

When the Semantic Code Search tool is invoked for a project that hasn't been indexed yet:

1. **Repository record creation**: An `Ai::ActiveContext::Code::Repository` record is created with `pending` state
1. **Index worker**: The `Ai::ActiveContext::Code::RepositoryIndexWorker` processes the `pending` repository
1. **Initial indexing**:
   1. The `Ai::ActiveContext::Code::InitialIndexingService` calls the `Ai::ActiveContext::Code::Indexer`
   1. The `Ai::ActiveContext::Code::Indexer` runs the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to fetch the repository's files from Gitaly, chunk the code, and index the chunks in the vector store
   1. The `Ai::ActiveContext::Code::InitialIndexingService` enqueues the references/IDs of the indexed content for embeddings generation
1. **Async processing**: Queued content references are picked up for embeddings generation through the asynchronous `Ai::ActiveContext::BulkProcessWorker`.
1. **Tool not available**: The user is notified that indexing is in progress and should try again in a few minutes.
1. **Ready check**: The `Ai::ActiveContext::Code::MarkRepositoryAsReadyEventWorker` runs on a 10-minute cron schedule (through `Ai::ActiveContext::Code::SchedulingService`) and checks if all embeddings have been generated. Once all embeddings are ready, it marks the repository as `ready`
1. **Available for queries**: The next time the tool is invoked, the repository is ready and can be used for semantic search queries

#### Incremental indexing

When code is merged into the default branch:

1. **Push event**: A push event triggers the incremental indexing process through the `Git::BranchPushService`
1. **Index worker**: The `Ai::ActiveContext::Code::RepositoryIndexWorker` processes the `ready` ActiveContext repository
1. **Incremental Indexing** - only the changed files are processed
   1. The `Ai::ActiveContext::Code::IncrementalIndexingService` calls the `Ai::ActiveContext::Code::Indexer`
   1. The `Ai::ActiveContext::Code::Indexer` runs the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to fetch the changed files from Gitaly, chunk the code, and index the chunks in the vector store. It also deletes orphaned data from the vector store.
   1. The `Ai::ActiveContext::Code::IncrementalIndexingService` enqueues the references/IDs of the indexed content for embeddings generation
1. **Async processing**: Queued content references are picked up for embeddings generation through the asynchronous `Ai::ActiveContext::BulkProcessWorker`.

### Deletion workflow

When a namespace is no longer eligible for indexing, `Ai::ActiveContext::Code::ProcessInvalidEnabledNamespaceEventWorker` picks it up and deletes the `Ai::ActiveContext::Code::EnabledNamespace` record.

When a repository is no longer eligible for indexing, `Ai::ActiveContext::Code::MarkRepositoryAsPendingDeletionEventWorker` marks it as `pending_delete`. The `Ai::ActiveContext::Code::RepositoryIndexWorker` then processes the repository and calls the [`gitlab-elasticsearch-indexer`](#gitlab-elasticsearch-indexer) to delete the project's documents from the vector store and delete the repository record.

### `gitlab-elasticsearch-indexer`

The [`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) Go project handles:

- fetching the repository's files from Gitaly
- chunking the files
- indexing the chunked content on the vector store
- deleting orphaned data
- deleting all data for a project

**Chunking**

The `gitlab-elasticsearch-indexer` makes use of the [`gitlab-code-parser`](https://gitlab.com/gitlab-org/rust/gitlab-code-parser) library to split the code into logic chunks.

The chunking process uses a two-stage approach:

1. _AST-aware chunking_: The code chunker parses each file and identifies logical split points (function definitions, class definitions, and similar constructs)
1. _Size-based fallback_: If no AST split points are available, the chunker falls back to splitting on line boundaries while respecting a maximum byte size

This approach ensures chunks are semantically meaningful while staying within size limits for embedding generation.

### Namespace eligibility

Not all namespaces are eligible for Semantic Code Search. Eligibility is managed through two workers:

**`Ai::ActiveContext::Code::CreateEnabledNamespaceEventWorker`** (runs daily through `Ai::ActiveContext::Code::SchedulingService`)

- Identifies and enables eligible namespaces
- Creates `Ai::ActiveContext::Code::EnabledNamespace` records for qualifying namespaces

**On GitLab.com**, a namespace is eligible if:

- AI features are enabled in the namespace settings
- The namespace has a supported AI plan (Premium or higher)
- The subscription is not expired

**On self-managed instances**, all top-level group namespaces are eligible if:

- Instance-level AI beta features are enabled (`instance_level_ai_beta_features_enabled`)
- AI features are available in the license

**`Ai::ActiveContext::Code::MarkRepositoryAsPendingDeletionEventWorker`** marks repositories for deletion when they no longer meet eligibility criteria.

**`Ai::ActiveContext::Code::ProcessInvalidEnabledNamespaceEventWorker`** cleans up `Ai::ActiveContext::Code::EnabledNamespace` records for namespaces that no longer meet eligibility criteria.

### Supported file types

Semantic Code Search indexes all files in a repository. Currently, results are post-filtered to exclude files matching the project's exclusion rules. Future versions will stop indexing excluded files entirely for improved efficiency.

### MCP implementation

For more information about GitLab MCP implementation and available clients, see the [GitLab MCP documentation](../../../user/gitlab_duo/model_context_protocol/mcp_clients.md) and the [runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/ai-active-context).

Currently, the Semantic Code Search tool is available in IDEs when GitLab MCP is configured. With the rollout of the `mcp_client` feature flag, it will be available on the web.

## Enabling Semantic Code Search

### Prerequisites

- `ActiveContext` gem configured in `config/initializers/active_context.rb`:

  ```ruby
  ActiveContext.configure do |config|
    config.enabled = true
    config.indexing_enabled = true
    config.logger = ::Gitlab::ActiveContext::Logger.build

    config.queue_classes = []
    if Gitlab.ee?
      config.queue_classes.concat([
        ::Ai::ActiveContext::Queues::Code,
        ::Ai::ActiveContext::Queues::CodeBackfill
      ])
    end
  end
  ```

- Vector store connection configured (Elasticsearch, OpenSearch, or PostgreSQL with pgvector).
- [AI Gateway configured](../duo_agent_platform.md)
- [Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/embeddings) credentials configured for embedding generation.
- [Beta experiment features setting enabled](../../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) for the instance.

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

**Embedding generation**

Test that embedding generation is configured:

```ruby
model_metadata = {
  model_ref: 'text_embedding_005_vertex',
  field: 'test_field_v1',
  dimensions: 768
}
::Ai::ActiveContext::Embeddings::ModelFactory
  .for(model_metadata)
  .generate_embeddings('test', user: User.first)
```

This should return a vector.

**Beta experiment features**

Verify that beta experiment features are enabled for the namespace:

```ruby
namespace.experiment_features_enabled?
```

This should return `true`.

## Disabling Semantic Code Search

> [!warning]
> Disabling semantic code search can cause long database locks if there are many repository records to delete.
> Use with caution on production environments. Upcoming work will allow disabling safely.
> See [issue 582787](https://gitlab.com/gitlab-org/gitlab/-/issues/582787).

Delete the index and collection record:

```ruby
ActiveContext.adapter.executor.drop_collection(:code)
```

Delete the connection and associated records:

```ruby
::Ai::ActiveContext::Connection.active.destroy!
```

## Setting up MCP locally

To set up the MCP server locally for development and testing, see the [MCP server development guide](../../duo_agent_platform/mcp/_index.md).

> [!note]
> Ask for the `semantic_code_search` tool in your prompt to ensure the tool is used.

## Using Semantic Code Search

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
