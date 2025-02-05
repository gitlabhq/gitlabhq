---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipelines API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Pipelines pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](rest/_index.md#pagination).

## List project pipelines

> - `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.
> - `name` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) in GitLab 15.11 [with a flag](../administration/feature_flags.md) named `pipeline_name_in_api`. Disabled by default.
> - `name` in request [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) in 15.11 [with a flag](../administration/feature_flags.md) named `pipeline_name_search`. Disabled by default.
> - `name` in response [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) in GitLab 16.3. Feature flag `pipeline_name_in_api` removed.
> - `name` in request [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/385864) in GitLab 16.9. Feature flag `pipeline_name_search` removed.
> - Support for returning child pipelines with `source` set to `parent_pipeline` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/39503) in GitLab 17.0.

List pipelines in a project.

By default, [child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)
are not included in the results. To return child pipelines, set `source` to `parent_pipeline`.

```plaintext
GET /projects/:id/pipelines
```

| Attribute        | Type           | Required | Description |
|------------------|----------------|----------|-------------|
| `id`             | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`           | string         | No       | Return pipelines with the specified name. |
| `order_by`       | string         | No       | Order pipelines by `id`, `status`, `ref`, `updated_at` or `user_id` (default: `id`) |
| `ref`            | string         | No       | The ref of pipelines |
| `scope`          | string         | No       | The scope of pipelines, one of: `running`, `pending`, `finished`, `branches`, `tags` |
| `sha`            | string         | No       | The SHA of pipelines |
| `sort`           | string         | No       | Sort pipelines in `asc` or `desc` order (default: `desc`) |
| `source`         | string         | No       | The [pipeline source](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `status`         | string         | No       | The status of pipelines, one of: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled` |
| `updated_after`  | datetime       | No       | Return pipelines updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime       | No       | Return pipelines updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `username`       | string         | No       | The username of the user who triggered pipelines |
| `yaml_errors`    | boolean        | No       | Returns pipelines with invalid configurations |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

Example of response

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "pending",
    "source": "push",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 1,
    "status": "pending",
    "source": "web",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Get a single pipeline

> - `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.
> - `name` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) in GitLab 15.11 [with a flag](../administration/feature_flags.md) named `pipeline_name_in_api`. Disabled by default.
> - `name` in response [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) in GitLab 16.3. Feature flag `pipeline_name_in_api` removed.

Get one pipeline from a project.

You can also get a single [child pipeline](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

Example of response

```json
{
  "id": 287,
  "iid": 144,
  "project_id": 21,
  "name": "Build pipeline",
  "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
  "ref": "main",
  "status": "success",
  "source": "push",
  "created_at": "2022-09-21T01:05:07.200Z",
  "updated_at": "2022-09-21T01:05:50.185Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
  "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
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
  "started_at": "2022-09-21T01:05:14.197Z",
  "finished_at": "2022-09-21T01:05:50.175Z",
  "committed_at": null,
  "duration": 34,
  "queued_duration": 6,
  "coverage": null,
  "detailed_status": {
    "icon": "status_success",
    "text": "passed",
    "label": "passed",
    "group": "success",
    "tooltip": "passed",
    "has_details": false,
    "details_path": "/test-group/test-project/-/pipelines/287",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
  }
}
```

### Get the latest pipeline

> - `name` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) in GitLab 15.11 [with a flag](../administration/feature_flags.md) named `pipeline_name_in_api`. Disabled by default.
> - `name` in response [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) in GitLab 16.3. Feature flag `pipeline_name_in_api` removed.

Get the latest pipeline for the most recent commit on a specific ref in a project. If no pipeline exists for the commit, a `403` status code is returned.

```plaintext
GET /projects/:id/pipelines/latest
```

| Attribute | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `ref`     | string | No       | The branch or tag to check for the latest pipeline. Defaults to the default branch when not specified. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/latest"
```

Example of response

```json
{
    "id": 287,
    "iid": 144,
    "project_id": 21,
    "name": "Build pipeline",
    "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
    "ref": "main",
    "status": "success",
    "source": "push",
    "created_at": "2022-09-21T01:05:07.200Z",
    "updated_at": "2022-09-21T01:05:50.185Z",
    "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
    "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
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
    "started_at": "2022-09-21T01:05:14.197Z",
    "finished_at": "2022-09-21T01:05:50.175Z",
    "committed_at": null,
    "duration": 34,
    "queued_duration": 6,
    "coverage": null,
    "detailed_status": {
        "icon": "status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "tooltip": "passed",
        "has_details": false,
        "details_path": "/test-group/test-project/-/pipelines/287",
        "illustration": null,
        "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
    }
}
```

### Get variables of a pipeline

Get the variables of a pipeline. Does not include variables that come from a pipeline schedule.
For more information, see [issue 250850](https://gitlab.com/gitlab-org/gitlab/-/issues/250850).

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

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

NOTE:
This API route is part of the [Unit test report](../ci/testing/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

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

### Get a pipeline's test report summary

NOTE:
This API route is part of the [Unit test report](../ci/testing/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

Sample request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

Sample response:

```json
{
    "total": {
        "time": 1904,
        "count": 3363,
        "success": 3351,
        "failed": 0,
        "skipped": 12,
        "error": 0,
        "suite_error": null
    },
    "test_suites": [
        {
            "name": "test",
            "total_time": 1904,
            "total_count": 3363,
            "success_count": 3351,
            "failed_count": 0,
            "skipped_count": 12,
            "error_count": 0,
            "build_ids": [
                66004
            ],
            "suite_error": null
        }
    ]
}
```

## Create a new pipeline

> - `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

```plaintext
POST /projects/:id/pipeline
```

| Attribute   | Type           | Required | Description |
|-------------|----------------|----------|-------------|
| `id`        | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `ref`       | string         | Yes      | The branch or tag to run the pipeline on. For merge request pipelines use the [merge requests endpoint](merge_requests.md#create-merge-request-pipeline). |
| `variables` | array          | No       | An [array of hashes](rest/_index.md#array-of-hashes) containing the variables available in the pipeline, matching the structure `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`. If `variable_type` is excluded, it defaults to `env_var`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

Example of response

```json
{
  "id": 61,
  "iid": 21,
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

> - `iid` in response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) in GitLab 14.6.

Retry failed or canceled jobs in a pipeline. If there are no failed or canceled jobs in the pipeline, calling this endpoint has no effect.

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

Response:

```json
{
  "id": 46,
  "iid": 11,
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

NOTE:
This endpoint returns a success response `200` regardless of the pipeline's state.
For more information, see [issue 414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963).

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

Response:

```json
{
  "id": 46,
  "iid": 11,
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

Deleting a pipeline expires all pipeline caches, and deletes all immediately
related objects, such as builds, logs, artifacts, and triggers.
**This action cannot be undone.**

Deleting a pipeline does not automatically delete its
[child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).
See the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)
for details.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## Update pipeline metadata

You can update the metadata of a pipeline. The metadata contains the name of the pipeline.

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`        | string         | Yes      | The new name of the pipeline |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

Sample request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "name=Some new pipeline name" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata"
```

Sample response:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "running",
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
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "name": "Some new pipeline name"
}
```
