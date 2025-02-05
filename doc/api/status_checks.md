---
stage: Security Risk Management
group: Security Policies
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: External Status Checks API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Get project external status check services

You can request information about a project's external status check services using the following endpoint:

```plaintext
GET /projects/:id/external_status_checks
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | ID of a project     |

```json
[
  {
    "id": 1,
    "name": "Compliance Tool",
    "project_id": 6,
    "external_url": "https://gitlab.com/example/compliance-tool",
    "hmac": true,
    "protected_branches": [
      {
        "id": 14,
        "project_id": 6,
        "name": "main",
        "created_at": "2020-10-12T14:04:50.787Z",
        "updated_at": "2020-10-12T14:04:50.787Z",
        "code_owner_approval_required": false
      }
    ]
  }
]
```

## Create external status check service

You can create a new external status check service for a project using the following endpoint:

```plaintext
POST /projects/:id/external_status_checks
```

WARNING:
External status checks send information about all applicable merge requests to the
defined external service. This includes confidential merge requests.

| Attribute              | Type             | Required | Description                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | integer          | yes      | ID of a project                                |
| `name`                 | string           | yes      | Display name of external status check service  |
| `external_url`         | string           | yes      | URL of external status check service           |
| `shared_secret`        | string           | no       | HMAC secret for external status check          |
| `protected_branch_ids` | `array<Integer>` | no       | IDs of protected branches to scope the rule by |

## Update external status check service

You can update an existing external status check for a project using the following endpoint:

```plaintext
PUT /projects/:id/external_status_checks/:check_id
```

| Attribute              | Type             | Required | Description                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | integer          | yes      | ID of a project                                |
| `check_id`             | integer          | yes      | ID of an external status check service         |
| `name`                 | string           | no       | Display name of external status check service  |
| `external_url`         | string           | no       | URL of external status check service           |
| `shared_secret`        | string           | no       | HMAC secret for external status check          |
| `protected_branch_ids` | `array<Integer>` | no       | IDs of protected branches to scope the rule by |

## Delete external status check service

You can delete an external status check service for a project using the following endpoint:

```plaintext
DELETE /projects/:id/external_status_checks/:check_id
```

| Attribute              | Type           | Required | Description                            |
|------------------------|----------------|----------|----------------------------------------|
| `check_id`             | integer        | yes      | ID of an external status check service |
| `id`                   | integer        | yes      | ID of a project                        |

## List status checks for a merge request

For a single merge request, list the external status check services that apply to it and their status.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/status_checks
```

**Parameters:**

| Attribute                | Type    | Required | Description                |
| ------------------------ | ------- | -------- | -------------------------- |
| `id`                     | integer | yes      | ID of a project            |
| `merge_request_iid`      | integer | yes      | IID of a merge request     |

```json
[
    {
        "id": 2,
        "name": "Service 1",
        "external_url": "https://gitlab.com/test-endpoint",
        "status": "passed"
    },
    {
        "id": 1,
        "name": "Service 2",
        "external_url": "https://gitlab.com/test-endpoint-2",
        "status": "pending"
    }
]
```

## Set status of an external status check

> - Support for `failed` and `passed` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/353836) in GitLab 15.0
> - Support for `pending` in GitLab 16.5 [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/413723) in GitLab 16.5

For a single merge request, use the API to inform GitLab that a merge request has passed a check by an external service.
To set the status of an external check, the personal access token used must belong to a user with at least the Developer role on the target project of the merge request.

Execute this API call as any user with rights to approve the merge request itself.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_check_responses
```

**Parameters:**

| Attribute                  | Type    | Required | Description                                                                                       |
| -------------------------- | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                       | integer | yes      | ID of a project                                                                                   |
| `merge_request_iid`        | integer | yes      | IID of a merge request                                                                            |
| `sha`                      | string  | yes      | SHA at `HEAD` of the source branch                                                                |
| `external_status_check_id` | integer | yes      | ID of an external status check                                                                    |
| `status`                   | string  | no       | Set to `pending` to mark the check as pending, `passed` to pass the check, or `failed` to fail it |

NOTE:
`sha` must be the SHA at the `HEAD` of the merge request's source branch.

## Retry failed status check for a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383200) in GitLab 15.7.

For a single merge request, retry the specified failed external status check. Even
though the merge request hasn't changed, this endpoint resends the current state of
merge request to the defined external service.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_checks/:external_status_check_id/retry
```

**Parameters:**

| Attribute                  | Type    | Required | Description                           |
| -------------------------- | ------- | -------- | ------------------------------------- |
| `id`                       | integer | yes      | ID of a project                       |
| `merge_request_iid`        | integer | yes      | IID of a merge request                |
| `external_status_check_id` | integer | yes      | ID of a failed external status check |

## Response

In case of success status code is 202.

```json
{
    "message": "202 Accepted"
}
```

In case status check is already passed status code is 422

```json
{
    "message": "External status check must be failed"
}
```

## Example payload sent to external service

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "[REDACTED]"
  },
  "project": {
    "id": 6,
    "name": "Flight",
    "description": "Ipsa minima est consequuntur quisquam.",
    "web_url": "http://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
    "git_http_url": "http://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 20,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "main",
    "ci_config_path": null,
    "homepage": "http://example.com/flightjs/Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "ssh_url": "ssh://example.com/flightjs/Flight.git",
    "http_url": "http://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "assignee_id": null,
    "author_id": 1,
    "created_at": "2022-12-07 07:53:43 UTC",
    "description": "",
    "head_pipeline_id": 558,
    "id": 144,
    "iid": 4,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": {
      "force_remove_source_branch": "1"
    },
    "merge_status": "can_be_merged",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": null,
    "source_branch": "root-main-patch-30152",
    "source_project_id": 6,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 6,
    "time_estimate": 0,
    "title": "Update README.md",
    "updated_at": "2022-12-07 07:53:43 UTC",
    "updated_by_id": null,
    "url": "http://example.com/flightjs/Flight/-/merge_requests/4",
    "source": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "target": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "last_commit": {
      "id": "141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "message": "Update README.md",
      "title": "Update README.md",
      "timestamp": "2022-12-07T07:52:11+00:00",
      "url": "http://example.com/flightjs/Flight/-/commit/141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "author": {
        "name": "Administrator",
        "email": "admin@example.com"
      }
    },
    "work_in_progress": false,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [
    ],
    "reviewer_ids": [
    ],
    "labels": [
    ],
    "state": "opened",
    "blocking_discussions_resolved": true,
    "first_contribution": false,
    "detailed_merge_status": "mergeable"
  },
  "labels": [
  ],
  "changes": {
  },
  "repository": {
    "name": "Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "description": "Ipsa minima est consequuntur quisquam.",
    "homepage": "http://example.com/flightjs/Flight"
  },
  "external_approval_rule": {
    "id": 1,
    "name": "QA",
    "external_url": "https://example.com/"
  }
}
```

## Related topics

- [External status checks](../user/project/merge_requests/status_checks.md)
