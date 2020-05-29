---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Group milestones API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12819) in GitLab 9.5.

This page describes the group milestones API.
There's a separate [project milestones API](./group_milestones.md) page.

## List group milestones

Returns a list of group milestones.

```plaintext
GET /groups/:id/milestones
GET /groups/:id/milestones?iids[]=42
GET /groups/:id/milestones?iids[]=42&iids[]=43
GET /groups/:id/milestones?state=active
GET /groups/:id/milestones?state=closed
GET /groups/:id/milestones?title=1.0
GET /groups/:id/milestones?search=version
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `iids[]`  | integer array | no | Return only the milestones having the given `iid` |
| `state`   | string | no | Return only `active` or `closed` milestones |
| `title`   | string | no | Return only the milestones having the given `title` |
| `search`  | string | no | Return only milestones with a title or description matching the provided string |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/milestones"
```

Example Response:

```json
[
  {
    "id": 12,
    "iid": 3,
    "group_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "web_url": "https://gitlab.com/groups/gitlab-org/-/milestones/42"
  }
]
```

## Get single milestone

Gets a single group milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of the group milestone |

## Create new milestone

Creates a new group milestone.

```plaintext
POST /groups/:id/milestones
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `title` | string | yes | The title of a milestone |
| `description` | string | no | The description of the milestone |
| `due_date` | date | no | The due date of the milestone, in YYYY-MM-DD format (ISO 8601) |
| `start_date` | date | no | The start date of the milestone, in YYYY-MM-DD format (ISO 8601) |

## Edit milestone

Updates an existing group milestone.

```plaintext
PUT /groups/:id/milestones/:milestone_id
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of a group milestone |
| `title` | string | no | The title of a milestone |
| `description` | string | no | The description of a milestone |
| `due_date` | date | no | The due date of the milestone, in YYYY-MM-DD format (ISO 8601) |
| `start_date` | date | no | The start date of the milestone, in YYYY-MM-DD format (ISO 8601) |
| `state_event` | string | no | The state event of the milestone _(`close` or `activate`)_ |

## Delete group milestone

Only for users with Developer access to the group.

```plaintext
DELETE /groups/:id/milestones/:milestone_id
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of the group's milestone |

## Get all issues assigned to a single milestone

Gets all issues assigned to a single group milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/issues
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of a group milestone |

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single group milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/merge_requests
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of a group milestone |

## Get all burndown chart events for a single milestone **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4737) in GitLab 12.1

Get all burndown chart events for a single milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/burndown_events
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `milestone_id` | integer | yes | The ID of a group milestone |
