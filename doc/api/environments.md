# Environments API

## List environments

Get all environments for a given project.

```
GET /projects/:id/environments
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/environments
```

Example response:

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "external_url": "https://review-fix-foo-dfjre3.example.gitlab.com"
  }
]
```

## Create a new environment

Creates a new environment with the given name and external_url.

It returns `201` if the environment was successfully created, `400` for wrong parameters.

```
POST /projects/:id/environments
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user        |
| `name`        | string  | yes      | The name of the environment  |
| `external_url` | string  | no     | Place to link to for this environment |

```bash
curl --data "name=deploy&external_url=https://deploy.example.gitlab.com" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/environments"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.example.gitlab.com"
}
```

## Edit an existing environment

Updates an existing environment's name and/or external_url.

It returns `200` if the environment was successfully updated. In case of an error, a status code `400` is returned.

```
PUT /projects/:id/environments/:environments_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer/string | yes                               | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user            |
| `environment_id` | integer | yes | The ID of the environment  | The ID of the environment        |
| `name`          | string  | no                                | The new name of the environment  |
| `external_url`  | string  | no                                | The new external_url             |

```bash
curl --request PUT --data "name=staging&external_url=https://staging.example.gitlab.com" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Example response:

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "external_url": "https://staging.example.gitlab.com"
}
```

## Delete an environment

It returns `204` if the environment was successfully deleted, and `404` if the environment does not exist.

```
DELETE /projects/:id/environments/:environment_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `environment_id` | integer | yes | The ID of the environment |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## Stop an environment

It returns `200` if the environment was successfully stopped, and `404` if the environment does not exist.

```
POST /projects/:id/environments/:environment_id/stop
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `environment_id` | integer | yes | The ID of the environment |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/environments/1/stop"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.example.gitlab.com"
}
```
