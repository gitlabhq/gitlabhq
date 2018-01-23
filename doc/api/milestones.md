# Milestones API

## List project milestones

Returns a list of project milestones.

```
GET /projects/:id/milestones
GET /projects/:id/milestones?iids[]=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?search=version
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `iids[]` | Array[integer] | optional | Return only the milestones having the given `iid` |
| `state` | string | optional | Return only `active` or `closed` milestones` |
| `search` | string | optional | Return only milestones with a title or description matching the provided string |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/milestones
```

Example Response:

```json
[
  {
    "id": 12,
    "iid": 3,
    "project_id": 16,
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

Gets a single project milestone.

```
GET /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the project's milestone

## Create new milestone

Creates a new project milestone.

```
POST /projects/:id/milestones
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of a milestone
- `description` (optional) - The description of the milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone

## Edit milestone

Updates an existing project milestone.

```
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone
- `title` (optional) - The title of a milestone
- `description` (optional) - The description of a milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone
- `state_event` (optional) - The state event of the milestone (close|activate)

## Delete project milestone

Only for user with developer access to the project.

```
DELETE /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the project's milestone

## Get all issues assigned to a single milestone

Gets all issues assigned to a single project milestone.

```
GET /projects/:id/milestones/:milestone_id/issues
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single project milestone.

```
GET /projects/:id/milestones/:milestone_id/merge_requests
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone
