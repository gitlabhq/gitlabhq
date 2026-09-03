---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to create, manage, and monitor CI/CD pipelines.
title: Pipelines API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with [CI/CD pipelines](../ci/pipelines/_index.md).

## List pipelines

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250635) in GitLab 19.3.
- Field `project` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252943) in GitLab 19.4.
- Fields `detailed_status`, `started_at`, `finished_at`, `duration`, `queued_duration`, and `merge_request` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253012) in GitLab 19.4.

{{< /history >}}

Lists pipelines across all projects that were triggered by the authenticated user.

Only recently created pipelines are returned. To list the full pipeline history of a specific
project, use [List project pipelines](#list-project-pipelines).

Pipelines from projects the user can no longer access are not included in the results.
By default, [child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)
are not included in the results. To return child pipelines, set `source` to `parent_pipeline`.

The `merge_request` field is included only for [merge request pipelines](../ci/pipelines/merge_request_pipelines.md)
whose merge request is visible to the user.

```plaintext
GET /pipelines
```

The results are [paginated](rest/_index.md#keyset-based-pagination) and return up to 100 records
per page (20 by default). Offset-based pagination is not supported. To retrieve the next page of
results, use the URL in the `Link` response header.

Supported attributes:

| Attribute        | Type     | Required | Description |
|------------------|----------|----------|-------------|
| `created_after`  | datetime | No       | Return pipelines created after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime | No       | Return pipelines created before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `cursor`         | string   | No       | Cursor for keyset pagination, from the `Link` header of a previous response. |
| `order_by`       | string   | No       | Order pipelines by `created_at`. Only `created_at` is supported. Default: `created_at`. |
| `sort`           | string   | No       | Sort pipelines in `desc` order. Only `desc` is supported. Default: `desc`. |
| `source`         | string   | No       | Return pipelines with the specified [source](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable). |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/pipelines?created_after=2016-08-11T00:00:00Z"
```

Example of response

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "running",
    "source": "merge_request_event",
    "ref": "refs/merge-requests/14/merge",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z",
    "started_at": "2016-08-11T11:28:54.085Z",
    "finished_at": null,
    "duration": null,
    "queued_duration": 20,
    "detailed_status": {
      "icon": "status_running",
      "text": "Running",
      "label": "running",
      "group": "running",
      "tooltip": "running",
      "has_details": true,
      "details_path": "/foo/bar/-/pipelines/47",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_running.png"
    },
    "merge_request": {
      "iid": 14,
      "title": "Add rate limiting to the public API",
      "web_url": "https://example.com/foo/bar/-/merge_requests/14"
    },
    "project": {
      "id": 1,
      "description": "",
      "name": "Bar",
      "name_with_namespace": "Foo / Bar",
      "path": "bar",
      "path_with_namespace": "foo/bar",
      "created_at": "2016-08-10T09:00:00.000Z"
    }
  },
  {
    "id": 51,
    "iid": 5,
    "project_id": 3,
    "status": "success",
    "source": "web",
    "ref": "main",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "name": "Deploy pipeline",
    "web_url": "https://example.com/foo/baz/pipelines/51",
    "created_at": "2016-08-11T09:07:01.514Z",
    "updated_at": "2016-08-11T09:12:44.782Z",
    "started_at": "2016-08-11T09:07:31.514Z",
    "finished_at": "2016-08-11T09:12:44.782Z",
    "duration": 313,
    "queued_duration": 30,
    "detailed_status": {
      "icon": "status_success",
      "text": "Passed",
      "label": "passed",
      "group": "success",
      "tooltip": "passed",
      "has_details": true,
      "details_path": "/foo/baz/-/pipelines/51",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_success.png"
    },
    "project": {
      "id": 3,
      "description": "",
      "name": "Baz",
      "name_with_namespace": "Foo / Baz",
      "path": "baz",
      "path_with_namespace": "foo/baz",
      "created_at": "2016-08-10T09:00:00.000Z"
    }
  }
]
```

## List project pipelines

{{< history >}}

- Support for returning child pipelines with `source` set to `parent_pipeline` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/39503) in GitLab 17.0.

{{< /history >}}

Lists pipelines in a project.

By default, [child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)
are not included in the results. To return child pipelines, set `source` to `parent_pipeline`.

```plaintext
GET /projects/:id/pipelines
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute        | Type              | Required | Description |
|------------------|-------------------|----------|-------------|
| `id`             | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`           | string            | No       | Return pipelines with the specified name. |
| `order_by`       | string            | No       | The field to order pipelines by: `id`, `status`, `ref`, `updated_at`, or `user_id` (default: `id`). |
| `ref`            | string            | No       | Return pipelines for the specified branch or tag. |
| `scope`          | string            | No       | Return pipelines in the specified scope: `running`, `pending`, `finished`, `branches`, or `tags`. |
| `sha`            | string            | No       | Return pipelines for the specified commit SHA. |
| `sort`           | string            | No       | The sort order: `asc` or `desc` (default: `desc`). |
| `source`         | string            | No       | Return pipelines with the specified [source](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `status`         | string            | No       | Return pipelines with the specified status: `created`, `waiting_for_resource`, `preparing`, `waiting_for_callback`, `pending`, `running`, `success`, `failed`, `canceling`, `canceled`, `skipped`, `manual`, or `scheduled`. |
| `updated_after`  | datetime          | No       | Return pipelines updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime          | No       | Return pipelines updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_after`  | datetime          | No       | Return pipelines created after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime          | No       | Return pipelines created before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `username`       | string            | No       | Return pipelines triggered by the specified username. |
| `yaml_errors`    | boolean           | No       | Return pipelines with invalid configurations. |

When `scope` is set to `branches` or `tags`, the API returns only the latest pipeline for each branch or tag ref.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines"
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

## Retrieve a single pipeline

Retrieves a single pipeline from a project.

You can also get a single [child pipeline](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
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
  },
  "archived": false
}
```

## Retrieve the latest pipeline

Retrieves the latest pipeline for the most recent commit on a specific ref in a project. If no pipeline exists for the commit, a `403` status code is returned.

```plaintext
GET /projects/:id/pipelines/latest
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `ref`     | string | No       | The branch or tag to check for the latest pipeline. Defaults to the default branch when not specified. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/latest"
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
    },
    "archived": false
}
```

## Retrieve pipeline variables

Retrieves the [pipeline variables](../ci/variables/_index.md#use-pipeline-variables) of a pipeline.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
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

## Retrieve a test report for a pipeline

> [!note]
> This API route is part of the [Unit test report](../ci/testing/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

Sample request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
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

## Retrieve a test report summary for a pipeline

> [!note]
> This API route is part of the [Unit test report](../ci/testing/unit_test_reports.md) feature.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

Sample request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
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

{{< history >}}

- `inputs` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519958) in GitLab 17.10 [with a feature flag](../administration/feature_flags/_index.md) named `ci_inputs_for_pipelines`. Enabled by default.
- `inputs` attribute [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) in GitLab 18.1. Feature flag `ci_inputs_for_pipelines` removed.

{{< /history >}}

```plaintext
POST /projects/:id/pipeline
```

| Attribute   | Type           | Required | Description |
|-------------|----------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `ref`       | string         | Yes      | The branch or tag to run the pipeline on. For merge request pipelines use the [merge requests endpoint](merge_requests.md#create-merge-request-pipeline). |
| `variables` | array          | No       | An [array of hashes](rest/_index.md#array-of-hashes) containing the variables available in the pipeline, matching the structure `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`. If `variable_type` is excluded, it defaults to `env_var`. |
| `inputs`    | hash           | No       | A [hash](rest/_index.md#hash) containing the inputs, as key-value pairs, to use when creating the pipeline. |

Basic example:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

Example request with [inputs](../ci/inputs/_index.md):

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}'
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
  "web_url": "https://example.com/foo/bar/pipelines/61",
  "archived": false
}
```

## Retry jobs in a pipeline

Retries failed or canceled jobs in a pipeline. If there are no failed or canceled jobs in the pipeline, calling this endpoint has no effect.

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
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
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## Cancel all jobs for a pipeline

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

> [!note]
> This endpoint returns a success response `200` regardless of the pipeline's state.
> For more information, see [issue 414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963).

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
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
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## Delete a pipeline

Deleting a pipeline expires all pipeline caches, and deletes all immediately
related objects, such as builds, logs, artifacts, and triggers.
**This action cannot be undone**.

Deleting a pipeline does not automatically delete its
[child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).
See the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)
for details.

Prerequisites:

- The Owner role for the project.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## Update pipeline metadata

Updates pipeline metadata. The metadata contains the name of the pipeline.

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| Attribute     | Type           | Required | Description |
|---------------|----------------|----------|-------------|
| `id`          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`        | string         | Yes      | The new name of the pipeline |
| `pipeline_id` | integer        | Yes      | The ID of a pipeline |

Sample request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata" \
  --data '{"name": "Some new pipeline name"}'
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
  "name": "Some new pipeline name",
  "archived": false
}
```
