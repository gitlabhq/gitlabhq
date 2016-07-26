# Environments

## List environments

Get all environments for a given project.

```
GET /projects/:id/environments
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID of the project |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/1/environments
```

Example response:

```json
[
  {
    "id": 1,
    "name": "Env1",
    "external_url": "https://env1.example.gitlab.com"
  }
]
```

## Create a new environment

Creates a new environment with the given name and external_url.

It returns 200 if the environment was successfully created, 400 for wrong parameters
and 409 if the environment already exists.

```
POST /projects/:id/environment
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`          | integer | yes      | The ID of the project        |
| `name`        | string  | yes      | The name of the environment  |
| `external_url` | string  | yes     | Place to link to for this environment |

```bash
curl --data "name=deploy&external_url=https://deploy.example.gitlab.com" -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/environments"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "external_url": "https://deploy.example.gitlab.com"
}
```

## Delete an environment

It returns 200 if the environment was successfully deleted, and 404 if the environment does not exist.

```
DELETE /projects/:id/environments/:environment_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id` | integer | yes | The ID of the project |
| `environment_id` | integer | yes | The ID of the environment |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/environment/1"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "external_url": "https://deploy.example.gitlab.com"
}
```

## Edit an existing environment

Updates an existing environments name and/or external_url.

It returns 200 if the label was successfully updated, In case of an error, an additional error message is returned.

```
PUT /projects/:id/environments/:environments_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer | yes                               | The ID of the project            |
| `environment_id` | integer | yes | The ID of the environment  | The ID of the environment        |
| `name`          | string  | no                                | The new name of the environment  |
| `external_url`  | string  | no                                | The new external_url             |

```bash
curl -X PUT --data "name=staging&external_url=https://staging.example.gitlab.com" -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/environment/1"
```

Example response:

```json
{
  "id": 1,
  "name": "staging",
  "external_url": "https://staging.example.gitlab.com"
}
```
