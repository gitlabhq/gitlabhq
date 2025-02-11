---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Resource weight events API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Resource weight events keep track of what happens to GitLab [issues](../user/project/issues/_index.md).

Use them to track which weight was set, who did it, and when it happened.

## Issues

### List project issue weight events

Gets a list of all weight events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events
```

| Attribute   | Type           | Required | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid` | integer        | yes      | The IID of an issue                                                             |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events"
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
    "issue_id": 253,
    "weight": 3
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
    "issue_id": 253,
    "weight": 2
  }
]
```

### Get single issue weight event

Returns a single weight event for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events/:resource_weight_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project |
| `issue_iid`                   | integer        | yes      | The IID of an issue                                                             |
| `resource_weight_event_id`    | integer        | yes      | The ID of a weight event                                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events/143"
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
"issue_id": 253,
"weight": 2
}
```
