---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline trigger tokens API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can read more about [triggering pipelines through the API](../ci/triggers/_index.md).

## List project trigger tokens

Get a list of a project's pipeline trigger tokens.

```plaintext
GET /projects/:id/triggers
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
[
    {
        "id": 10,
        "description": "my trigger",
        "created_at": "2016-01-07T09:53:58.235Z",
        "last_used": null,
        "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
        "updated_at": "2016-01-07T09:53:58.235Z",
        "owner": null
    }
]
```

The trigger token is displayed in full if the trigger token was created by the authenticated
user. Trigger tokens created by other users are shortened to four characters.

## Get trigger token details

Get details of a project's pipeline trigger token.

```plaintext
GET /projects/:id/triggers/:trigger_id
```

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `trigger_id` | integer        | Yes      | The trigger ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Create a trigger token

Create a pipeline trigger token for a project.

```plaintext
POST /projects/:id/triggers
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `description` | string         | Yes      | The trigger name |
| `id`          | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form description="my description" "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Update a pipeline trigger token

Update a project's pipeline trigger token.

```plaintext
PUT /projects/:id/triggers/:trigger_id
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `trigger_id`  | integer        | Yes      | The trigger ID |
| `description` | string         | No       | The trigger name |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form description="my description" "https://gitlab.example.com/api/v4/projects/1/triggers/10"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Remove a pipeline trigger token

Remove a project's pipeline trigger token.

```plaintext
DELETE /projects/:id/triggers/:trigger_id
```

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `trigger_id` | integer        | Yes      | The trigger ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

## Trigger a pipeline with a token

Trigger a pipeline by using a [pipeline trigger token](../ci/triggers/_index.md#create-a-pipeline-trigger-token)
or a [CI/CD job token](../ci/jobs/ci_job_token.md) for authentication.

With a CI/CD job token, the [triggered pipeline is a multi-project pipeline](../ci/pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api).
The job that authenticates the request becomes associated with the upstream pipeline,
which is visible on the pipeline graph.

If you use a trigger token in a job, the job is not associated with the upstream pipeline.

```plaintext
POST /projects/:id/trigger/pipeline
```

Supported attributes:

| Attribute   | Type           | Required | Description |
|-------------|----------------|----------|-------------|
| `id`        | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `ref`       | string         | Yes      | The branch or tag to run the pipeline on. |
| `token`     | string         | Yes      | The trigger token or CI/CD job token. |
| `variables` | hash           | No       | A map of key-valued strings containing the pipeline variables. For example: `{ VAR1: "value1", VAR2: "value2" }`. |

Example request:

```shell
curl --request POST --form "variables[VAR1]=value1" --form "variables[VAR2]=value2" "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

Example response:

```json
{
  "id": 257,
  "iid": 118,
  "project_id": 123,
  "sha": "91e2711a93e5d9e8dddfeb6d003b636b25bf6fc9",
  "ref": "main",
  "status": "created",
  "source": "trigger",
  "created_at": "2022-03-31T01:12:49.068Z",
  "updated_at": "2022-03-31T01:12:49.068Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/257",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "username": "root",
    "name": "Administrator",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/root"
  },
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_created",
    "text": "created",
    "label": "created",
    "group": "created",
    "tooltip": "created",
    "has_details": true,
    "details_path": "/test-group/test-project/-/pipelines/257",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png"
  }
}
```
