---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Administer and configure semantic code search on GitLab Self-Managed instances.
title: Semantic code search administration
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16910) as a [beta](../policy/development_stages_support.md#beta) in GitLab 18.7.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259) to GitLab Duo Core in GitLab 18.8.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/590394) to GitLab Premium in GitLab 18.9.

{{< /history >}}

> [!note]
> For user documentation, see [semantic code search](../user/gitlab_duo/semantic_code_search.md).

With semantic code search, AI-native GitLab Duo features
can find relevant code snippets in your repository.

## Prerequisites

- Access to the [GitLab AI Gateway](gitlab_duo/gateway.md) or [GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md).
- Beta and experimental features turned on [for the instance](../user/duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-2).
- [A vector store configured](#vector-storage):
  - Elasticsearch 8.0 and later.
  - OpenSearch 2.0 and later.
  - PostgreSQL with the [`pgvector`](https://github.com/pgvector/pgvector) extension.
- For GitLab Duo Self-Hosted, [an embedding model configured](#configure-an-embedding-model).

## Vector storage

You should use Elasticsearch or OpenSearch for medium to large repositories.
Use PostgreSQL with `pgvector` only for setups with a few small repositories.
Indexing and querying performance might be limited with `pgvector`.

### Connect to the advanced search cluster

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/18905) in GitLab 18.7.

{{< /history >}}

If your GitLab instance uses Elasticsearch or OpenSearch for [advanced search](../user/search/advanced_search.md),
you can turn on semantic code search by connecting to the same cluster:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Search**.
1. Expand **Semantic search**.
1. For **Vector storage**, select **Configure**.
1. On the **Vector storage** page, under **Advanced search cluster**, select **Connect**.

### Configure a custom vector store

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585318) in GitLab 19.2.

{{< /history >}}

To configure a custom vector store connection:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Search**.
1. Expand **Semantic search**.
1. For **Vector storage**, select **Configure**.
1. From the **Search adapter** dropdown list, select
   **Elasticsearch**, **OpenSearch**, or **PostgreSQL**.
1. Complete the fields for your adapter.
1. Select **Save changes**.

#### Elasticsearch

| Setting      | Description |
|--------------|-------------|
| **URL**      | Comma-separated list of URLs for your Elasticsearch cluster (for example, `http://localhost:9200, http://localhost:9201`). |
| **Username** | Username of password-protected Elasticsearch servers. |
| **Password** | Password of password-protected Elasticsearch servers. |

#### OpenSearch

| Setting      | Description |
|--------------|-------------|
| **URL**      | Comma-separated list of URLs for your OpenSearch cluster (for example, `http://localhost:9200, http://localhost:9201`). |
| **Username** | Username of password-protected OpenSearch servers. |
| **Password** | Password of password-protected OpenSearch servers. |

To use AWS OpenSearch Service, select **Use AWS OpenSearch Service with IAM credentials**
and complete the fields:

| Setting                   | Description |
|---------------------------|-------------|
| **AWS region**            | AWS region of your OpenSearch domain. |
| **AWS Access Key**        | AWS access key ID. Required only if you're not using role instance credentials. |
| **AWS Secret Access Key** | AWS secret access key. Required only if you're not using role instance credentials. |
| **AWS Role ARN**          | AWS IAM role ARN of `AssumeRole` authorization across accounts. |

#### PostgreSQL with `pgvector`

Prerequisites:

- Enable the [`pgvector`](https://github.com/pgvector/pgvector) extension in your PostgreSQL database:

  ```sql
  CREATE EXTENSION vector;
  ```

| Setting      | Description |
|--------------|-------------|
| **Host**     | Host name of the PostgreSQL server. |
| **Port**     | Port of the PostgreSQL server. Default is `5432`. |
| **Database** | Name of the PostgreSQL database. |
| **Username** | PostgreSQL username. |
| **Password** | PostgreSQL password. |

## Configure an embedding model

To configure an embedding model:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Search**.
1. Expand **Semantic search**.
1. For **Code embeddings**, select **Set model**.
   If you already configured an embedding model, **Change model** appears instead.
1. On the **Semantic search code embeddings** page,
   select the embedding model, embedding dimensions, and the chunking strategy.
1. Select **Set embeddings**. If you already configured an embedding model,
   **Update embeddings and start backfill process** appears instead.

> [!warning]
> When you change the embedding model or dimensions, a backfill runs
> that can take several hours depending on your codebase size.
> Semantic search remains available during this process.

### Embedding models

#### GitLab-managed models

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/582638) in GitLab 19.0 [with a feature flag](feature_flags/_index.md) named `semantic_search_user_model_selection`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- Access to both the [GitLab AI Gateway](gitlab_duo/gateway.md) and [GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md).

GitLab-managed models are offered on the [GitLab AI Gateway](gitlab_duo/gateway.md).
Select the `text-embedding-005` model provided by the Gemini Enterprise Agent Platform.

For more information about GitLab-managed models with a
[GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md) setup,
see [hybrid AI Gateway and model configuration](gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration).

> [!warning]
> If GitLab deprecates a model you selected, you must switch to a different model yourself.

#### Self-hosted models

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588849) in GitLab 19.1 [with a feature flag](feature_flags/_index.md) named `semantic_search_user_model_selection`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- Access to [GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md).
- [Self-hosted beta models and features turned on](gitlab_duo_self_hosted/configure_duo_features.md#turn-on-self-hosted-beta-models-and-features).

Self-hosted models are AI models [hosted on your own infrastructure](gitlab_duo_self_hosted/_index.md).

To select a self-hosted model:

1. Set up [GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md).
1. [Add a self-hosted model](gitlab_duo_self_hosted/configure_duo_features.md#add-a-self-hosted-model) with an `EMBEDDING` model family.

### Chunking strategy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/600201) in GitLab 19.2 [with a feature flag](feature_flags/_index.md) named `semantic_search_user_model_selection`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

The chunking strategy is the algorithm used to split code files into smaller snippets for embeddings.
Select one of the following strategies:

- Code bytes:
  Splits code into fixed-size byte chunks without considering code structure or semantics.
  Chunk size refers to the maximum number of bytes per chunk.
  Use this strategy for the following:
  - Faster indexing and more predictable chunk size.
  - Repositories with diverse file types and languages.
- Code pre-BERT:
  Splits code by using semantic boundaries optimized for BERT-based embedding models.
  Chunk size refers to the maximum number of tokens per chunk.
  Use this strategy for the following:
  - Better search quality and more meaningful chunks that respect code structure.
  - Repositories with well-structured code.

> [!warning]
> You can select the chunking strategy only when you configure the embedding model for the first time.
> To change the chunking strategy after indexing starts, you must fully reindex the instance.
> Support for automatic reindexing is proposed in [issue 600200](https://gitlab.com/gitlab-org/gitlab/-/work_items/600200) and [issue 602138](https://gitlab.com/gitlab-org/gitlab/-/work_items/602138).

## Check semantic code search status

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/596795) in GitLab 19.0.

{{< /history >}}

To check the status of semantic code search, including indexing status,
vector store connection details, repository statistics,
and embedding queue sizes, run this Rake task:

```shell
sudo gitlab-rake gitlab:semantic_search:code:info
```

To monitor status continuously, provide a watch interval in seconds:

```shell
sudo gitlab-rake "gitlab:semantic_search:code:info[5]"
```

This task refreshes the output at the specified interval.
To stop the task, press <kbd>Control</kbd>+<kbd>C</kbd>.

## Manage the dead queue

Prerequisites:

- A personal access token with the `admin_mode`, `ai_features`, and `api` scopes.

When embedding generation fails repeatedly, items are moved to the dead queue for manual intervention.
You can check the dead queue size in the `Embedding Queues` section of the
[status Rake task](#check-semantic-code-search-status) output.

### Clear the dead queue

To delete all items from the dead queue, run this command:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_token>" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue"
```

### Replay the dead queue

To move dead queue items back into a processing queue for another attempt,
use the `queue` parameter to specify the target.
Valid values are `retry_queue`, `code`, and `code_backfill`.

To attempt processing once more before potentially failing back to the dead queue,
use `retry_queue`:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --data "queue=retry_queue" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue/replay"
```

To add items to the main code queue, use `code`:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --data "queue=code" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue/replay"
```
