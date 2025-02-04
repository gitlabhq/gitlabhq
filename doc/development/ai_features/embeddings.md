---
stage: Foundations
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Embeddings
---

Embeddings are a way of representing data in a vectorised format, making it easy and efficient to find similar documents.

Currently embeddings are only generated for issues which allows for features such as

- [Issue search](https://gitlab.com/gitlab-org/gitlab/-/issues/440424)
- [Find similar issues](https://gitlab.com/gitlab-org/gitlab/-/issues/407385)
- [Find duplicate issues](https://gitlab.com/gitlab-org/gitlab/-/issues/407385)
- [Find similar/related issues for Zendesk tickets](https://gitlab.com/gitlab-org/gitlab/-/issues/411847)
- [Auto-Categorize Service Desk issues](https://gitlab.com/gitlab-org/gitlab/-/issues/409646)

## Architecture

Embeddings are stored in Elasticsearch which is also used for [Advanced Search](../advanced_search.md).

```mermaid
graph LR
  A[database record] --> B[ActiveRecord callback]
  B --> C[build embedding reference]
  C -->|add to queue| N[queue]
  E[cron worker every minute] <-->|pull from queue| N
  E --> G[deserialize reference]
  G --> H[generate embedding]
  H <--> I[AI gateway]
  I <--> J[Vertex API]
  H --> K[upsert document with embedding]
  K --> L[Elasticsearch]
```

The process is driven by `Search::Elastic::ProcessEmbeddingBookkeepingService` which adds and pulls from a Redis queue.

### Adding to the embedding queue

The following process description uses issues as an example.

An issue embedding is generated from the content `"issue with title '#{issue.title}' and description '#{issue.description}'"`.

Using ActiveRecord callbacks defined in [`Search::Elastic::IssuesSearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/concerns/search/elastic/issues_search.rb), an [embedding reference](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/search/elastic/references/embedding.rb) is added to the embedding queue if it is created or if the title or description is updated and if [embedding generation is available](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/concerns/search/elastic/issues_search.rb#L38-47) for the issue.

### Pulling from the embedding queue

A `Search::ElasticIndexEmbeddingBulkCronWorker` cron worker runs every minute and does the following:

```mermaid
graph LR
  A[cron] --> B{endpoint throttled?}
  B -->|no| C[schedule 16 workers]
  C ..->|each worker| D{endpoint throttled?}
  D -->|no| E[fetch 19 references from queue]
  E ..->|each reference| F[increment endpoint]
  F --> G{endpoint throttled?}
  G -->|no| H[call AI gateway to generate embedding]
```

Therefore we always make sure that we don't exceed the rate limit setting of 450 embeddings per minute even with 16 concurrent processes generating embeddings at the same time.

### Backfilling

An [Advanced Search migration](../search/advanced_search_migration_styleguide.md) is used to perform the backfill. It essentially adds references to the queue in batches which are then processed by the cron worker as described above.

## Adding a new embedding type

The following process outlines the steps to get embeddings generated and stored in Elasticsearch.

1. Do a cost and resource calculation to see if the Elasticsearch cluster can handle embedding generation or if it needs additional resources.
1. Decide where to store embeddings. Look at the [existing indices in Elasticsearch](../../integration/advanced_search/elasticsearch.md#advanced-search-index-scopes) and if there isn't a suitable existing index, [create a new index](../advanced_search.md#add-a-new-document-type-to-elasticsearch).
1. Add embedding fields to the index: [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149209).
1. Update the way [content](https://gitlab.com/gitlab-org/gitlab/-/blob/616f92a2251fcadfec5ef3792ff3d2e4a879920a/ee/lib/search/elastic/references/embedding.rb#L43-59) is generated to accommodate the new type.
1. Add a new unit primitive: [here](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/918) and [here](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155835).
1. Use `Elastic::ApplicationVersionedSearch` to access callbacks and add the necessary checks for when to generate embeddings. See [`Search::Elastic::IssuesSearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/concerns/search/elastic/issues_search.rb) for an example.
1. Backfill embeddings: [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154940).

## Adding work item embeddings locally

### Prerequisites

1. [Make sure Elasticsearch is running](../advanced_search.md#setting-up-development-environment).
1. If you have an existing Elasticsearch setup, make sure the `AddEmbeddingToWorkItems` migration has been completed by executing the following until it returns:

   ```ruby
   Elastic::MigrationWorker.new.perform
   ```

1. Make sure you can run [GitLab Duo features on your local environment](../ai_features/_index.md#instructions-for-setting-up-gitlab-duo-features-in-the-local-development-environment).
1. Ensure running the following in a rails console outputs an embedding (a vector of 768 dimensions). If not, there is a problem with the AI setup.

   ```ruby
   Gitlab::Llm::VertexAi::Embeddings::Text.new('text', user: nil, tracking_context: {}, unit_primitive: 'semantic_search_issue').execute
   ```

### Running the backfill

To backfill work item embeddings for a project's work items, run the following in a rails console:

```ruby
Gitlab::Duo::Developments::BackfillWorkItemEmbeddings.execute(project_id: project_id)
```

The task adds the work items to a queue and processes them in batches, indexing embeddings into Elasticsearch.
It respects a rate limit of 450 embeddings per minute. Reach out to `#g_global_search` in Slack if there are any issues.

### Verify

If the following returns 0, all work items for the project have embeddings:

```shell
curl "http://localhost:9200/gitlab-development-work_items/_count" \
--header "Content-Type: application/json" \
--data '{"query": {"bool": {"filter": [{"term": {"project_id": PROJECT_ID}}], "must_not": [{"exists": {"field": "embedding_0"}}]}}}' | jq '.count'
```

Replacing `PROJECT_ID` with your project ID.
