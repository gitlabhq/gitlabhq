---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project Aliases API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

All methods require administrator authorization.

## List all project aliases

Get a list of all project aliases:

```plaintext
GET /project_aliases
```

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

## Get project alias' details

Get details of a project alias:

```plaintext
GET /project_aliases/:name
```

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Yes      | The name of the alias. |

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

Add a new alias for a project. When successful, responds with `201 Created`.
When there are validation errors, for example, when the alias already exists, responds with `400 Bad Request`:

```plaintext
POST /project_aliases
```

| Attribute    | Type           | Required | Description                            |
|--------------|----------------|----------|----------------------------------------|
| `name`       | string         | Yes | The name of the alias. Must be unique. |
| `project_id` | integer or string | Yes | The ID or path of the project.         |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=1" \
  --form "name=gitlab"
```

or

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
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

Removes a project aliases. Responds with a 204 when project alias
exists, 404 when it doesn't:

```plaintext
DELETE /project_aliases/:name
```

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Yes | The name of the alias. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```
