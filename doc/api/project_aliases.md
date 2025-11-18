---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project Aliases API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [project aliases](../user/project/working_with_projects.md#project-aliases).
After you create an alias for a project, users can clone the repository with the alias,
which can be helpful when migrating repositories.

All methods require administrator authorization.

## List all project aliases

Get a list of all project aliases:

```plaintext
GET /project_aliases
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID of the project alias. |
| `name`       | string  | Name of the alias. |
| `project_id` | integer | ID of the associated project. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases"
```

Example response:

```json
[
  {
    "id": 1,
    "project_id": 1,
    "name": "gitlab-foss"
  },
  {
    "id": 2,
    "project_id": 2,
    "name": "gitlab"
  }
]
```

## Get project alias details

Get details of a project alias:

```plaintext
GET /project_aliases/:name
```

Supported attributes:

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Yes      | The name of the alias. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID of the project alias. |
| `name`       | string  | Name of the alias. |
| `project_id` | integer | ID of the associated project. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```

Example response:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## Create a project alias

Add a new alias for a project:

```plaintext
POST /project_aliases
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `name`       | string            | Yes      | Name of the alias. Must be unique. |
| `project_id` | integer or string | Yes      | ID or path of the project. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID of the project alias. |
| `name`       | string  | Name of the alias. |
| `project_id` | integer | ID of the associated project. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=1" \
  --form "name=gitlab"
```

You can also use the project path:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=gitlab-org/gitlab" \
  --form "name=gitlab"
```

Example response:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## Delete a project alias

Remove a project alias:

```plaintext
DELETE /project_aliases/:name
```

Supported attributes:

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Yes      | Name of the alias. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```
