---
stage: Orbit
group: Context Systems
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to run queries, retrieve schemas, and check cluster health for Orbit.
title: Orbit API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19744) as an [experiment](../policy/development_stages_support.md) in GitLab 18.10 [with a feature flag](../administration/feature_flags/_index.md) named `knowledge_graph`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237959) from experiment to beta in GitLab 19.1.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245620) in GitLab 19.3.
- [GQL mode introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256465) in GitLab 19.4 with a feature flag named `orbit_gql_queries`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Use this API to run queries, retrieve schemas, and check cluster health for
[Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph).

## Endpoint reference

For the full reference of Orbit endpoints, including paths, parameters, and
responses, see the [interactive API reference](https://api.gitlab.com/rest/#tag/orbit).
The following sections cover query DSL behavior and worked examples that the
generated reference doesn't show.

## Query mode

Queries require JSON DSL objects by default.
Enabling `orbit_gql_queries` switches queries to read-only GQL strings and discovery to GQL guidance.
GQL follows openCypher 9 syntax.
The flag targets individual users.
REST and MCP callers cannot override the mode through parameters or headers.

## Skills

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/orbit/knowledge-graph/-/work_items/1063) in GitLab 19.5.

{{< /history >}}

Skill endpoints require authentication with the `read_api` scope.
They don't require Orbit entitlement, so you can retrieve setup and troubleshooting guidance before you
configure Orbit access.
An older knowledge graph service without skill RPCs returns `404 Not Found` with the message
`Skills are not available`.

### List deployed skills

Lists the Orbit skills deployed with the connected knowledge graph service.

```plaintext
GET /orbit/skills
```

This request takes no attributes.

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `server_version` | string | Version of the deployed knowledge graph service. |
| `skills` | array | Deployed skills. |
| `skills[].compatibility` | string | Environment requirements from the skill manifest. |
| `skills[].description` | string | Description from the skill manifest. |
| `skills[].name` | string | Skill name. |
| `skills[].version` | string | Skill version from the manifest. |

The response includes an `ETag` header derived from the sorted skill names and versions,
and a `Cache-Control` header set to `private, max-age=0, must-revalidate`.

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/skills"
```

Example response:

```json
{
  "skills": [
    {
      "name": "orbit",
      "version": "0.29.0",
      "description": "Use the glab orbit CLI for knowledge graph queries.",
      "compatibility": "Requires Orbit CLI"
    }
  ],
  "server_version": "0.31.0"
}
```

### Retrieve a deployed skill

Retrieves a complete deployed Orbit skill tree.

```plaintext
GET /orbit/skills/:name
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | Yes | Skill name. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `compatibility` | string | Environment requirements from the skill manifest. |
| `files` | array | Files in the skill tree. |
| `files[].content` | string | UTF-8 file content. |
| `files[].path` | string | Normalized path relative to the skill root. |
| `files[].sha256` | string | SHA-256 hash of the file content. |
| `name` | string | Skill name. |
| `server_version` | string | Version of the deployed knowledge graph service. |
| `version` | string | Skill version. |

The response includes these headers:

| Header | Description |
| ------ | ----------- |
| `Cache-Control` | Set to `private, max-age=0, must-revalidate`. |
| `ETag` | Set to `"<version>"`. |

Send the current `ETag` value in the `If-None-Match` request header to revalidate a cached skill tree.
A matching value returns `304 Not Modified` with no response body.

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/skills/orbit"
```

Example response:

```json
{
  "name": "orbit",
  "version": "0.29.0",
  "compatibility": "Requires Orbit CLI",
  "server_version": "0.31.0",
  "files": [
    {
      "path": "SKILL.md",
      "sha256": "93f2655e8772217e4aa8c8fbe3ad0c1f36b2bdf4a63f9f6e2f6d89a3b01da9f8",
      "content": "# Orbit skill\n"
    }
  ]
}
```

If the skill doesn't exist, returns `404 Not Found` with the known skill names in the error message.

### Check deployed skill metadata

Checks the identity and cache headers of a deployed skill without retrieving its files.

```plaintext
HEAD /orbit/skills/:name
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | Yes | Skill name. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes), the same `ETag` and `Cache-Control`
headers as `GET /orbit/skills/:name`, and no response body.

Example request:

```shell
curl --head \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/skills/orbit"
```

### Retrieve a deployed skill file

Retrieves one file from a deployed skill as raw UTF-8 text. Use this route to fetch
`SKILL.md` directly or follow relative links to files in the same skill tree.

```plaintext
GET /orbit/skills/:name/*path
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | Yes | Deployed skill name. |
| `path` | string | Yes | File path relative to the skill root, for example `references/usage.md`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the file content,
not a JSON object. Markdown files (`.md`) have the content type `text/markdown; charset=utf-8`.
Other files have the content type `text/plain; charset=utf-8`; no skill file is served as HTML.
Only exact paths listed in the skill manifest are available. Unknown paths return `404 Not Found`.
Malformed paths can return `400 Bad Request`. API error responses are JSON, rather than raw file content;
requests blocked by path traversal middleware can return a plain-text error.

The response includes a strong `ETag` from the file's SHA-256 and a `Cache-Control` header
set to `private, max-age=0, must-revalidate`. Send the `ETag` in `If-None-Match` to receive
`304 Not Modified` when the file is unchanged. `HEAD` returns the same headers without a body.

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/skills/orbit/SKILL.md"
```

Example response:

```markdown
# Orbit skill
```

## Named queries

Prefer `POST /api/v4/orbit/query/:name` over `POST /api/v4/orbit/query` for
programmatic consumers. A named query's structure lives on the server, so it
cannot drift from the DSL grammar or ontology.
Named requests keep JSON envelopes and run templates in the active mode.

## Query templates

The named query templates listed at `GET /api/v4/orbit/query/templates`
include `raw_query` rendered for the authenticated user:

- Templates contain JSON objects in JSON mode and GQL strings in GQL mode.
- Identity values, like the ID of the authenticated user, are resolved
  server-side from the request credentials. The same request returns
  different `raw_query` values for different users. Do not cache or share
  templates across users or modes.
- Invoke parameterized queries by name with their arguments, as the catalog excludes them.

Prefer executing named queries directly over using templates. Use templates
only where displaying the query text is the goal, such as populating a
query editor or explorer with the text of a preset.

## Query examples

The following examples show the Orbit query DSL for each query type. All
examples use `POST /api/v4/orbit/query`.

In GQL mode, pass a GQL string as the `query` value to `POST /api/v4/orbit/query`:

```json
{"query": "MATCH (u:User {id: 1}) RETURN u LIMIT 1"}
```

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

## Access and cluster health

`GET /api/v4/orbit/status` always returns [`200 OK`](rest/troubleshooting.md#status-codes),
regardless of access or service health. When the user has no access, `system`
is `null`:

```json
{
  "user": {
    "available": false
  },
  "system": null
}
```
