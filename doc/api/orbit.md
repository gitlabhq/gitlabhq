---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to run queries, retrieve schemas, and check cluster health for Orbit.
title: Orbit API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19744) in GitLab 18.10 [with a feature flag](../administration/feature_flags/_index.md) named `knowledge_graph`. This feature is an [experiment](../policy/development_stages_support.md) and subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Use this API to run queries, retrieve schemas, and check cluster health for
[Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph).

## Create a query

Creates and executes a query against the Orbit gRPC service.

```plaintext
POST /api/v4/orbit/query
```

Supported attributes:

| Attribute         | Type   | Required | Description                                                |
|-------------------|--------|----------|------------------------------------------------------------|
| `query`           | object | Yes      | The query DSL object.                                      |
| `query_type`      | string | No       | The query language. Only `json` is supported. Default is `json`. |
| `response_format` | string | No       | One of `raw` or `llm`. Default is `raw`.                   |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                                              |
|---------------------|-----------------|----------------------------------------------------------|
| `result`            | array or string | The query results. An array when `raw`, a string when `llm`. |
| `query_type`        | string          | The query language, for example `json`.                  |
| `raw_query_strings` | string array    | The underlying queries that were run.                    |
| `row_count`         | integer         | The number of rows returned.                             |

### Examples

Retrieve a user by username:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "search",
      "node": {"id": "u", "entity": "User", "filters": {"username": "john_smith"}}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": [
    {
      "u_id": 1,
      "u_username": "john_smith",
      "u_name": "John Smith",
      "u_state": "active",
      "u_type": "User"
    }
  ],
  "query_type": "search",
  "row_count": 1
}
```

Find merged merge requests in a project:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "traversal",
      "nodes": [
        {"id": "p", "entity": "Project", "node_ids": [8]},
        {"id": "mr", "entity": "MergeRequest", "filters": {"state": "merged"}}
      ],
      "relationships": [{"type": "IN_PROJECT", "from": "mr", "to": "p"}]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": [
    {
      "p_name": "Diaspora Client",
      "p_full_path": "diaspora/diaspora-client",
      "mr_id": 43,
      "mr_iid": 1,
      "mr_title": "Resolve connection timeout on large payloads",
      "mr_state": "merged"
    },
    {
      "mr_id": 44,
      "mr_iid": 2,
      "mr_title": "Replace deprecated API calls in federation module",
      "mr_state": "merged"
    }
  ],
  "query_type": "traversal",
  "row_count": 2
}
```

Count merge requests per project:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "aggregation",
      "nodes": [
        {"id": "p", "entity": "Project"},
        {"id": "mr", "entity": "MergeRequest"}
      ],
      "relationships": [{"type": "IN_PROJECT", "from": "mr", "to": "p"}],
      "aggregations": [{"function": "count", "target": "mr", "group_by": "p", "alias": "mr_count"}]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": [
    {"p_name": "Diaspora Client", "p_full_path": "diaspora/diaspora-client", "mr_count": 8},
    {"p_name": "Puppet", "p_full_path": "brightbox/puppet", "mr_count": 6}
  ],
  "query_type": "aggregation",
  "row_count": 2
}
```

Find outgoing neighbors of a user:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "neighbors",
      "node": {"id": "u", "entity": "User", "node_ids": [43]},
      "neighbors": {"node": "u"}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": [
    {
      "_gkg_relationship_type": "MEMBER_OF",
      "_gkg_neighbor_type": "Project",
      "id": 5,
      "name": "Diaspora Client"
    },
    {
      "_gkg_relationship_type": "MEMBER_OF",
      "_gkg_neighbor_type": "Group",
      "id": 29,
      "name": "diaspora"
    },
    {
      "_gkg_relationship_type": "AUTHORED",
      "_gkg_neighbor_type": "MergeRequest",
      "id": 43,
      "title": "Resolve connection timeout on large payloads"
    }
  ],
  "query_type": "neighbors",
  "row_count": 3
}
```

Find the shortest path between two projects:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "path_finding",
      "nodes": [
        {"id": "p1", "entity": "Project", "node_ids": [8]},
        {"id": "p2", "entity": "Project", "node_ids": [5]}
      ],
      "path": {"type": "shortest", "from": "p1", "to": "p2", "max_depth": 3}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": [
    {
      "depth": 2,
      "path": [
        {"id": 8, "entity_type": "Project", "name": "Diaspora Client", "full_path": "diaspora/diaspora-client"},
        {"id": 43, "entity_type": "User", "name": "John Smith", "username": "john_smith"},
        {"id": 5, "entity_type": "Project", "name": "Puppet", "full_path": "brightbox/puppet"}
      ],
      "edges": ["MEMBER_OF", "MEMBER_OF"]
    }
  ],
  "query_type": "path_finding",
  "row_count": 1
}
```

## Execute a named query

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244436) in GitLab 19.2.

{{< /history >}}

Executes a server-defined named query. Prefer this endpoint over
[create a query](#create-a-query) for programmatic consumers: the query
structure lives on the server, so it cannot drift from the DSL grammar or
ontology.

```plaintext
POST /api/v4/orbit/query/:name
```

Supported attributes:

| Attribute         | Type   | Required | Description                                                |
|-------------------|--------|----------|--------------------------------------------------------------|
| `name`            | string | Yes      | The named query identifier, for example `recent_merges`.     |
| `parameters`      | object | No       | Values for the placeholders the named query declares.        |
| `response_format` | string | No       | One of `raw` or `llm`. Default is `raw`.                     |

The request body must use `Content-Type: application/json`. Form encoding
stringifies nested parameter values, which the per-query parameter schemas
reject.

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the same response
attributes as [create a query](#create-a-query).

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"parameters": {}}' \
  --url "https://gitlab.example.com/api/v4/orbit/query/my_neighbors"
```

## List query templates

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244701) in GitLab 19.2.

{{< /history >}}

Lists the server-defined named queries with their query DSL rendered for the
authenticated user.

For programmatic consumers, prefer [executing named queries directly](#execute-a-named-query)
with parameters. Use the templates and their rendered `raw_query` from this
endpoint only where displaying the query DSL text is the goal, such as
populating a query editor or explorer with the text of a preset.

The rendered query DSL is not the same for every user:

- Identity values, like the ID of the authenticated user, are resolved
  server-side from the request credentials. The same request returns different
  `raw_query` values for different users. Do not cache or share templates
  across users.
- Placeholders for caller-supplied values, like the selected nodes in
  `expand_neighbors`, are filled with server-declared example values. Replace
  them with real values before you execute the query.

```plaintext
GET /api/v4/orbit/query/templates
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and an array of
template objects with the following attributes:

| Attribute     | Type   | Description                                             |
|---------------|--------|----------------------------------------------------------|
| `name`        | string | The name of the named query.                             |
| `description` | string | The description of the named query.                      |
| `raw_query`   | object | The query DSL rendered for the authenticated user.       |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/query/templates"
```

Example response, where `43` is the ID of the authenticated user:

```json
[
  {
    "name": "my_neighbors",
    "description": "Immediate graph neighborhood of the current user.",
    "raw_query": {
      "query_type": "neighbors",
      "node": {"id": "me", "entity": "User", "node_ids": [43]},
      "neighbors": {"node": "me", "direction": "both"},
      "limit": 100
    }
  },
  {
    "name": "recent_merges",
    "description": "Recently merged merge requests and the users who merged them.",
    "raw_query": {
      "query_type": "traversal",
      "nodes": [
        {"id": "u", "entity": "User", "columns": ["id", "username"]},
        {"id": "mr", "entity": "MergeRequest", "filters": {"state": "merged"}, "columns": ["id", "title", "merged_at"]}
      ],
      "relationships": [{"type": "MERGED", "from": "u", "to": "mr"}],
      "limit": 100
    }
  }
]
```

## Retrieve the schema

Retrieves the Orbit schema.

```plaintext
GET /api/v4/orbit/schema
```

Supported attributes:

| Attribute         | Type   | Required | Description                              |
|-------------------|--------|----------|------------------------------------------|
| `expand`          | string | No       | Comma-separated node names to expand.    |
| `response_format` | string | No       | One of `raw` or `llm`. Default is `raw`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute        | Type         | Description                    |
|------------------|--------------|--------------------------------|
| `schema_version` | string       | The version of the schema.     |
| `domains`        | object array | The domain definitions.        |
| `nodes`          | object array | The node type definitions.     |
| `edges`          | object array | The edge type definitions.     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/schema?expand=MergeRequest"
```

Example response:

```json
{
  "schema_version": "0.1",
  "domains": [
    {"name": "ci", "description": "Entities related to CI/CD pipelines, stages, and jobs.", "node_names": ["Job", "Pipeline", "Stage"]},
    {"name": "code_review", "node_names": ["MergeRequest", "MergeRequestDiff", "MergeRequestDiffFile"]},
    {"name": "core", "node_names": ["Group", "Note", "Project", "User"]},
    {"name": "plan", "node_names": ["Label", "Milestone", "WorkItem"]},
    {"name": "security", "node_names": ["Finding", "SecurityScan", "Vulnerability"]},
    {"name": "source_code", "node_names": ["Branch", "Definition", "Directory", "File", "ImportedSymbol"]}
  ],
  "nodes": [],
  "edges": []
}
```

## Retrieve access and cluster health

Returns whether the authenticated user can access the Knowledge Graph, along with the
cluster health. Use this endpoint to decide whether to expose Orbit actions before you
call them. It always returns `200 OK`, regardless of access or service health.

```plaintext
GET /api/v4/orbit/status
```

Supported attributes:

| Attribute         | Type   | Required | Description                              |
|-------------------|--------|----------|------------------------------------------|
| `response_format` | string | No       | One of `raw` or `llm`. Default is `raw`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute          | Type    | Description                                                         |
|--------------------|---------|---------------------------------------------------------------------|
| `user`             | object  | The requesting user's access.                                       |
| `user.available`   | boolean | Whether the user can access the Knowledge Graph.                    |
| `system`           | object  | The cluster health, or `null` when the user has no access.          |
| `system.status`    | string  | The cluster health status, for example `healthy` or `unknown`.      |
| `system.timestamp` | string  | The timestamp of the health check.                                  |
| `system.version`   | string  | The service version.                                                |
| `system.components`| array   | The individual component statuses.                                  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/status"
```

Example response:

```json
{
  "user": {
    "available": true
  },
  "system": {
    "status": "healthy",
    "timestamp": "2026-03-05T15:08:35.885160548+00:00",
    "version": "0.1.0",
    "components": [
      {"name": "gkg-indexer", "status": "healthy", "replicas": {"ready": 1, "desired": 1}, "metrics": {}},
      {"name": "gkg-webserver", "status": "healthy", "replicas": {"ready": 1, "desired": 1}, "metrics": {}},
      {"name": "clickhouse", "status": "healthy", "replicas": {"ready": 0, "desired": 0}, "metrics": {}}
    ]
  }
}
```

When the user has no access, `system` is `null`:

```json
{
  "user": {
    "available": false
  },
  "system": null
}
```

## List all tools

Lists all available Orbit operations.

```plaintext
GET /api/v4/orbit/tools
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and an array of
tool objects with the following attributes:

| Attribute     | Type   | Description                         |
|---------------|--------|-------------------------------------|
| `name`        | string | The name of the tool.               |
| `description` | string | The description of the tool.        |
| `parameters`  | object | The parameter schema for the tool.  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/tools"
```

Example response:

```json
[
  {
    "name": "query_graph",
    "description": "Execute graph queries to find nodes, traverse relationships...",
    "parameters": {
      "type": "object",
      "required": ["query"],
      "properties": {"query": {"type": "object"}}
    }
  },
  {
    "name": "get_graph_schema",
    "description": "List the GitLab Knowledge Graph schema...",
    "parameters": {
      "type": "object",
      "properties": {"expand_nodes": {"type": "array"}}
    }
  }
]
```
