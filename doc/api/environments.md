---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Environments API

## List environments

Get all environments for a given project.

```plaintext
GET /projects/:id/environments
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name`    | string  | no       | Return the environment with this name. Mutually exclusive with `search` |
| `search`  | string  | no       | Return list of environments matching the search criteria. Mutually exclusive with `name` |
| `states`  | string  | no       | List all environments that match a specific state. Accepted values: `available` or `stopped`. If no state value given, returns all environments. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments?name=review%2Ffix-foo"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
    "state": "available"
  }
]
```

## Get a specific environment

```plaintext
GET /projects/:id/environments/:environment_id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `environment_id` | integer | yes | The ID of the environment |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Example of response

```json
{
  "id": 1,
  "name": "review/fix-foo",
  "slug": "review-fix-foo-dfjre3",
  "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
  "state": "available",
  "last_deployment": {
    "id": 100,
    "iid": 34,
    "ref": "fdroid",
    "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
    "created_at": "2019-03-25T18:55:13.252Z",
    "status": "success",
    "user": {
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "deployable": {
      "id": 710,
      "status": "success",
      "stage": "deploy",
      "name": "staging",
      "ref": "fdroid",
      "tag": false,
      "coverage": null,
      "created_at": "2019-03-25T18:55:13.215Z",
      "started_at": "2019-03-25T12:54:50.082Z",
      "finished_at": "2019-03-25T18:55:13.216Z",
      "duration": 21623.13423,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "skype": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": null
      },
      "commit": {
        "id": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "short_id": "416d8ea1",
        "created_at": "2016-01-02T15:39:18.000Z",
        "parent_ids": [
          "e9a4449c95c64358840902508fc827f1a2eab7df"
        ],
        "title": "Removed fabric to fix #40",
        "message": "Removed fabric to fix #40\n",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "authored_date": "2016-01-02T15:39:18.000Z",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com",
        "committed_date": "2016-01-02T15:39:18.000Z"
      },
      "pipeline": {
        "id": 34,
        "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "ref": "fdroid",
        "status": "success",
        "web_url": "http://localhost:3000/Commit451/lab-coat/pipelines/34"
      },
      "web_url": "http://localhost:3000/Commit451/lab-coat/-/jobs/710",
      "artifacts": [
        {
          "file_type": "trace",
          "size": 1305,
          "filename": "job.log",
          "file_format": null
        }
      ],
      "runner": null,
      "artifacts_expire_at": null
    }
  }
}
```

## Create a new environment

Creates a new environment with the given name and `external_url`.

It returns `201` if the environment was successfully created, `400` for wrong parameters.

```plaintext
POST /projects/:id/environments
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user        |
| `name`        | string  | yes      | The name of the environment  |
| `external_url` | string  | no     | Place to link to for this environment |

```shell
curl --data "name=deploy&external_url=https://deploy.gitlab.example.com" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "available"
}
```

## Edit an existing environment

Updates an existing environment's name and/or `external_url`.

It returns `200` if the environment was successfully updated. In case of an error, a status code `400` is returned.

```plaintext
PUT /projects/:id/environments/:environments_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer/string | yes                               | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user            |
| `environment_id` | integer | yes | The ID of the environment  |
| `name`          | string  | no                                | The new name of the environment  |
| `external_url`  | string  | no                                | The new `external_url`           |

```shell
curl --request PUT --data "name=staging&external_url=https://staging.gitlab.example.com" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Example response:

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "external_url": "https://staging.gitlab.example.com",
  "state": "available"
}
```

## Delete an environment

It returns `204` if the environment was successfully deleted, and `404` if the environment does not exist.

```plaintext
DELETE /projects/:id/environments/:environment_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `environment_id` | integer | yes | The ID of the environment |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## Stop an environment

It returns `200` if the environment was successfully stopped, and `404` if the environment does not exist.

```plaintext
POST /projects/:id/environments/:environment_id/stop
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `environment_id` | integer | yes | The ID of the environment |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/environments/1/stop"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "stopped"
}
```
