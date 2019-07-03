# Project Aliases API **[PREMIUM ONLY]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/3264) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.1.

All methods require administrator authorization.

## List all project aliases

Get a list of all project aliases:

```
GET /project_aliases
```

```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/project_aliases"
```

Example response:

```json
[
  {
    "id": 1,
    "project_id": 1,
    "name": "gitlab-ce"
  },
  {
    "id": 2,
    "project_id": 2,
    "name": "gitlab-ee"
  }
]
```

## Get project alias' details

Get details of a project alias:

```
GET /project_aliases/:name
```

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | yes      | The name of the alias |

```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/project_aliases/gitlab-ee"
```

Example response:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab-ee"
}
```

## Create a project alias

Add a new alias for a project. Responds with a 201 when successful,
400 when there are validation errors (e.g. alias already exists):

```
POST /project_aliases
```

| Attribute    | Type           | Required | Description                            |
|--------------|----------------|----------|----------------------------------------|
| `project_id` | integer/string | yes      | The ID or path of the project.         |
| `name`       | string         | yes      | The name of the alias. Must be unique. |

```
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/project_aliases" --form "project_id=1" --form "name=gitlab-ee"
```

or

```
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/project_aliases" --form "project_id=gitlab-org/gitlab-ee" --form "name=gitlab-ee"
```

Example response:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab-ee"
}
```

## Delete a project alias

Removes a project aliases. Responds with a 204 when project alias
exists, 404 when it doesn't:

```
DELETE /project_aliases/:name
```

| Attribute | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | yes      | The name of the alias |

```
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/project_aliases/gitlab-ee"
```
