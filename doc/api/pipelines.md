---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pipelines API **(FREE)**

## Single Pipeline Requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36494) in GitLab 13.3.

Endpoints that request information about a single pipeline return data for any pipeline.
Before 13.3, requests for [child pipelines](../ci/pipelines/parent_child_pipelines.md) returned
a 404 error.

## Pipelines pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

## List project pipelines

```plaintext
GET /projects/:id/pipelines
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`   | string  | no       | The scope of pipelines, one of: `running`, `pending`, `finished`, `branches`, `tags` |
| `status`  | string  | no       | The status of pipelines, one of: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled` |
| `ref`     | string  | no       | The ref of pipelines |
| `sha`     | string  | no       | The SHA of pipelines |
| `yaml_errors`| boolean  | no       | Returns pipelines with invalid configurations |
| `name`| string  | no       | The name of the user who triggered pipelines |
| `username`| string  | no       | The username of the user who triggered pipelines |
| `updated_after` | datetime | no | Return pipelines updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime | no | Return pipelines updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `order_by`| string  | no       | Order pipelines by `id`, `status`, `ref`, `updated_at` or `user_id` (default: `id`) |
| `sort`    | string  | no       | Sort pipelines in `asc` or `desc` order (default: `desc`) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

Example of response

```json
[
  {
    "id": 47,
    "project_id": 1,
    "status": "pending",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "project_id": 1,
    "status": "pending",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Get a single pipeline

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

Example of response

```json
{
  "id": 46,
  "project_id": 1,
  "status": "success",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": 123.65,
  "queued_duration": 0.010,
  "coverage": "30.0",
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

### Get variables of a pipeline

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
```

Example of response

```json
[
  {
    "key": "RUN_NIGHTLY_BUILD",
    "variable_type": "env_var",
    "value": "true"
  },
  {
    "key": "foo",
    "value": "bar"
  }
]
```

### Get a pipeline's test report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202525) in GitLab 13.0.

NOTE:
This API route is part of the [Unit test report](../ci/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

Sample request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

Sample response:

```json
{
  "total_time": 5,
  "total_count": 1,
  "success_count": 1,
  "failed_count": 0,
  "skipped_count": 0,
  "error_count": 0,
  "test_suites": [
    {
      "name": "Secure",
      "total_time": 5,
      "total_count": 1,
      "success_count": 1,
      "failed_count": 0,
      "skipped_count": 0,
      "error_count": 0,
      "test_cases": [
        {
          "status": "success",
          "name": "Security Reports can create an auto-remediation MR",
          "classname": "vulnerability_management_spec",
          "execution_time": 5,
          "system_output": null,
          "stack_trace": null
        }
      ]
    }
  ]
}
```

## Create a new pipeline

```plaintext
POST /projects/:id/pipeline
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `ref`       | string  | yes      | Reference to commit |
| `variables` | array   | no       | An array containing the variables available in the pipeline, matching the structure `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }]` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

Example of response

```json
{
  "id": 61,
  "project_id": 1,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "main",
  "status": "pending",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-11-04T09:36:13.747Z",
  "updated_at": "2016-11-04T09:36:13.977Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61"
}
```

## Retry jobs in a pipeline

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

Response:

```json
{
  "id": 46,
  "project_id": 1,
  "status": "pending",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## Cancel a pipeline's jobs

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

Response:

```json
{
  "id": 46,
  "project_id": 1,
  "status": "canceled",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## Delete a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22988) in GitLab 11.6.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```
