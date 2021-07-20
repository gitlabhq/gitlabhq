---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Resource state events API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35210/) in GitLab 13.2.

Resource state events keep track of what happens to GitLab [issues](../user/project/issues/) and
[merge requests](../user/project/merge_requests/).

Use them to track which state was set, who did it, and when it happened.

## Issues

### List project issue state events

Gets a list of all state events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events
```

| Attribute   | Type           | Required | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid` | integer        | yes      | The IID of an issue                                                             |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events"
```

Example response:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 11,
    "state": "opened"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 11,
    "state": "closed"
  }
]
```

### Get single issue state event

Returns a single state event for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events/:resource_state_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path](index.md#namespaced-path-encoding) of the project |
| `issue_iid`                   | integer        | yes      | The IID of an issue                                                             |
| `resource_state_event_id`     | integer        | yes      | The ID of a state event                                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events/143"
```

Example response:

```json
{
  "id": 143,
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2018-08-21T14:38:20.077Z",
  "resource_type": "Issue",
  "resource_id": 11,
  "state": "closed"
}
```

## Merge requests

### List project merge request state events

Gets a list of all state events for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events
```

| Attribute           | Type           | Required | Description                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path](index.md#namespaced-path-encoding) of the project |
| `merge_request_iid` | integer        | yes      | The IID of a merge request                                                      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events"
```

Example response:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 11,
    "state": "opened"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 11,
    "state": "closed"
  }
]
```

### Get single merge request state event

Returns a single state event for a specific project merge request

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events/:resource_state_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid`           | integer        | yes      | The IID of a merge request                                                      |
| `resource_state_event_id`     | integer        | yes      | The ID of a state event                                                     |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events/120"
```

Example response:

```json
{
  "id": 120,
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2018-08-21T14:38:20.077Z",
  "resource_type": "MergeRequest",
  "resource_id": 11,
  "state": "closed"
}
```
