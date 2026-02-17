---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for merge trains in GitLab.
title: Merge trains API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with [merge trains](../ci/pipelines/merge_trains.md).

Prerequisites:

- You must have the Developer, Maintainer, or Owner role.

All merge train endpoints support [offset-based pagination](rest/_index.md#offset-based-pagination) using the `page` and `per_page` parameters.

## List all merge trains for a project

Lists all merge trains for a specified project.

```plaintext
GET /projects/:id/merge_trains
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `scope`   | string            | No       | Return merge trains filtered by the given scope. Available scopes are `active` (to be merged) and `complete` (have been merged). |
| `sort`    | string            | No       | Return merge trains sorted in `asc` or `desc` order. Default: `desc`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Timestamp when the merge train was created. |
| `duration`                  | integer  | Time spent in seconds on the merge train, or `null` if not completed. |
| `id`                        | integer  | ID of the merge train. |
| `merged_at`                 | datetime | Timestamp when the merge request was merged, or `null` if not merged. |
| `merge_request`             | object   | Merge request details. |
| `merge_request.created_at`  | datetime | Timestamp when the merge request was created. |
| `merge_request.description` | string   | Description of the merge request. |
| `merge_request.id`          | integer  | ID of the merge request. |
| `merge_request.iid`         | integer  | Internal ID of the merge request. |
| `merge_request.project_id`  | integer  | ID of the project containing the merge request. |
| `merge_request.state`       | string   | State of the merge request. |
| `merge_request.title`       | string   | Title of the merge request. |
| `merge_request.updated_at`  | datetime | Timestamp when the merge request was last updated. |
| `merge_request.web_url`     | string   | Web URL of the merge request. |
| `pipeline`                  | object   | Pipeline details, or `null` if no pipeline is associated. |
| `pipeline.created_at`       | datetime | Timestamp when the pipeline was created. |
| `pipeline.id`               | integer  | ID of the pipeline. |
| `pipeline.iid`              | integer  | Internal ID of the pipeline. |
| `pipeline.project_id`       | integer  | ID of the project containing the pipeline. |
| `pipeline.ref`              | string   | Git reference of the pipeline. |
| `pipeline.sha`              | string   | SHA of the commit that triggered the pipeline. |
| `pipeline.source`           | string   | Source of the pipeline trigger. |
| `pipeline.status`           | string   | Status of the pipeline. |
| `pipeline.updated_at`       | datetime | Timestamp when the pipeline was last updated. |
| `pipeline.web_url`          | string   | Web URL of the pipeline. |
| `status`                    | string   | Status of the merge train. Possible values: `idle`, `stale`, `fresh`, `merging`, `merged`, `skip_merged`. |
| `target_branch`             | string   | Name of the target branch. |
| `updated_at`                | datetime | Timestamp when the merge train was last updated. |
| `user`                      | object   | User who added the merge request to the merge train. |
| `user.avatar_url`           | string   | Avatar URL of the user. |
| `user.id`                   | integer  | ID of the user. |
| `user.name`                 | string   | Name of the user. |
| `user.state`                | string   | State of the user account. |
| `user.username`             | string   | Username of the user. |
| `user.web_url`              | string   | Web URL of the user profile. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

Example response:

```json
[
  {
    "id": 110,
    "merge_request": {
      "id": 126,
      "iid": 59,
      "project_id": 20,
      "title": "Test MR 1580978354",
      "description": "",
      "state": "merged",
      "created_at": "2020-02-06T08:39:14.883Z",
      "updated_at": "2020-02-06T08:40:57.038Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59"
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://local.gitlab.test:8181/root"
    },
    "pipeline": {
      "id": 246,
      "sha": "bcc17a8ffd51be1afe45605e714085df28b80b13",
      "ref": "refs/merge-requests/59/train",
      "status": "success",
      "created_at": "2020-02-06T08:40:42.410Z",
      "updated_at": "2020-02-06T08:40:46.912Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/pipelines/246"
    },
    "created_at": "2020-02-06T08:39:47.217Z",
    "updated_at": "2020-02-06T08:40:57.720Z",
    "target_branch": "feature-1580973432",
    "status": "merged",
    "merged_at": "2020-02-06T08:40:57.719Z",
    "duration": 70
  }
]
```

## List all merge requests in a merge train

Lists all merge requests in a merge train for a target branch.

```plaintext
GET /projects/:id/merge_trains/:target_branch
```

Supported attributes:

| Attribute       | Type              | Required | Description |
| --------------- | ----------------- | -------- | ----------- |
| `id`            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `target_branch` | string            | Yes      | The target branch of the merge train. |
| `scope`         | string            | No       | Return merge trains filtered by the given scope. Available scopes are `active` (to be merged) and `complete` (have been merged). |
| `sort`          | string            | No       | Return merge trains sorted in `asc` or `desc` order. Default: `desc`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Timestamp when the merge train was created. |
| `duration`                  | integer  | Time spent in seconds on the merge train, or `null` if not completed. |
| `id`                        | integer  | ID of the merge train. |
| `merged_at`                 | datetime | Timestamp when the merge request was merged, or `null` if not merged. |
| `merge_request`             | object   | Merge request details. |
| `merge_request.created_at`  | datetime | Timestamp when the merge request was created. |
| `merge_request.description` | string   | Description of the merge request. |
| `merge_request.id`          | integer  | ID of the merge request. |
| `merge_request.iid`         | integer  | Internal ID of the merge request. |
| `merge_request.project_id`  | integer  | ID of the project containing the merge request. |
| `merge_request.state`       | string   | State of the merge request. |
| `merge_request.title`       | string   | Title of the merge request. |
| `merge_request.updated_at`  | datetime | Timestamp when the merge request was last updated. |
| `merge_request.web_url`     | string   | Web URL of the merge request. |
| `pipeline`                  | object   | Pipeline details, or `null` if no pipeline is associated. |
| `pipeline.created_at`       | datetime | Timestamp when the pipeline was created. |
| `pipeline.id`               | integer  | ID of the pipeline. |
| `pipeline.iid`              | integer  | Internal ID of the pipeline. |
| `pipeline.project_id`       | integer  | ID of the project containing the pipeline. |
| `pipeline.ref`              | string   | Git reference of the pipeline. |
| `pipeline.sha`              | string   | SHA of the commit that triggered the pipeline. |
| `pipeline.source`           | string   | Source of the pipeline trigger. |
| `pipeline.status`           | string   | Status of the pipeline. |
| `pipeline.updated_at`       | datetime | Timestamp when the pipeline was last updated. |
| `pipeline.web_url`          | string   | Web URL of the pipeline. |
| `status`                    | string   | Status of the merge train. Possible values: `idle`, `stale`, `fresh`, `merging`, `merged`, `skip_merged`. |
| `target_branch`             | string   | Name of the target branch. |
| `updated_at`                | datetime | Timestamp when the merge train was last updated. |
| `user`                      | object   | User who added the merge request to the merge train. |
| `user.avatar_url`           | string   | Avatar URL of the user. |
| `user.id`                   | integer  | ID of the user. |
| `user.name`                 | string   | Name of the user. |
| `user.state`                | string   | State of the user account. |
| `user.username`             | string   | Username of the user. |
| `user.web_url`              | string   | Web URL of the user profile. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/main"
```

Example response:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```

## Retrieve merge train status

Retrieves the merge train status of a specified merge request.

```plaintext
GET /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

Supported attributes:

| Attribute           | Type              | Required | Description |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Timestamp when the merge train was created. |
| `duration`                  | integer  | Time spent in seconds on the merge train, or `null` if not completed. |
| `id`                        | integer  | ID of the merge train. |
| `merged_at`                 | datetime | Timestamp when the merge request was merged, or `null` if not merged. |
| `merge_request`             | object   | Merge request details. |
| `merge_request.created_at`  | datetime | Timestamp when the merge request was created. |
| `merge_request.description` | string   | Description of the merge request. |
| `merge_request.id`          | integer  | ID of the merge request. |
| `merge_request.iid`         | integer  | Internal ID of the merge request. |
| `merge_request.project_id`  | integer  | ID of the project containing the merge request. |
| `merge_request.state`       | string   | State of the merge request. |
| `merge_request.title`       | string   | Title of the merge request. |
| `merge_request.updated_at`  | datetime | Timestamp when the merge request was last updated. |
| `merge_request.web_url`     | string   | Web URL of the merge request. |
| `pipeline`                  | object   | Pipeline details, or `null` if no pipeline is associated. |
| `pipeline.created_at`       | datetime | Timestamp when the pipeline was created. |
| `pipeline.id`               | integer  | ID of the pipeline. |
| `pipeline.iid`              | integer  | Internal ID of the pipeline. |
| `pipeline.project_id`       | integer  | ID of the project containing the pipeline. |
| `pipeline.ref`              | string   | Git reference of the pipeline. |
| `pipeline.sha`              | string   | SHA of the commit that triggered the pipeline. |
| `pipeline.source`           | string   | Source of the pipeline trigger. |
| `pipeline.status`           | string   | Status of the pipeline. |
| `pipeline.updated_at`       | datetime | Timestamp when the pipeline was last updated. |
| `pipeline.web_url`          | string   | Web URL of the pipeline. |
| `status`                    | string   | Status of the merge train. Possible values: `idle`, `stale`, `fresh`, `merging`, `merged`, `skip_merged`. |
| `target_branch`             | string   | Name of the target branch. |
| `updated_at`                | datetime | Timestamp when the merge train was last updated. |
| `user`                      | object   | User who added the merge request to the merge train. |
| `user.avatar_url`           | string   | Avatar URL of the user. |
| `user.id`                   | integer  | ID of the user. |
| `user.name`                 | string   | Name of the user. |
| `user.state`                | string   | State of the user account. |
| `user.username`             | string   | Username of the user. |
| `user.web_url`              | string   | Web URL of the user profile. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

Example response:

```json
{
  "id": 267,
  "merge_request": {
    "id": 273,
    "iid": 1,
    "project_id": 597,
    "title": "My title 9",
    "description": null,
    "state": "opened",
    "created_at": "2022-10-31T19:06:05.725Z",
    "updated_at": "2022-10-31T19:06:05.725Z",
    "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
  },
  "user": {
    "id": 933,
    "username": "user12",
    "name": "Sidney Jones31",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
    "web_url": "http://localhost/user12"
  },
  "pipeline": {
    "id": 273,
    "iid": 1,
    "project_id": 598,
    "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
    "ref": "main",
    "status": "pending",
    "source": "push",
    "created_at": "2022-10-31T19:06:06.231Z",
    "updated_at": "2022-10-31T19:06:06.231Z",
    "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
  },
  "created_at": "2022-10-31T19:06:06.237Z",
  "updated_at": "2022-10-31T19:06:06.237Z",
  "target_branch": "main",
  "status": "idle",
  "merged_at": null,
  "duration": null
}
```

## Add a merge request to a merge train

Adds a specified merge request to a merge train.

```plaintext
POST /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

Supported attributes:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid`      | integer           | Yes      | The internal ID of the merge request. |
| `auto_merge`             | boolean           | No       | If true, the merge request is added to the merge train when the checks pass. When false or unspecified, the merge request is added directly to the merge train. |
| `sha`                    | string            | No       | If present, the SHA must match the `HEAD` of the source branch, otherwise the merge fails. |
| `squash`                 | boolean           | No       | If true, the commits are squashed into a single commit on merge. |
| `when_pipeline_succeeds` | boolean           | No       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/521290) in GitLab 17.11. Use `auto_merge` instead. |

If successful, returns:

- [`201 Created`](rest/troubleshooting.md#status-codes) if the merge request is immediately added to the merge train.
- [`202 Accepted`](rest/troubleshooting.md#status-codes) if the merge request is scheduled to be added to the merge train.

The following response attributes are returned:

| Attribute                   | Type     | Description |
| --------------------------- | -------- | ----------- |
| `created_at`                | datetime | Timestamp when the merge train was created. |
| `duration`                  | integer  | Time spent in seconds on the merge train, or `null` if not completed. |
| `id`                        | integer  | ID of the merge train. |
| `merged_at`                 | datetime | Timestamp when the merge request was merged, or `null` if not merged. |
| `merge_request`             | object   | Merge request details. |
| `merge_request.created_at`  | datetime | Timestamp when the merge request was created. |
| `merge_request.description` | string   | Description of the merge request. |
| `merge_request.id`          | integer  | ID of the merge request. |
| `merge_request.iid`         | integer  | Internal ID of the merge request. |
| `merge_request.project_id`  | integer  | ID of the project containing the merge request. |
| `merge_request.state`       | string   | State of the merge request. |
| `merge_request.title`       | string   | Title of the merge request. |
| `merge_request.updated_at`  | datetime | Timestamp when the merge request was last updated. |
| `merge_request.web_url`     | string   | Web URL of the merge request. |
| `pipeline`                  | object   | Pipeline details, or `null` if no pipeline is associated. |
| `pipeline.created_at`       | datetime | Timestamp when the pipeline was created. |
| `pipeline.id`               | integer  | ID of the pipeline. |
| `pipeline.iid`              | integer  | Internal ID of the pipeline. |
| `pipeline.project_id`       | integer  | ID of the project containing the pipeline. |
| `pipeline.ref`              | string   | Git reference of the pipeline. |
| `pipeline.sha`              | string   | SHA of the commit that triggered the pipeline. |
| `pipeline.source`           | string   | Source of the pipeline trigger. |
| `pipeline.status`           | string   | Status of the pipeline. |
| `pipeline.updated_at`       | datetime | Timestamp when the pipeline was last updated. |
| `pipeline.web_url`          | string   | Web URL of the pipeline. |
| `status`                    | string   | Status of the merge train. Possible values: `idle`, `stale`, `fresh`, `merging`, `merged`, `skip_merged`. |
| `target_branch`             | string   | Name of the target branch. |
| `updated_at`                | datetime | Timestamp when the merge train was last updated. |
| `user`                      | object   | User who added the merge request to the merge train. |
| `user.avatar_url`           | string   | Avatar URL of the user. |
| `user.id`                   | integer  | ID of the user. |
| `user.name`                 | string   | Name of the user. |
| `user.state`                | string   | State of the user account. |
| `user.username`             | string   | Username of the user. |
| `user.web_url`              | string   | Web URL of the user profile. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

Example response:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```
