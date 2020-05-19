# Pipelines API

## Pipelines pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

## List project pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5837) in GitLab 8.11

```plaintext
GET /projects/:id/pipelines
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`   | string  | no       | The scope of pipelines, one of: `running`, `pending`, `finished`, `branches`, `tags` |
| `status`  | string  | no       | The status of pipelines, one of: `running`, `pending`, `success`, `failed`, `canceled`, `skipped`, `created`, `manual` |
| `ref`     | string  | no       | The ref of pipelines |
| `sha`     | string  | no       | The SHA of pipelines |
| `yaml_errors`| boolean  | no       | Returns pipelines with invalid configurations |
| `name`| string  | no       | The name of the user who triggered pipelines |
| `username`| string  | no       | The username of the user who triggered pipelines |
| `updated_after` | datetime | no | Return pipelines updated after the specified date. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |
| `updated_before` | datetime | no | Return pipelines updated before the specified date. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |
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
    "status": "pending",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z",
  },
  {
    "id": 48,
    "status": "pending",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z",
  }
]
```

## Get a single pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5837) in GitLab 8.11

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

Example of response

```json
{
  "id": 46,
  "status": "success",
  "ref": "master",
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
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
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

CAUTION: **Caution:**
This API route is part of the [JUnit test report](../ci/junit_test_reports.md) feature. It is protected by a [feature flag](../development/feature_flags/index.md) that is **disabled** due to performance issues with very large data sets. See [the documentation for the feature](../ci/junit_test_reports.md#enabling-the-feature) for further details.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/7209) in GitLab 8.14

```plaintext
POST /projects/:id/pipeline
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `ref`       | string  | yes      | Reference to commit |
| `variables` | array   | no       | An array containing the variables available in the pipeline, matching the structure `[{ 'key' => 'UPLOAD_TO_S3', 'variable_type' => 'file', 'value' => 'true' }]` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=master"
```

Example of response

```json
{
  "id": 61,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "master",
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
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61"
}
```

## Retry jobs in a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5837) in GitLab 8.11

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

Response:

```json
{
  "id": 46,
  "status": "pending",
  "ref": "master",
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
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## Cancel a pipeline's jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5837) in GitLab 8.11

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes   | The ID of a pipeline |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

Response:

```json
{
  "id": 46,
  "status": "canceled",
  "ref": "master",
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
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `pipeline_id` | integer | yes      | The ID of a pipeline   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```
