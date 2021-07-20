---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project milestones API **(FREE)**

Use project [milestones](../user/project/milestones/index.md) with the REST API.
There's a separate [group milestones API](group_milestones.md) page.

## List project milestones

Returns a list of project milestones.

```plaintext
GET /projects/:id/milestones
GET /projects/:id/milestones?iids[]=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?title=1.0
GET /projects/:id/milestones?search=version
```

Parameters:

| Attribute                         | Type   | Required | Description |
| ----------------------------      | ------ | -------- | ----------- |
| `id`                              | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `iids[]`                          | integer array | optional | Return only the milestones having the given `iid` (Note: ignored if `include_parent_milestones` is set as `true`) |
| `state`                           | string | optional | Return only `active` or `closed` milestones |
| `title`                           | string | optional | Return only the milestones having the given `title` |
| `search`                          | string | optional | Return only milestones with a title or description matching the provided string |
| `include_parent_milestones`       | boolean | optional | Include group milestones from parent group and its ancestors. Introduced in [GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/196066) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/milestones"
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
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false
  }
]
```

## Get single milestone

Gets a single project milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the project's milestone

## Create new milestone

Creates a new project milestone.

```plaintext
POST /projects/:id/milestones
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of a milestone
- `description` (optional) - The description of the milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone

## Edit milestone

Updates an existing project milestone.

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone
- `title` (optional) - The title of a milestone
- `description` (optional) - The description of a milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone
- `state_event` (optional) - The state event of the milestone (close or activate)

## Delete project milestone

Only for users with the Developer role in the project.

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the project's milestone

## Get all issues assigned to a single milestone

Gets all issues assigned to a single project milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single project milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone

## Promote project milestone to a group milestone

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53861) in GitLab 11.9

Only for users with the Developer role in the group.

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone

## Get all burndown chart events for a single milestone **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4737) in GitLab 12.1
> - Moved to GitLab Premium in 13.9.

Gets all burndown chart events for a single milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone
