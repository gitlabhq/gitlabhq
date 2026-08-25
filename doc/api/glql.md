---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209517) in GitLab 18.7.

{{< /history >}}

Use this API to execute [GitLab Query Language (GLQL)](../user/glql/_index.md) queries programmatically.
GLQL provides a simplified query language for searching and
filtering [GitLab resources](../user/glql/_index.md#supported-areas) such as issues, merge requests,
and epics across projects and groups.

Prerequisites:

- The group or project must allow access to its data.
- For private groups and projects, you must use
  [a personal access token](../user/profile/personal_access_tokens.md) with appropriate permissions.

## Execute a GLQL query

Executes a GLQL query to search and filter GitLab resources.

```plaintext
POST /glql
```

> [!note]
> This endpoint rate-limits queries based on the query SHA. Identical queries that time out are
> tracked and might be temporarily blocked if executed too frequently.

Supported attributes:

| Attribute   | Type   | Required | Description                                                                                                                           |
|-------------|--------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `glql_yaml` | string | Yes      | The GLQL query with optional YAML configuration. Maximum size: 10,000 bytes (10 KB). See [Query formats](#query-formats) for details. |
| `after`     | string | No       | Cursor for pagination. Use the `data.pageInfo.endCursor` value from a previous query to fetch the next page of results.               |

### Query formats

The `glql_yaml` parameter accepts the YAML format with a `query` key:

```yaml
fields: id,title,author
group: my-group
limit: 10
sort: created desc
query: state = opened
```

### Configuration options

The following configuration options can be included in the YAML:

| Option    | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `fields`  | string  | No       | Comma-separated list of fields to return. Default: `title`. See [available fields](#available-fields). |
| `group`   | string  | No       | Scope the query to a specific group. Cannot be used with `project`. If `group` is also specified in the query, the query value takes precedence. |
| `limit`   | integer | No       | Maximum number of results to return. Must be between 1 and 100. Default: `100`. |
| `project` | string  | No       | Scope the query to a specific project. Format: `group/project`. If `project` is also specified in the query, the query value takes precedence. |
| `sort`    | string  | No       | Sort order for results. Format: `field direction` (for example, `created asc` or `created desc`). |

### Available fields

Set the `fields` configuration option to a comma-separated list of the [available GLQL fields](../user/glql/fields.md).

### GLQL query syntax

The query syntax is defined by [GLQL](../user/glql/_index.md#query-syntax).

### Response attributes

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                       | Type    | Description |
|---------------------------------|---------|-------------|
| `data`                          | object  | Contains the query results. |
| `data.count`                    | integer | Total number of matching results. |
| `data.nodes`                    | array   | Array of matching resources with requested fields. |
| `data.pageInfo`                 | object  | Pagination information. |
| `data.pageInfo.endCursor`       | string  | Cursor for fetching the next page of results. |
| `data.pageInfo.hasNextPage`     | boolean | Indicates if more results are available. |
| `data.pageInfo.hasPreviousPage` | boolean | Indicates if previous results are available. |
| `data.pageInfo.startCursor`     | string  | Cursor for fetching the previous page of results. |
| `error`                         | string  | Error message if the query failed. |
| `fields`                        | array   | Array of field definitions. |
| `fields[].field`                | string  | The base field name. For aliased parameterised fields, this is the underlying field name (for example, `durationQuantile`), while `key` is the alias (for example, `p50`). For standard fields, same as `key`. |
| `fields[].key`                  | string  | The unique field identifier. |
| `fields[].label`                | string  | The human-readable field name. |
| `fields[].name`                 | string  | The common field name that unifies similar fields. For example, `created` and `createdAt` keys have the name `createdAt`. For aliased parameterised fields, this is the generated response key (for example, `durationQuantile_quantile_0_d5`), not a common name. |
| `fields[].parameters`           | object  | Resolved parameter metadata for parameterised fields. Absent when the field has no parameters. For example, `{"granularity": "weekly"}` or `{"quantile": "0.5"}`. |
| `fields[].type`                 | string  | Field classification: `dimension` or `metric` for analytics mode fields. Absent for standard fields. |
| `success`                       | boolean | Indicates if the query was successful. |

### Example: Basic query

Search for opened issues in a group:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Example response:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

### Example: Query with front matter configuration

Search with custom fields and sorting:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,author,state\ngroup: my-group\nlimit: 5\nsort: created desc\nquery: state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Example response:

```json
{
  "data": {
    "count": 2,
    "nodes": [
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/123",
          "name": "John Doe",
          "username": "johndoe",
          "webUrl": "https://gitlab.example.com/johndoe"
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      },
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/122",
          "name": "Jane Doe",
          "username": "janedoe",
          "webUrl": "https://gitlab.example.com/janedoe"
        },
        "id": "gid://gitlab/Issue/122",
        "iid": "122",
        "reference": "#122",
        "state": "OPEN",
        "title": "HTTP server examples for all programming languages",
        "webUrl": "https://gitlab.example.com/groups/my-group/-/issues/122",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "field": "id",
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "field": "author",
      "key": "author",
      "label": "Author",
      "name": "author"
    },
    {
      "field": "state",
      "key": "state",
      "label": "State",
      "name": "state"
    }
  ],
  "success": true
}
```

### Example: Query with project scope

Search in a specific project:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: project = \"my-group/my-project\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

### Example: Query with `currentUser()` function

Search for issues assigned to the current user:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,assignees\nquery: group = \"my-group\" AND assignee = currentUser()"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Example response:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "assignees": {
          "nodes": [
            {
              "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
              "id": "gid://gitlab/User/123",
              "name": "John Doe",
              "username": "johndoe",
              "webUrl": "https://gitlab.example.com/johndoe"
            }
          ]
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "field": "id",
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "field": "assignees",
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees"
    }
  ],
  "success": true
}
```

### Example: Query with limit and pagination

Retrieve a limited number of results and paginate through them:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Example response:

```json
{
  "data": {
    "count": 68,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/321",
        "iid": "321",
        "reference": "#321",
        "state": "OPEN",
        "title": "Corrupti consectetur impedit non blanditiis hic vitae minus.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/321",
        "widgets": null
      },
      {
        "id": "gid://gitlab/WorkItem/322",
        "iid": "322",
        "reference": "#322",
        "state": "OPEN",
        "title": "Ipsa cupiditate corrupti vel maxime quasi at assumenda repellat quod.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/322",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjIifQ==",
      "hasNextPage": true,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

To fetch the next page, use the `endCursor` value from the previous response:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened",
    "after": "eyJpZCI6IjIifQ=="
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

### Example: Analytics mode query

Aggregate pipeline metrics grouped by a dimension.
In analytics mode, the `fields` array includes the `type` attribute for each field,
and the `parameters` attribute for parameterised fields:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "mode: analytics\ndimensions: ref\nmetrics: durationQuantile(0.5) as \"p50\"\nquery: type = Pipeline AND project = \"my-group/my-project\" AND finished >= -30d"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Example response:

```json
{
  "data": {
    "count": 2,
    "nodes": [
      {
        "durationQuantile_quantile_0_d5": 245.5,
        "p50": 245.5,
        "ref": "main"
      },
      {
        "durationQuantile_quantile_0_d5": 312.0,
        "p50": 312.0,
        "ref": "feature-branch"
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjIifQ==",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEifQ=="
    }
  },
  "error": null,
  "fields": [
    {
      "field": "ref",
      "key": "ref",
      "label": "Ref",
      "name": "ref",
      "type": "dimension"
    },
    {
      "field": "durationQuantile",
      "key": "p50",
      "label": "p50",
      "name": "durationQuantile_quantile_0_d5",
      "parameters": {
        "quantile": "0.5"
      },
      "type": "metric"
    }
  ],
  "success": true
}
```

## Retrieve the GLQL schema

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247360) in GitLab 19.3.

{{< /history >}}

Retrieves the GLQL schema: the available data sources with their filter, display, and sort
fields, the operator, value kind, and reference type vocabularies, the available functions, and
the display types a query can be rendered as.

The document describes the query language. A query against a data source that is not available to
you fails at `POST /glql`.

The document changes only when GitLab is upgraded. It is served with an `ETag`, so send
`If-None-Match` to revalidate and receive `304 Not Modified` instead of the full document.

```plaintext
GET /glql/schema
```

This endpoint takes no parameters and returns the same document for every user.

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute         | Type         | Description |
|-------------------|--------------|-------------|
| `display_types`   | object array | How a query can be rendered, and what each one needs. Omitting `display:` renders a list. See below. |
| `functions`       | object array | Available functions, each with a `name`, a `kind` (`value` for use in a query, `field` for use in `fields`), a `description`, `args`, and `returns`. |
| `operators`       | object array | Comparison operators, each with a `symbol`, `name`, and `label`. |
| `reference_types` | object array | Reference prefixes, each with a `name`, `symbol`, and `example`. For example, `~` for a label. |
| `sources`         | object array | The data sources. See below. |
| `value_kinds`     | object array | The kinds of value a filter accepts, each with a `name` and `description`. |
| `version`         | string       | Version of the GLQL gem this document was shipped in. |

Response attributes for `display_types[]`:

| Attribute     | Type         | Description |
|---------------|--------------|-------------|
| `description` | string       | What the display type renders. |
| `name`        | string       | The value to use in a GLQL block's `display:` option. |
| `selections`  | object array | The combinations of dimensions and metrics the type accepts. A query must match one of them. Present only for types that aggregate, which for that reason need `mode: analytics`. See below. |

Response attributes for `display_types[].selections[]`:

| Attribute    | Type    | Description |
|--------------|---------|-------------|
| `dimensions` | integer | Exact number of dimensions this combination takes. |
| `metrics`    | object  | How many metrics this combination takes, as `min` and an optional `max`. No `max` means no limit. |

Response attributes for `sources[]`:

| Attribute | Type         | Description |
|-----------|--------------|-------------|
| `label`   | string       | Human-readable name. |
| `modes`   | object array | Query modes the source supports. See below. |
| `name`    | string       | Canonical source name. For example, `WorkItems`. |

Response attributes for `sources[].modes[]`:

| Attribute                | Type         | Description |
|--------------------------|--------------|-------------|
| `allowed_scopes`         | string array | Scopes the source can be queried in. For example, `project`. |
| `dimensions`             | string array | Analytics modes only. Fields to group by. |
| `display_fields`         | object array | Standard modes only. Fields usable in `fields`, each with a `name` and optional `aliases`. Analytics modes omit this and use `dimensions` and `metrics` instead. |
| `filter_fields`          | object array | Fields usable in `query`, each with a `name`, optional `aliases`, and `value_types`. |
| `metrics`                | string array | Analytics modes only. Aggregations to compute. |
| `mode`                   | string       | `Standard` or `Analytics`. Note these are capitalized here, while the `mode` option in a GLQL block is lowercase. For example, `mode: analytics`. |
| `parameterized_fields`   | object array | Fields that accept arguments, each with a `name` and `parameters`. Present only where supported. See below. |
| `sort_fields`            | string array | Fields usable in `sort`. |
| `sort_restrictions`      | object array | Sort fields that accept only one direction, each with a `name` and the `directions` it accepts. Fields absent from this list accept both `asc` and `desc`. Present only where a restriction applies. |
| `wildcard_filter_fields` | object array | Filters taking an argument, each with a `name`, a `syntax` string, and `value_types`. For example, `customField("Name")`. Present only where supported. |

Response attributes for `sources[].modes[].filter_fields[].value_types[]`:

| Attribute    | Type         | Description |
|--------------|--------------|-------------|
| `items`      | object array | `List` only. The value types accepted inside the list. |
| `kind`       | string       | One of the `value_kinds` names. |
| `operators`  | string array | Operators accepted for this kind. |
| `references` | string       | `Reference` only. One of the `reference_types` names. |
| `values`     | string array | `Enum` and `StringEnum` only. The accepted tokens. On the `type` filter, the tokens listed are the ones that select this data source. Only `WorkItems` accepts more than one, because for work items `type` also narrows the results to a work item type. |

Response attributes for `sources[].modes[].parameterized_fields[].parameters[]`:

| Attribute | Type         | Description |
|-----------|--------------|-------------|
| `default` | string       | Value used when the argument is omitted. |
| `kind`    | string       | `Enum` or `Number`. |
| `max`     | number       | `Number` only. Largest accepted value. |
| `min`     | number       | `Number` only. Smallest accepted value. |
| `name`    | string       | Argument name. For example, `granularity`. |
| `values`  | string array | `Enum` only. The accepted values. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/glql/schema"
```

Example response, truncated:

```json
{
  "sources": [
    {
      "name": "WorkItems",
      "label": "work items",
      "modes": [
        {
          "mode": "Standard",
          "allowed_scopes": ["project", "group"],
          "filter_fields": [
            {
              "name": "label",
              "aliases": ["labels"],
              "value_types": [
                { "kind": "String", "operators": ["=", "!="] },
                {
                  "kind": "List",
                  "operators": ["in", "=", "!="],
                  "items": [{ "kind": "String" }, { "kind": "Reference", "references": "LabelRef" }]
                }
              ]
            }
          ],
          "wildcard_filter_fields": [
            {
              "name": "customField",
              "syntax": "customField(\"Name\")",
              "value_types": [{ "kind": "String", "operators": ["="] }]
            }
          ],
          "display_fields": [
            { "name": "title" },
            { "name": "assignee", "aliases": ["assignees"] }
          ],
          "sort_fields": ["created", "updated", "due"]
        }
      ]
    }
  ],
  "operators": [{ "symbol": "=", "name": "Equal", "label": "equals" }],
  "value_kinds": [{ "name": "String", "description": "A quoted string, for example \"my title\"." }],
  "reference_types": [{ "name": "LabelRef", "symbol": "~", "example": "~frontend" }],
  "display_types": [
    { "name": "list", "description": "A bulleted list of items." },
    {
      "name": "barChart",
      "description": "Horizontal bars, one per dimension value.",
      "selections": [
        { "dimensions": 1, "metrics": { "min": 1 } },
        { "dimensions": 2, "metrics": { "min": 1, "max": 1 } }
      ]
    }
  ],
  "functions": [
    { "name": "today", "kind": "value", "description": "Today's date at 00:00 UTC.", "args": [], "returns": "Date" }
  ],
  "version": "0.34.0"
}
```

Analytics modes list the arguments their dimensions and metrics accept, so a query can set them
explicitly rather than relying on the default:

```json
"parameterized_fields": [
  {
    "name": "finished",
    "parameters": [
      { "name": "granularity", "kind": "Enum", "values": ["daily", "weekly", "monthly"], "default": "weekly" }
    ]
  },
  {
    "name": "durationQuantile",
    "parameters": [{ "name": "quantile", "kind": "Number", "min": 0.01, "max": 0.99, "default": 0.95 }]
  }
]
```

## Rate limiting

The GLQL API implements rate limiting based on the SHA-256 hash of the query.
Queries that time out are tracked. If a particular query that is timing out
is executed too frequently, it is temporarily blocked.

When rate limited, the API returns a `429 Too Many Requests` status code with an error message:

```json
{
  "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
}
```

## Error handling

The API returns the following HTTP status codes:

| Status code                 | Description |
|-----------------------------|-------------|
| `200 Success`               | Query executed successfully. |
| `400 Bad Request`           | Invalid query syntax, missing required parameters, or input exceeds size limit. |
| `401 Unauthorized`          | Authentication required or invalid credentials. |
| `403 Forbidden`             | Insufficient permissions or missing required OAuth scope. |
| `429 Too Many Requests`     | Query rate limit exceeded. |
| `500 Internal Server Error` | Server error during query execution. |

### Error response examples

- Missing required parameter:

  ```json
  {
    "error": "glql_yaml is missing, glql_yaml is empty"
  }
  ```

- Invalid GLQL syntax:

  ```json
  {
    "error": "400 Bad request - Error: Unexpected `invalid syntax @@@ ###`, expected operator (one of IN, =, !=, >, or <)"
  }
  ```

- Input size exceeded:

  ```json
  {
    "error": "400 Bad request - Input exceeds maximum size"
  }
  ```

- Non-existent project:

  ```json
  {
    "error": "400 Bad request - Error: Project does not exist or you do not have access to it"
  }
  ```

- Non-existent group:

  ```json
  {
    "error": "400 Bad request - Error: Group does not exist or you do not have access to it"
  }
  ```

- Rate limit exceeded:

  ```json
  {
    "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
  }
  ```

- Invalid field

  ```json
  {
    "error": "Field 'title' doesn't exist on type 'WorkItem' (Did you mean `title`?)"
  }
  ```

> [!note]
> GraphQL bad request errors are passed through to the API `error` field when applicable with
> the `400` error code.

## Limits and constraints

The GLQL API has the following limits:

- Maximum input size: 10,000 bytes (10 KB) for the `glql_yaml` parameter.
- Maximum query limit: 100 results per request.
- Default limit: 100 results when not specified.
- Pagination: Only forward pagination is supported using the `after` attribute with the
  `endCursor` value from a previous response.
- Rate limiting: Queries are rate-limited based on query SHA-256 hash.

## Related topics

- [GLQL query language documentation](../user/glql/_index.md)
- [REST API authentication](rest/authentication.md)
- [OAuth 2.0 authentication](oauth2.md)
