---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group webhooks API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Interact with group [webhooks](../user/project/integrations/webhooks.md) by using the REST API. Also called group hooks.
These are different from [system hooks](system_hooks.md) that are system wide and [project webhooks](project_webhooks.md) that are limited to one project.

Prerequisites:

- You must be an Administrator or have the Owner role for the group.

## List group hooks

Get a list of group hooks

```plaintext
GET /groups/:id/hooks
```

Supported attributes:

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string  | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks"
```

Example response:

```json
[
  {
    "id": 1,
    "url": "http://example.com/hook",
    "name": "Test group hook",
    "description": "This is a test group hook.",
    "created_at": "2024-09-01T09:10:54.854Z",
    "push_events": true,
    "tag_push_events": false,
    "merge_requests_events": false,
    "repository_update_events": false,
    "enable_ssl_verification": true,
    "alert_status": "executable",
    "disabled_until": null,
    "url_variables": [],
    "push_events_branch_filter": null,
    "branch_filter_strategy": "all_branches",
    "custom_webhook_template": "",
    "custom_headers": [],
    "group_id": 99,
    "issues_events": false,
    "confidential_issues_events": false,
    "note_events": false,
    "confidential_note_events": false,
    "pipeline_events": false,
    "wiki_page_events": false,
    "job_events": false,
    "deployment_events": false,
    "feature_flag_events": false,
    "releases_events": false,
    "subgroup_events": false,
    "emoji_events": false,
    "resource_access_token_events": false,
    "member_events": false,
    "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
    "custom_headers": [
      {
        "key": "Authorization"
      }
    ]
  }
]
```

## Get a group hook

Get a specific hook for a group.

```plaintext
GET /groups/:id/hooks/:hook_id
```

Supported attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer        | yes      | The ID of a group hook. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

Example response:

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": false,
  "releases_events": true,
  "subgroup_events": true,
  "member_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ]
}
```

## Get group hook events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) in GitLab 17.3.

Get a list of events for a specific group hook in the past seven days from start date.

```plaintext
GET /groups/:id/hooks/:hook_id/events
```

Supported attributes:

| Attribute | Type              | Required | Description                                                                                                                                                                                 |
|-----------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).                                                                                                          |
| `hook_id` | integer           | Yes      | The ID of a project hook.                                                                                                                                                                   |
| `status` | integer or string | No | The response status code of the events, for example: `200` or `500`. You can search by status category: `successful` (200-299), `client_failure` (400-499), and `server_failure` (500-599). |
| `page`             | integer | No | Page to retrieve. Defaults to `1`.                                                                                                                                                          |
| `per_page`         | integer | No | Number of records to return per page. Defaults to `20`.                                                                                                                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/events"
```

Example response:

```json
[
  {
    "id": 1,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "a5461c4d-9c7f-4af9-add6-cddebe3c426f",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push"
    }
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:17 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0906479999999874,
    "response_status": "200"
  },
  {
    "id": 2,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "1f0a54f0-0529-408d-a5b8-a2a98ff5f94a",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com:3000",
      "X-Gitlab-Event-UUID": "842d7c3e-3114-4396-8a95-66c084d53cb1",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:19 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0716120000000728,
    "response_status": "200"
  }
]
```

### Resend group hook event

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) in GitLab 17.4.

Resends a specific hook event.

This endpoint has a rate limit of five requests per minute for each hook and authenticated user.
To disable this limit on GitLab Self-Managed and GitLab Dedicated, an administrator can
[disable the feature flag](../administration/feature_flags.md) named `web_hook_event_resend_api_endpoint_rate_limit`.

```plaintext
POST /groups/:id/hooks/:hook_id/events/:hook_event_id/resend
```

Supported attributes:

| Attribute | Type             | Required | Description             |
|-----------|------------------|----------|-------------------------|
| `id`      | integer/string   | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer          | Yes      | The ID of a group hook. |
| `hook_event_id`      | integer | Yes      | The ID of a hook event. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/events/1/resend"
```

Example response:

```json
{
  "response_status": 200
}
```

## Add a group hook

Adds a hook to a specified group.

```plaintext
POST /groups/:id/hooks
```

Supported attributes:

| Attribute                    | Type           | Required | Description |
| -----------------------------| -------------- |----------| ----------- |
| `id`                         | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `url`                        | string         | yes      | The hook URL. |
| `name`                       | string         | no       | Name of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `description`                | string         | no       | Description of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `push_events`                | boolean        | no       | Trigger hook on push events. |
| `push_events_branch_filter`  | string         | no       | Trigger hook on push events for matching branches only. |
| `branch_filter_strategy`     | string         | no       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `issues_events`              | boolean        | no       | Trigger hook on issues events. |
| `confidential_issues_events` | boolean        | no       | Trigger hook on confidential issues events. |
| `merge_requests_events`      | boolean        | no       | Trigger hook on merge requests events. |
| `tag_push_events`            | boolean        | no       | Trigger hook on tag push events. |
| `note_events`                | boolean        | no       | Trigger hook on note events. |
| `confidential_note_events`   | boolean        | no       | Trigger hook on confidential note events. |
| `job_events`                 | boolean        | no       | Trigger hook on job events. |
| `pipeline_events`            | boolean        | no       | Trigger hook on pipeline events. |
| `wiki_page_events`           | boolean        | no       | Trigger hook on wiki page events. |
| `deployment_events`          | boolean        | no       | Trigger hook on deployment events. |
| `feature_flag_events`        | boolean        | no       | Trigger hook on feature flag events. |
| `releases_events`            | boolean        | no       | Trigger hook on release events. |
| `subgroup_events`            | boolean        | no       | Trigger hook on subgroup events. |
| `member_events`              | boolean        | no       | Trigger hook on member events. |
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook. |
| `token`                      | string         | no       | Secret token to validate received payloads; not returned in the response. |
| `resource_access_token_events` | boolean         | no       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string         | no       | Custom webhook template for the hook. |
| `custom_headers`             | array             | No       | Custom headers for the hook. |

Example request:

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks" \
  --data '{"url": "https://example.com/hook", "name": "My Hook", "description": "Hook description"}'
```

Example response:

```json
{
  "id": 42,
  "url": "https://example.com/hook",
  "name": "My Hook",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": true,
  "releases_events": true,
  "subgroup_events": true,
  "member_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
}
```

## Edit group hook

Edits a hook for a specified group.

```plaintext
PUT /groups/:id/hooks/:hook_id
```

Supported attributes:

| Attribute                    | Type           | Required | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id`                    | integer        | yes      | The ID of the group hook. |
| `url`                        | string         | yes      | The hook URL. |
| `name`                       | string         | no       | Name of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `description`                | string         | no       | Description of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `push_events`                | boolean        | no       | Trigger hook on push events. |
| `push_events_branch_filter`  | string         | no       | Trigger hook on push events for matching branches only. |
| `branch_filter_strategy`     | string         | no       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `issues_events`              | boolean        | no       | Trigger hook on issues events. |
| `confidential_issues_events` | boolean        | no       | Trigger hook on confidential issues events. |
| `merge_requests_events`      | boolean        | no       | Trigger hook on merge requests events. |
| `tag_push_events`            | boolean        | no       | Trigger hook on tag push events. |
| `note_events`                | boolean        | no       | Trigger hook on note events. |
| `confidential_note_events`   | boolean        | no       | Trigger hook on confidential note events. |
| `job_events`                 | boolean        | no       | Trigger hook on job events. |
| `pipeline_events`            | boolean        | no       | Trigger hook on pipeline events. |
| `wiki_page_events`           | boolean        | no       | Trigger hook on wiki page events. |
| `deployment_events`          | boolean        | no       | Trigger hook on deployment events. |
| `feature_flag_events`        | boolean        | no       | Trigger hook on feature flag events. |
| `releases_events`            | boolean        | no       | Trigger hook on release events. |
| `subgroup_events`            | boolean        | no       | Trigger hook on subgroup events. |
| `member_events`              | boolean        | no       | Trigger hook on member events. |
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook. |
| `service_access_tokens_expiration_enforced` | boolean | no | Require service account access tokens to have an expiration date. |
| `token`                      | string         | no       | Secret token to validate received payloads. Not returned in the response. When you change the webhook URL, the secret token is reset and not retained. |
| `resource_access_token_events` | boolean      | no       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string         | no       | Custom webhook template for the hook. |
| `custom_headers`             | array             | no       | Custom headers for the hook. |

Example request:

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1" \
  --data '{"url": "https://example.com/hook", "name": "New hook name", "description": "Changed hook description"}'
```

Example response:

```json
{
  "id": 1,
  "url": "https://example.com/hook",
  "name": "New hook name",
  "description": "Changed hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": true,
  "releases_events": true,
  "subgroup_events": true,
  "member_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ]
}
```

## Delete a group hook

Deletes a hook from a group. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

Supported attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer        | yes      | The ID of the group hook. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

On success, no message is returned.

## Trigger a test group hook

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/455589) in GitLab 17.1.
> - Special rate limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486) in GitLab 17.1 [with a flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`. Enabled by default.

Trigger a test hook for a specified group.

This endpoint has a rate limit of five requests per minute for each group and authenticated user.
To disable this limit on GitLab Self-Managed and GitLab Dedicated, an administrator can
[disable the feature flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`.

```plaintext
POST /groups/:id/hooks/:hook_id/test/:trigger
```

| Attribute | Type              | Required | Description                                                                                                                                                                                                                                                |
|-----------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `hook_id` | integer           | Yes      | The ID of the group hook.                                                                                                                                                                                                                                  |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).                                                                                                                                                                           |
| `trigger` | string            | Yes      | One of `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `emoji_events`, or `resource_access_token_events`. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/test/push_events"
```

Example response:

```json
{"message":"201 Created"}
```

## Set a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

Sets a custom header.

```plaintext
PUT /groups/:id/hooks/:hook_id/custom_headers/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | The ID of the group hook. |
| `key`     | string            | Yes      | The key of the custom header. |
| `value`   | string            | Yes      | The value of the custom header. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key?value='header_value'"
```

On success, no message is returned.

## Delete a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

Deletes a custom header.

```plaintext
DELETE /groups/:id/hooks/:hook_id/custom_headers/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | The ID of the group hook. |
| `key`     | string            | Yes      | The key of the custom header. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key"
```

On success, no message is returned.

## Set a URL variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310) in GitLab 15.2.

```plaintext
PUT /groups/:id/hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | The ID of the group hook. |
| `key`     | string            | Yes      | The key of the URL variable. |
| `value`   | string            | Yes      | The value of the URL variable. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key?value='my_key_value'"
```

On success, no message is returned.

## Delete a URL variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310) in GitLab 15.2.

```plaintext
DELETE /groups/:id/hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | The ID of the group hook. |
| `key`     | string            | Yes      | The key of the URL variable. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key"
```

On success, no message is returned.
