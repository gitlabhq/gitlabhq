---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Find relevant code snippets in your repository based on meaning rather than keyword matching.
title: Semantic code search
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16910) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 18.7.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259) to GitLab Duo Core in GitLab 18.8.

{{< /history >}}

Semantic code search uses AI to find relevant code snippets
in your repository based on meaning rather than keyword matching.

Semantic code search converts your codebase into vector embeddings
and stores these embeddings in a vector database.
Your search query is also converted into an embedding and then compared against
your code embeddings to find the most semantically similar results.
This approach finds relevant code even when keywords do not match.

Improvements to this feature are proposed in [epic 18018](https://gitlab.com/groups/gitlab-org/-/epics/18018)
and [epic 20110](https://gitlab.com/groups/gitlab-org/-/epics/20110).

## Prerequisites

- Access to the GitLab-operated [AI Gateway](../../administration/gitlab_duo/gateway.md).
- These features turned on:
  - For GitLab.com, experiment features for your top-level namespace.
  - For GitLab Self-Managed, GitLab Duo experiment and beta features for the instance.
- [GitLab Duo](turn_on_off.md#turn-gitlab-duo-on-or-off) turned on for your project.
- A supported vector store configured:
  - Elasticsearch 8.0 and later.
  - OpenSearch 2.0 and later.
- Administrator access.

## Enable semantic code search

### With the UI

If your GitLab instance uses Elasticsearch or OpenSearch for advanced search,
you can enable semantic code search by connecting to the same cluster:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Semantic search**.
1. Select **Connect to the advanced search cluster**.

### With the Rails console

To create a custom vector store connection for Elasticsearch or OpenSearch,
in the Rails console, create a connection with `adapter` and `options`.

#### Elasticsearch

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elasticsearch",
  options: { url: ["http://your-elasticsearch-url:9200"] },
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter"
)
connection.activate!
```

Connection options:

| Option                   | Type             | Required | Default    | Description |
|--------------------------|------------------|----------|------------|-------------|
| `url`                    | array of strings | Yes      | None       | Array of URLs for your Elasticsearch cluster (for example, `["http://localhost:9200"]`). |
| `client_adapter`         | string           | No       | `typhoeus` | HTTP adapter to use. Possible values are `typhoeus` and `net_http`. |
| `client_request_timeout` | integer          | No       | `30`       | Request timeout in seconds. |
| `retry_on_failure`       | integer          | No       | `0`        | Number of retries on failure. |
| `debug`                  | boolean          | No       | `false`    | Enables debug logging. |

#### OpenSearch

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "opensearch",
  options: { url: ["http://your-opensearch-url:9200"] },
  adapter_class: "ActiveContext::Databases::Opensearch::Adapter"
)
connection.activate!
```

Connection options:

| Option                   | Type             | Required | Default    | Description |
|--------------------------|------------------|----------|------------|-------------|
| `url`                    | array of strings | Yes      | None       | Array of URLs for your OpenSearch cluster (for example, `["http://localhost:9200"]`). |
| `client_adapter`         | string           | No       | `typhoeus` | HTTP adapter to use. Possible values are `typhoeus` and `net_http`. |
| `client_request_timeout` | integer          | No       | `30`       | Request timeout in seconds. |
| `retry_on_failure`       | integer          | No       | `0`        | Number of retries on failure. |
| `debug`                  | boolean          | No       | `false`    | Enables debug logging. |
| `aws`                    | boolean          | No       | `false`    | Enables AWS Signature Version 4 signing. |
| `aws_region`             | string           | No       | None       | AWS region for your OpenSearch domain. |
| `aws_access_key`         | string           | No       | None       | AWS access key ID. |
| `aws_secret_access_key`  | string           | No       | None       | AWS secret access key. |

## Use semantic code search

Semantic code search is available as a GitLab MCP server tool.
For more information about how to use this tool, see
[`semantic_code_search`](model_context_protocol/mcp_server_tools.md#semantic_code_search).

When you first use semantic code search in a GitLab project:

- Your repository code is indexed and converted into vector embeddings.
- These embeddings are stored in your configured vector store.
- Updates are processed incrementally when code is merged to the default branch.

Initial indexing might take a few minutes depending on your repository size.
