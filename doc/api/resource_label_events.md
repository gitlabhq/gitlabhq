---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Resource label events API **(FREE)**

Resource label events keep track about who, when, and which label was added to (or removed from)
an issue, merge request, or epic.

## Issues

### List project issue label events

Gets a list of all label events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`         | integer          | yes        | The IID of an issue |

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
    "resource_id": 253,
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
    },
    "action": "add"
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
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "remove"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events"
```

### Get single issue label event

Returns a single label event for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events/:resource_label_event_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `resource_label_event_id` | integer        | yes      | The ID of a label event |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events/1"
```

## Epics **(ULTIMATE)**

### List group epic label events

Gets a list of all label events for a single epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`           | integer          | yes        | The ID of an epic |

```json
[
  {
    "id": 106,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
    },
    "action": "add"
  },
  {
    "id": 107,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 37,
      "name": "glabel2",
      "color": "#A8D695",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events"
```

### Get single epic label event

Returns a single label event for a specific group epic

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events/:resource_label_event_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `resource_label_event_id` | integer        | yes      | The ID of a label event |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events/107"
```

## Merge requests

### List project merge request label events

Gets a list of all label events for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer          | yes        | The IID of a merge request |

```json
[
  {
    "id": 119,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "add"
  },
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
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 41,
      "name": "project",
      "color": "#D1D100",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events"
```

### Get single merge request label event

Returns a single label event for a specific project merge request

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events/:resource_label_event_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `resource_label_event_id`     | integer        | yes      | The ID of a label event |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events/120"
```
