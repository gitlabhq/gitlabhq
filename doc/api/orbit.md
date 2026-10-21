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
- Feature flag `knowledge_graph` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/259054) in GitLab 19.5.

{{< /history >}}

Use this API to run queries, retrieve schemas, and check cluster health for
[Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph).

## Search for graph entities

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256404) as an [experiment](../policy/development_stages_support.md) in GitLab 19.6.

{{< /history >}}

Searches for readable entities in a project or group and returns Orbit entity tokens.
Results use GitLab search, and might be available before the graph indexes the entities.
The endpoint selects Zoekt, Advanced Search, or Basic search independently for each scope.
Every selected scope appears in `scopes` with a `status`, so you can tell an empty scope from one that was skipped, unavailable, or failed.

You need at least the Reporter role in a group under the target's top-level group, and Orbit must be turned on for that top-level group.
Without a Reporter membership in any Orbit-enabled top-level group, such as a project-only member, the endpoint returns `403 Forbidden`.
Otherwise, a target outside your Orbit-enabled top-level groups returns `404 Not Found`.
Where the instance license covers Orbit, administrators in Admin Mode and auditors only need Orbit turned on for the target's top-level group.
On GitLab.com, they still need the usual Orbit entitlement, like the other Orbit endpoints: a Reporter membership in an entitled top-level group.
A search that GitLab search treats as abusive, such as a stop word or a term that is too short or too long, returns `400 Bad Request`.
The endpoint counts toward the Orbit query rate limit. It also counts once toward the [search rate limit](../administration/instance_limits.md#search-rate-limit), plus once for each further scope it searches. Once you hit that limit, the remaining scopes return `rate_limited` without searching.

```plaintext
GET /api/v4/orbit/grep
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `search` | string | Yes | Search terms. Must contain between 2 and 256 bytes after leading and trailing whitespace is removed. |
| `full_path` | string | Conditional | Full path of a project or group. Required if `namespace_id` and `project_id` are omitted. |
| `namespace_id` | integer | Conditional | ID of a group. Required if `full_path` and `project_id` are omitted. |
| `project_id` | integer | Conditional | ID of a project. Required if `full_path` and `namespace_id` are omitted. |
| `limit` | integer | No | Maximum total results. From 1 to 50. Default is 20. |
| `per_scope` | integer | No | Maximum results per scope. From 1 to 10 and no greater than `limit`. Default is 5. |
| `response_format` | string | No | Response format. One of `raw` or `llm`. Default is `raw`. |
| `scopes` | string array | No | Scopes to search, as a comma-separated list or repeated `scopes[]` parameters. Valid values: `work_items`, `merge_requests`, `blobs`, `commits`, `notes`, `milestones`, `users`, `projects`, and `groups`. Defaults to all scopes. |

Provide exactly one of `full_path`, `namespace_id`, or `project_id`.
Scopes are searched in a fixed order: work items, merge requests, blobs, commits, notes,
milestones, users, projects, and groups. The total `limit` applies only to the selected scopes.

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes for `response_format=raw`:

| Attribute | Type | Description |
|-----------|------|-------------|
| `request` | object | Effective request values: `search`, `limit`, and `per_scope`. |
| `result_count` | integer | Number of returned results. |
| `results` | object array | Results from all scopes, in scope order. |
| `results[].id` | integer or string | Entity ID. The commit SHA for commits, and `null` for files. |
| `results[].matches` | object array | Matched lines for a file, when the search type returns them. Each entry has `start_line`, `end_line`, and `text`. Basic search keeps the first match for each file. |
| `results[].reference` | object | Structured entity reference. |
| `results[].scope` | string | Scope that returned the result. |
| `results[].text` | string | One-line result text, truncated to 200 characters. |
| `results[].token` | string | Entity token in the form `Type[id]`. `null` for files and commits. |
| `results[].type` | string | Orbit entity type. |
| `scopes` | object array | One entry for every selected scope. |
| `scopes[].backend` | string | Search type used for the scope: `basic`, `advanced`, or `zoekt`. Present when `status` is `ok`. |
| `scopes[].name` | string | Search scope name. |
| `scopes[].pagination` | object | Present when `status` is `ok`. `has_more` is `true` when the scope has more results than were returned. |
| `scopes[].reason` | object | Present when `status` is not `ok`. `code` is one of `not_available_for_search_type`, `search_type_error`, `invalid_search`, `search_failed`, `timeout`, `rate_limited`, or `limit_reached`. |
| `scopes[].result_count` | integer | Number of results from the scope. Present when `status` is `ok`. |
| `scopes[].status` | string | One of `ok`, `unavailable`, `skipped`, or `error`. `unavailable` means the search type or target doesn't support the scope, the search backend rejected the request (for example, a Zoekt project limit), or you don't have access to it. `skipped` means the total `limit` was reached first. `error` means the search failed or hit the search rate limit, and other scopes keep their results. |
| `target` | object | Search target. |
| `target.full_path` | string | Full path of the target. |
| `target.id` | integer | Target ID. |
| `target.token` | string | Entity token of the target. |
| `target.type` | string | `Project` or `Group`. |
| `truncated` | boolean | Whether the total limit was reached before all scopes were exhausted, or a scope has more results than `per_scope`. |
| `version` | string | Grep response contract version. |

Files use a `reference` with `project_id`, `path`, `branch`, and `commit_sha`.
`branch` is the default branch for Advanced Search and Zoekt results.
`commit_sha` is the indexed commit for Advanced Search results, and `null` otherwise.
Commits use a `reference` with `project_id` and `sha`.
Other entities use a reference with the global database `id`.

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/grep?search=search%20term&project_id=1&scopes=merge_requests,blobs,notes&limit=2&per_scope=2"
```

Example response:

```json
{
  "version": "1.0.0",
  "request": {"search": "search term", "limit": 2, "per_scope": 2},
  "target": {"type": "Project", "id": 1, "token": "Project[1]", "full_path": "example-group/example-project"},
  "scopes": [
    {"name": "merge_requests", "status": "ok", "backend": "advanced", "result_count": 1, "pagination": {"has_more": false}},
    {"name": "blobs", "status": "ok", "backend": "advanced", "result_count": 1, "pagination": {"has_more": true}},
    {"name": "notes", "status": "skipped", "reason": {"code": "limit_reached"}}
  ],
  "results": [
    {
      "scope": "merge_requests",
      "type": "MergeRequest",
      "id": 42,
      "token": "MergeRequest[42]",
      "reference": {"id": 42},
      "text": "Add scoped search"
    },
    {
      "scope": "blobs",
      "type": "File",
      "id": null,
      "token": null,
      "reference": {"project_id": 1, "path": "README.md", "branch": "main", "commit_sha": "e79b2dc8c2cca1ed93c8c760dfa89b8e47ed1720"},
      "text": "README.md",
      "matches": [{"start_line": 3, "end_line": 5, "text": "A search term in context"}]
    }
  ],
  "result_count": 2,
  "truncated": true
}
```

For `response_format=llm`, the endpoint returns compact `text/plain` output:

```plaintext
orbit_grep version=1.0.0 target=Project[1] search="search term" scopes="merge_requests,blobs,notes" results=2 truncated=true
- MergeRequest[42] type=MergeRequest text="Add scoped search"
- File project_id="1" path="README.md" branch="main" commit_sha="e79b2dc8c2cca1ed93c8c760dfa89b8e47ed1720" type=File text="README.md"
! skipped scope=notes reason=limit_reached
```

## Endpoint reference

For the full reference of Orbit endpoints, including paths, parameters, and
responses, see the [interactive API reference](https://api.gitlab.com/rest/#tag/orbit).
The following sections cover query DSL behavior and worked examples that the
generated reference doesn't show.

## Query mode

> [!flag]
> The availability of GQL query mode is controlled by a feature flag named `orbit_gql_queries`.
> For more information, see the history.

Queries require JSON DSL objects by default.
Enabling `orbit_gql_queries` switches queries to read-only GQL strings and discovery to GQL guidance.
GQL follows openCypher 9 syntax.
The flag targets individual users.
REST and MCP callers cannot override the mode through parameters or headers.
With the flag enabled, `response_format: gql` returns query results as a plain-text table.

## Skills

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/orbit/knowledge-graph/-/work_items/1063) in GitLab 19.5.

{{< /history >}}

Skill endpoints require authentication with the `read_api` scope.
They don't check the Orbit license, so unavailable skills return `404 Not Found` instead of `403 Forbidden`.
The response is `404 Not Found` with the message `Skills are not available` when:

- The knowledge graph service is an older version without skill RPCs.
- The knowledge graph service isn't configured on the instance. On GitLab Self-Managed, this is
  controlled by `orbit.enabled` in `gitlab.yml`, or the legacy `knowledge_graph.enabled` setting.
- The current user doesn't have at least the Reporter role in a group whose top-level group has Orbit
  turned on. Administrators in Admin Mode and auditors are exempt from this role requirement.

In these cases, the Orbit CLI uses its embedded local skill.

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
examples use `POST /api/v4/orbit/query`. For the complete query language, see
[Orbit query language](https://docs.gitlab.com/orbit/remote/queries/query-language/).

In GQL mode, pass a GQL string as the `query` value to `POST /api/v4/orbit/query`:

```json
{"query": "MATCH (u:User {id: 1}) RETURN u LIMIT 1"}
```

The examples use the default `raw` response format. In each response, the `result`
object lists the matched `nodes` and the `edges` between them. Node IDs are strings.
Aggregation queries also return `columns`, `group_columns`, and `rows`.

Retrieve a user by username:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "traversal",
      "nodes": [
        {"id": "u", "entity": "User", "filters": {"username": "john_smith"}}
      ]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": {
    "format_version": "5.0.3",
    "query_type": "traversal",
    "nodes": [
      {"type": "User", "id": "1", "username": "john_smith", "name": "John Smith", "state": "active"}
    ],
    "edges": [],
    "pagination": {"has_more": false, "truncated": false}
  },
  "query_type": "traversal",
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
  "result": {
    "format_version": "5.0.3",
    "query_type": "traversal",
    "nodes": [
      {"type": "Project", "id": "8", "name": "Diaspora Client", "full_path": "diaspora/diaspora-client", "visibility_level": "public"},
      {"type": "MergeRequest", "id": "43", "iid": 1, "title": "Resolve connection timeout on large payloads", "state": "merged", "source_branch": "fix-timeout", "target_branch": "main"},
      {"type": "MergeRequest", "id": "44", "iid": 2, "title": "Replace deprecated API calls in federation module", "state": "merged", "source_branch": "update-federation-api", "target_branch": "main"}
    ],
    "edges": [
      {"from": "MergeRequest", "from_id": "43", "to": "Project", "to_id": "8", "type": "IN_PROJECT"},
      {"from": "MergeRequest", "from_id": "44", "to": "Project", "to_id": "8", "type": "IN_PROJECT"}
    ],
    "pagination": {"has_more": false, "truncated": false}
  },
  "query_type": "traversal",
  "row_count": 2
}
```

Count merge requests per project. Traversal and aggregation queries must bound
at least one node with `node_ids` or filters:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "aggregation",
      "nodes": [
        {"id": "p", "entity": "Project", "node_ids": [5, 8]},
        {"id": "mr", "entity": "MergeRequest"}
      ],
      "relationships": [{"type": "IN_PROJECT", "from": "mr", "to": "p"}],
      "aggregations": [{"count": "mr", "as": "mr_count"}],
      "group_by": ["p"]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": {
    "format_version": "5.0.3",
    "query_type": "aggregation",
    "nodes": [],
    "edges": [],
    "columns": [{"name": "mr_count", "function": "count", "target": "mr"}],
    "group_columns": [{"name": "p", "kind": "node", "node": "p", "entity": "Project"}],
    "rows": [
      {"p": {"type": "Project", "id": "8", "properties": {"name": "Diaspora Client", "full_path": "diaspora/diaspora-client", "visibility_level": "public"}}, "mr_count": 8},
      {"p": {"type": "Project", "id": "5", "properties": {"name": "Puppet", "full_path": "brightbox/puppet", "visibility_level": "public"}}, "mr_count": 6}
    ],
    "pagination": {"has_more": false, "truncated": false}
  },
  "query_type": "aggregation",
  "row_count": 2
}
```

Find outgoing neighbors of a user. The `direction` attribute accepts `outgoing`,
`incoming`, or `both`, and defaults to `outgoing`:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "neighbors",
      "nodes": [{"id": "u", "entity": "User", "node_ids": [1]}],
      "neighbors": {"direction": "outgoing"}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": {
    "format_version": "5.0.3",
    "query_type": "neighbors",
    "nodes": [
      {"type": "User", "id": "1", "username": "john_smith", "name": "John Smith", "state": "active"},
      {"type": "Group", "id": "29", "name": "diaspora", "full_path": "diaspora", "visibility_level": "public"},
      {"type": "MergeRequest", "id": "43", "iid": "1", "title": "Resolve connection timeout on large payloads", "state": "merged", "source_branch": "fix-timeout", "target_branch": "main"},
      {"type": "MergeRequest", "id": "44", "iid": "2", "title": "Replace deprecated API calls in federation module", "state": "merged", "source_branch": "update-federation-api", "target_branch": "main"}
    ],
    "edges": [
      {"from": "User", "from_id": "1", "to": "Group", "to_id": "29", "type": "MEMBER_OF"},
      {"from": "User", "from_id": "1", "to": "MergeRequest", "to_id": "43", "type": "AUTHORED"},
      {"from": "User", "from_id": "1", "to": "MergeRequest", "to_id": "44", "type": "AUTHORED"}
    ],
    "pagination": {"has_more": false, "truncated": false}
  },
  "query_type": "neighbors",
  "row_count": 3
}
```

Find the shortest path from a user to a project. Path finding queries require
`rel_types`, and follow each relationship type only in its defined direction,
from the `from` node toward the `to` node:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "path_finding",
      "nodes": [
        {"id": "u", "entity": "User", "node_ids": [1]},
        {"id": "p", "entity": "Project", "node_ids": [8]}
      ],
      "path": {
        "type": "shortest",
        "from": "u",
        "to": "p",
        "max_depth": 3,
        "rel_types": ["MEMBER_OF", "CONTAINS"]
      }
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

Example response:

```json
{
  "result": {
    "format_version": "5.0.3",
    "query_type": "path_finding",
    "nodes": [
      {"type": "User", "id": "1", "username": "john_smith", "name": "John Smith", "state": "active"},
      {"type": "Group", "id": "29", "name": "diaspora", "full_path": "diaspora", "visibility_level": "public"},
      {"type": "Project", "id": "8", "name": "Diaspora Client", "full_path": "diaspora/diaspora-client", "visibility_level": "public"}
    ],
    "edges": [
      {"from": "User", "from_id": "1", "to": "Group", "to_id": "29", "type": "MEMBER_OF", "path_id": 0, "step": 0},
      {"from": "Group", "from_id": "29", "to": "Project", "to_id": "8", "type": "CONTAINS", "path_id": 0, "step": 1}
    ],
    "pagination": {"has_more": false, "truncated": false}
  },
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
