---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project milestones API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use project [milestones](../user/project/milestones/_index.md) with the REST API.
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
GET /projects/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
```

Parameters:

| Attribute                         | Type   | Required | Description |
| ----------------------------      | ------ | -------- | ----------- |
| `id`                              | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `iids[]`                          | integer array | no | Return only the milestones having the given `iid`. Ignored if `include_ancestors` is `true`.  |
| `state`                           | string | no | Return only `active` or `closed` milestones |
| `title`                           | string | no | Return only the milestones having the given `title` |
| `search`                          | string | no | Return only milestones with a title or description matching the provided string |
| `include_parent_milestones`       | boolean | no | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/433298) in GitLab 16.7. Use `include_ancestors` instead. |
| `include_ancestors`               | boolean | no | Include milestones from all parent groups. |
| `updated_before`                  | datetime | no | Return only milestones updated before the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Introduced in GitLab 15.10 |
| `updated_after`                   | datetime | no | Return only milestones updated after the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Introduced in GitLab 15.10 |

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

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |

## Create new milestone

Creates a new project milestone.

```plaintext
POST /projects/:id/milestones
```

Parameters:

| Attribute     | Type           | Required | Description                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `title`       | string         | yes      | The title of a milestone                                                                                        |
| `description` | string         | no       | The description of the milestone                                                                                |
| `due_date`    | string         | no       | The due date of the milestone (`YYYY-MM-DD`)                                                                    |
| `start_date`  | string         | no       | The start date of the milestone (`YYYY-MM-DD`)                                                                  |

## Edit milestone

Updates an existing project milestone.

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |
| `title`        | string         | no       | The title of a milestone                                                                                        |
| `description`  | string         | no       | The description of the milestone                                                                                |
| `due_date`     | string         | no       | The due date of the milestone (`YYYY-MM-DD`)                                                                    |
| `start_date`   | string         | no       | The start date of the milestone (`YYYY-MM-DD`)                                                                  |
| `state_event`  | string         | no       | The state event of the milestone (close or activate)                                                            |

## Delete project milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Only for users with at least the Planner role for the project.

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |

## Get all issues assigned to a single milestone

Gets all issues assigned to a single project milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single project milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |

## Promote project milestone to a group milestone

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) the minimum user role from Developer to Reporter in GitLab 15.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Only for users with at least the Planner role for the group.

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |

## Get all burndown chart events for a single milestone

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Gets all burndown chart events for a single milestone.

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer        | yes      | The ID of the project's milestone                                                                               |
