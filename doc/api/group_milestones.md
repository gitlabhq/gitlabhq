# Group milestones API

> **Notes:**
> [Introduced][ce-12819] in GitLab 9.5.

## List group milestones

Returns a list of group milestones.

```
GET /groups/:id/milestones
GET /groups/:id/milestones?iids[]=42
GET /groups/:id/milestones?iids[]=42&iids[]=43
GET /groups/:id/milestones?state=active
GET /groups/:id/milestones?state=closed
GET /groups/:id/milestones?search=version
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `iids[]` | Array[integer] | optional | Return only the milestones having the given `iid` |
| `state` | string | optional | Return only `active` or `closed` milestones` |
| `search` | string | optional | Return only milestones with a title or description matching the provided string |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/milestones
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
    "created_at": "2013-10-02T09:24:18Z"
  }
]
```


## Get single milestone

Gets a single group milestone.

```
GET /groups/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the group milestone

## Create new milestone

Creates a new group milestone.

```
POST /groups/:id/milestones
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of a milestone
- `description` (optional) - The description of the milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone

## Edit milestone

Updates an existing group milestone.

```
PUT /groups/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a group milestone
- `title` (optional) - The title of a milestone
- `description` (optional) - The description of a milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone
- `state_event` (optional) - The state event of the milestone (close|activate)

## Get all issues assigned to a single milestone

Gets all issues assigned to a single group milestone.

```
GET /groups/:id/milestones/:milestone_id/issues
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a group milestone

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single group milestone.

```
GET /groups/:id/milestones/:milestone_id/merge_requests
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a group milestone

[ce-12819]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12819
