---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Resource milestone events API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Resource [milestone](../user/project/milestones/_index.md) events keep track of what happens to
GitLab [issues](../user/project/issues/_index.md) and [merge requests](../user/project/merge_requests/_index.md).

Use them to track which milestone was added or removed, who did it, and when it happened.

## Issues

### List project issue milestone events

Gets a list of all milestone events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events
```

| Attribute   | Type           | Required | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid` | integer        | yes      | The IID of an issue                                                             |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events"
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
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
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
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### Get single issue milestone event

Returns a single milestone event for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events/:resource_milestone_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project |
| `issue_iid`                   | integer        | yes      | The IID of an issue                                                             |
| `resource_milestone_event_id` | integer        | yes      | The ID of a milestone event                                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events/1"
```

## Merge requests

### List project merge request milestone events

Gets a list of all milestone events for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events
```

| Attribute           | Type           | Required | Description                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project |
| `merge_request_iid` | integer        | yes      | The IID of a merge request                                                      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events"
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
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
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
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### Get single merge request milestone event

Returns a single milestone event for a specific project merge request

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events/:resource_milestone_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | integer        | yes      | The IID of a merge request                                                      |
| `resource_milestone_event_id` | integer        | yes      | The ID of a milestone event                                                     |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events/120"
```
