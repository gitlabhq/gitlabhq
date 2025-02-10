---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group milestones API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the group [milestones](../user/project/milestones/_index.md) using the REST API.
There's a separate [project milestones API](milestones.md) page.

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
GET /groups/:id/milestones?search_title=17.3+17.4
GET /groups/:id/milestones?search_title=17.3%2017.4
GET /groups/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?containing_date=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?start_date=2013-10-02T09%3A24%3A18Z&end_date=2013-11-02T09%3A24%3A18Z
```

Parameters:

| Attribute                   | Type   | Required | Description |
| ---------                   | ------ | -------- | ----------- |
| `id`                        | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `iids[]`                    | integer array | no | Return only the milestones having the given `iid`. Ignored if `include_ancestors` is `true`. |
| `state`                     | string | no | Return only `active` or `closed` milestones. |
| `title`                     | string | no | Return only the milestones having the given `title` (case-sensitive). |
| `search`                    | string | no | Return only milestones with a title or description matching the provided string (case-insensitive). |
| `search_title`              | string | no | Return only milestones with a title matching the provided string (case-insensitive). Multiple terms can be provided, separated by an escaped space, either `+` or `%20`, and will be ANDed together. Example: `17.4+17.5` will match substrings `17.4` and `17.5` (in any order). Introduced in GitLab 11.8. |
| `include_parent_milestones` | boolean | no | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/433298) in GitLab 16.7. Use `include_ancestors` instead. |
| `include_ancestors`         | boolean | no | Include milestones for all parent groups. |
| `include_descendants`       | boolean | no | Include milestones for group and its descendants. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421030) in GitLab 16.7. |
| `updated_before`            | datetime | no | Return only milestones updated before the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Introduced in GitLab 15.10. |
| `updated_after`             | datetime | no | Return only milestones updated after the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Introduced in GitLab 15.10. |
| `containing_date`           | datetime | no | Return only milestones where `start_date <= containing_date <= due_date`. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Introduced in GitLab 13.5. |
| `start_date`                | datetime | no | Return only milestones where `due_date >=` the provided `start_date`. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Note: only valid if `end_date` is also provided. Introduced in GitLab 12.8. |
| `end_date`                  | datetime | no | Return only milestones where `start_date <=` the provided `end_date`. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Note: only valid if `start_date` is also provided. Introduced in GitLab 12.8. |

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
    "expired": false,
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
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of the group milestone |

## Create new milestone

Creates a new group milestone.

```plaintext
POST /groups/:id/milestones
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `title` | string | yes | The title of a milestone |
| `description` | string | no | The description of the milestone |
| `due_date` | date | no | The due date of the milestone, in ISO 8601 format (`YYYY-MM-DD`) |
| `start_date` | date | no | The start date of the milestone, in ISO 8601 format (`YYYY-MM-DD`) |

## Edit milestone

Updates an existing group milestone.

```plaintext
PUT /groups/:id/milestones/:milestone_id
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of a group milestone |
| `title` | string | no | The title of a milestone |
| `description` | string | no | The description of a milestone |
| `due_date` | date | no | The due date of the milestone, in ISO 8601 format (`YYYY-MM-DD`) |
| `start_date` | date | no | The start date of the milestone, in ISO 8601 format (`YYYY-MM-DD`) |
| `state_event` | string | no | The state event of the milestone _(`close` or `activate`)_ |

## Delete group milestone

Only for users with the Developer role for the group.

```plaintext
DELETE /groups/:id/milestones/:milestone_id
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of the group's milestone |

## Get all issues assigned to a single milestone

Gets all issues assigned to a single group milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/issues
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of a group milestone |

Currently, this API endpoint doesn't return issues from any subgroups.
If you want to get all the milestones' issues, you can instead use the
[List issues API](issues.md#list-issues) and filter for a
particular milestone (for example, `GET /issues?milestone=1.0.0&state=opened`).

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single group milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/merge_requests
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of a group milestone |

## Get all burndown chart events for a single milestone

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Get all burndown chart events for a single milestone.

```plaintext
GET /groups/:id/milestones/:milestone_id/burndown_events
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `milestone_id` | integer | yes | The ID of a group milestone |
