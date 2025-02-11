---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Resource state events API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Resource state events keep track of what happens to GitLab [issues](../user/project/issues/_index.md)
[merge requests](../user/project/merge_requests/_index.md) and [epics starting with GitLab 15.4](../user/group/epics/_index.md)

Use them to track which state was set, who did it, and when it happened.

Resource state events API does not track the initial state ("create" or "open") of resources.
For a resource that was not closed or re-opened, an empty list is returned.

## Issues

### List project issue state events

Gets a list of all state events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events
```

| Attribute   | Type           | Required | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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
| `id`                          | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project |
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
| `id`                | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project |
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
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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

## Epics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97554) in GitLab 15.4.

WARNING:
The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
and is planned for removal in v5 of the API.
In GitLab 17.4 or later, if your administrator [enabled the new look for epics](../user/group/epics/epic_work_items.md), use the
[Work Items API](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/) instead. For more information, see the [guide how to migrate your existing APIs](graphql/epic_work_items_api_migration_guide.md).
This change is a breaking change.

### List group epic state events

Returns a list of all state events for a single epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events
```

| Attribute   | Type           | Required | Description                                                                    |
|-------------| -------------- | -------- |--------------------------------------------------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).   |
| `epic_id`   | integer        | yes      | The ID of an epic.                                                              |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events"
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
    "resource_type": "Epic",
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
    "resource_type": "Epic",
    "resource_id": 11,
    "state": "closed"
  }
]
```

### Get single epic state event

Returns a single state event for a specific group epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events/:resource_state_event_id
```

Parameters:

| Attribute                 | Type           | Required | Description                                                                   |
|---------------------------| -------------- | -------- |-------------------------------------------------------------------------------|
| `id`                      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).  |
| `epic_id`                 | integer        | yes      | The ID of an epic.                                                           |
| `resource_state_event_id` | integer        | yes      | The ID of a state event.                                                       |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events/143"
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
  "resource_type": "Epic",
  "resource_id": 11,
  "state": "closed"
}
```
