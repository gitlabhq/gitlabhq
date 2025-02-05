---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project webhooks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Manage [project webhooks](../user/project/integrations/webhooks.md) by using the REST API. Project webhooks are different
to [system hooks](system_hooks.md), which are system-wide, and [group webhooks](group_webhooks.md).

Prerequisites:

- You must be an administrator or have at least the Maintainer role for the project.

## List webhooks for a project

Get a list of project webhooks.

```plaintext
GET /projects/:id/hooks
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

## Get a project webhook

Get a specific webhook for a project.

```plaintext
GET /projects/:id/hooks/:hook_id
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Yes      | ID of a project webhook. |
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example response:

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "project_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
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
  "releases_events": true,
  "feature_flag_events": true,
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

## Get a list of project webhook events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) in GitLab 17.3.

Get a list of events for a specific project webhook in the past 7 days from start date.

```plaintext
GET /projects/:id/hooks/:hook_id/events
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|:-----------|:------------------|:---------|:------------|
| `hook_id`  | integer           | Yes      | ID of a project webhook. |
| `id`       | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `status`   | integer or string | No       | Response status code of the events, for example: `200` or `500`. You can search by status category: `successful` (200-299), `client_failure` (400-499), and `server_failure` (500-599). |
| `page`     | integer           | No       | Page to retrieve. Defaults to `1`. |
| `per_page` | integer           | No       | Number of records to return per page. Defaults to `20`. |

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
      "Idempotency-Key": "3a427872-00df-429c-9bc9-a9475de2efe4",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
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
      "Idempotency-Key": "7c6e0583-49f2-4dc5-a50b-4c0bcf3c1b27",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com",
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

## Resend a project webhook event

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) in GitLab 17.4.

Resend a specific project webhook event.

This endpoint has a rate limit of five requests per minute for each project webhook and authenticated user.
To disable this limit on GitLab Self-Managed and GitLab Dedicated, an administrator can
[disable the feature flag](../administration/feature_flags.md) named `web_hook_event_resend_api_endpoint_rate_limit`.

```plaintext
POST /projects/:id/hooks/:hook_id/events/:hook_event_id/resend
```

Supported attributes:

| Attribute       | Type    | Required | Description |
|:----------------|:--------|:---------|:------------|
| `hook_id`       | integer | Yes      | ID of a project webhook. |
| `hook_event_id` | integer | Yes      | ID of a project webhook event. |

Example response:

```json
{
  "response_status": 200
}
```

## Add a webhook to a project

> - `name` and `description` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.

Add a webhook to a specified project.

```plaintext
POST /projects/:id/hooks
```

Supported attributes:

| Attribute                      | Type              | Required | Description |
|:-------------------------------|:------------------|:---------|:------------|
| `id`                           | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `url`                          | string            | Yes      | Project webhook URL. |
| `name`                         | string            | No       | Name of the project webhook. |
| `description`                  | string            | No       | Description of the webhook. |
| `confidential_issues_events`   | boolean           | No       | Trigger project webhook on confidential issues events. |
| `confidential_note_events`     | boolean           | No       | Trigger project webhook on confidential note events. |
| `deployment_events`            | boolean           | No       | Trigger project webhook on deployment events. |
| `enable_ssl_verification`      | boolean           | No       | Do SSL verification when triggering the webhook. |
| `feature_flag_events`          | boolean           | No       | Trigger project webhook on feature flag events. |
| `issues_events`                | boolean           | No       | Trigger project webhook on issues events. |
| `job_events`                   | boolean           | No       | Trigger project webhook on job events. |
| `merge_requests_events`        | boolean           | No       | Trigger project webhook on merge requests events. |
| `note_events`                  | boolean           | No       | Trigger project webhook on note events. |
| `pipeline_events`              | boolean           | No       | Trigger project webhook on pipeline events. |
| `push_events_branch_filter`    | string            | No       | Trigger project webhook on push events for matching branches only. |
| `branch_filter_strategy`       | string            | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `push_events`                  | boolean           | No       | Trigger project webhook on push events. |
| `releases_events`              | boolean           | No       | Trigger project webhook on release events. |
| `tag_push_events`              | boolean           | No       | Trigger project webhook on tag push events. |
| `token`                        | string            | No       | Secret token to validate received payloads; the token isn't returned in the response. |
| `wiki_page_events`             | boolean           | No       | Trigger project webhook on wiki events. |
| `resource_access_token_events` | boolean           | No       | Trigger project webhook on project access token expiry events. |
| `custom_webhook_template`      | string            | No       | Custom webhook template for the project webhook. |
| `custom_headers`               | array             | No       | Custom headers for the project webhook. |

## Edit a project webhook

> - `name` and `description` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.

Edit a project webhook for a specified project.

```plaintext
PUT /projects/:id/hooks/:hook_id
```

Supported attributes:

| Attribute                      | Type              | Required | Description |
|:-------------------------------|:------------------|:---------|:------------|
| `hook_id`                      | integer           | Yes      | ID of the project webhook. |
| `id`                           | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `url`                          | string            | Yes      | Project webhook URL. |
| `name`                         | string            | No       | Name of the project webhook. |
| `description`                  | string            | No       | Description of the project webhook. |
| `confidential_issues_events`   | boolean           | No       | Trigger project webhook on confidential issues events. |
| `confidential_note_events`     | boolean           | No       | Trigger project webhook on confidential note events. |
| `deployment_events`            | boolean           | No       | Trigger project webhook on deployment events. |
| `enable_ssl_verification`      | boolean           | No       | Do SSL verification when triggering the hook. |
| `feature_flag_events`          | boolean           | No       | Trigger project webhook on feature flag events. |
| `issues_events`                | boolean           | No       | Trigger project webhook on issues events. |
| `job_events`                   | boolean           | No       | Trigger project webhook on job events. |
| `merge_requests_events`        | boolean           | No       | Trigger project webhook on merge requests events. |
| `note_events`                  | boolean           | No       | Trigger project webhook on note events. |
| `pipeline_events`              | boolean           | No       | Trigger project webhook on pipeline events. |
| `push_events_branch_filter`    | string            | No       | Trigger project webhook on push events for matching branches only. |
| `branch_filter_strategy`       | string            | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `push_events`                  | boolean           | No       | Trigger project webhook on push events. |
| `releases_events`              | boolean           | No       | Trigger project webhook on release events. |
| `tag_push_events`              | boolean           | No       | Trigger project webhook on tag push events. |
| `token`                        | string            | No       | Secret token to validate received payloads. Not returned in the response. When you change the webhook URL, the secret token is reset and not retained. |
| `wiki_page_events`             | boolean           | No       | Trigger project webhook on wiki page events. |
| `resource_access_token_events` | boolean           | No       | Trigger project webhook on project access token expiry events. |
| `custom_webhook_template`      | string            | No       | Custom webhook template for the project webhook. |
| `custom_headers`               | array             | No       | Custom headers for the project webhook. |

## Delete project webhook

Remove a webhook from a project. This method is idempotent and can be called multiple times. The project webhook is either
available or not.

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Note the JSON response differs if the project webhook is available or not. If the project
hook is available before it's returned in the JSON response or an empty response
is returned.

## Trigger a test project webhook

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656) in GitLab 16.11.
> - Special rate limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066) in GitLab 17.0 [with a flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`. Enabled by default.

Trigger a test project webhook for a specified project.

In GitLab 17.0 and later, this endpoint has a special rate limit:

- In GitLab 17.0, the rate was three requests per minute for each project webhook.
- In GitLab 17.1, this was changed to five requests per minute for each project and authenticated user.

To disable this limit on GitLab Self-Managed and GitLab Dedicated, an administrator can
[disable the feature flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`.

```plaintext
POST /projects/:id/hooks/:hook_id/test/:trigger
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `trigger` | string            | Yes      | One of `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `emoji_events`, or `resource_access_token_events`. |

Example response:

```json
{"message":"201 Created"}
```

## Set a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

```plaintext
PUT /projects/:id/hooks/:hook_id/custom_headers/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `key`     | string            | Yes      | Key of the custom header. |
| `value`   | string            | Yes      | Value of the custom header. |

On success, this endpoint returns the response code `204 No Content`.

## Delete a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

```plaintext
DELETE /projects/:id/hooks/:hook_id/custom_headers/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `key`     | string            | Yes      | Key of the custom header. |

On success, this endpoint returns the response code `204 No Content`.

## Set a URL variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310) in GitLab 15.2.

```plaintext
PUT /projects/:id/hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `key`     | string            | Yes      | Key of the URL variable. |
| `value`   | string            | Yes      | Value of the URL variable. |

On success, this endpoint returns the response code `204 No Content`.

## Delete a URL variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310) in GitLab 15.2.

```plaintext
DELETE /projects/:id/hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `hook_id` | integer           | Yes      | ID of the project webhook. |
| `key`     | string            | Yes      | Key of the URL variable. |

On success, this endpoint returns the response code `204 No Content`.
