---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Orbit Internal API
---

The Orbit internal API is used by the knowledge graph service.
The API cannot be used by other consumers. This documentation is intended for people
working on the GitLab codebase.

## Add new endpoints

API endpoints should be externally accessible by default, with proper authentication and authorization.
Before adding a new internal endpoint, consider if the API would benefit the wider GitLab community and
can be made externally accessible.

The Orbit API uses internal endpoints because requests are authenticated with a service-level
JWT token rather than a user token, and should only be accessible through an internal load balancer.

## Authentication

These endpoints are all authenticated using JWT authentication from the knowledge graph.

To authenticate using the JWT, clients:

1. Read the knowledge graph JWT signing secret.
1. Use the signing key to generate a JSON Web Token (`JWT`) with the `gkg-indexer:` subject prefix.
1. Pass the JWT in the `Gitlab-Orbit-Api-Request` header.

All endpoints require the `knowledge_graph_infra` feature flag to be enabled.

## Internal Endpoints

### Project

#### Fetch project info

Use a GET command to get the default branch for a project.

```plaintext
GET /internal/orbit/project/:project_id/info
```

Example request:

```shell
curl --header "Gitlab-Orbit-Api-Request: <json-web-token>" "https://gitlab.example.com/api/v4/internal/orbit/project/1/info"
```

Example response:

```json
{
  "project_id": 1,
  "default_branch": "main"
}
```

### Repository

#### Download repository archive

Use a GET command to download a tar.gz archive of the project repository at a given ref.

```plaintext
GET /internal/orbit/project/:project_id/repository/archive
```

| Attribute    | Type    | Required | Description                                                               |
|:-------------|:--------|:---------|:--------------------------------------------------------------------------|
| `project_id` | integer | yes      | ID of the project                                                         |
| `ref`        | string  | no       | Git ref to archive (branch, tag, or SHA). Defaults to the default branch. |

Example request:

```shell
curl --header "Gitlab-Orbit-Api-Request: <json-web-token>" "https://gitlab.example.com/api/v4/internal/orbit/project/1/repository/archive?ref=main"
```

Example response:

```plaintext
200
```

The response body is a binary tar.gz archive streamed via Workhorse.

#### List repository commits

Use a GET command to get a paginated list of commits for a given ref.

```plaintext
GET /internal/orbit/project/:project_id/repository/commits
```

| Attribute    | Type     | Required | Description                                            |
|:-------------|:---------|:---------|:-------------------------------------------------------|
| `project_id` | integer  | yes      | ID of the project                                      |
| `ref`        | string   | no       | Branch, tag, or SHA. Defaults to the default branch.   |
| `since`      | datetime | no       | Only commits after or on this date (ISO 8601)          |
| `until`      | datetime | no       | Only commits before or on this date (ISO 8601)         |
| `order`      | string   | no       | Sort order: `default` or `topo`. Defaults to `default` |
| `page`       | integer  | no       | Page number (defaults to 1)                            |
| `per_page`   | integer  | no       | Number of items per page (defaults to 20)              |

Example request:

```shell
curl --header "Gitlab-Orbit-Api-Request: <json-web-token>" "https://gitlab.example.com/api/v4/internal/orbit/project/1/repository/commits?ref=main&per_page=2"
```

Example response:

```json
[
  {
    "id": "abc123def456",
    "short_id": "abc123d",
    "title": "Update README",
    "message": "Update README with new instructions",
    "author_name": "Jane Smith",
    "author_email": "jane@example.com",
    "authored_date": "2025-01-15T10:30:00.000Z",
    "committed_date": "2025-01-15T10:30:00.000Z"
  }
]
```
