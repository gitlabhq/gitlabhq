# Merge requests API

Every API call to merge requests must be authenticated.

## List merge requests

> [Introduced][ce-13060] in GitLab 9.5.

Get all merge requests the authenticated user has access to. By
default it returns only merge requests created by the current user. To
get all merge requests, use parameter `scope=all`.

The `state` parameter can be used to get only merge requests with a
given state (`opened`, `closed`, or `merged`) or all of them (`all`).
The pagination parameters `page` and `per_page` can be used to
restrict the list of merge requests.

**Note**: the `changes_count` value in the response is a string, not an
integer. This is because when an MR has too many changes to display and store,
it will be capped at 1,000. In that case, the API will return the string
`"1000+"` for the changes count.

```
GET /merge_requests
GET /merge_requests?state=opened
GET /merge_requests?state=all
GET /merge_requests?milestone=release
GET /merge_requests?labels=bug,reproduced
GET /merge_requests?author_id=5
GET /merge_requests?my_reaction_emoji=star
GET /merge_requests?scope=assigned-to-me
```

Parameters:

| Attribute           | Type     | Required | Description                                                                                                            |
| ------------------- | -------- | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `state`             | string   | no       | Return all merge requests or just those that are `opened`, `closed`, or `merged`                                       |
| `order_by`          | string   | no       | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`                                |
| `sort`              | string   | no       | Return requests sorted in `asc` or `desc` order. Default is `desc`                                                     |
| `milestone`         | string   | no       | Return merge requests for a specific milestone                                                                         |
| `view`              | string   | no       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request                              |
| `labels`            | string   | no       | Return merge requests matching a comma separated list of labels                                                        |
| `created_after`     | datetime | no       | Return merge requests created on or after the given time                                                               |
| `created_before`    | datetime | no       | Return merge requests created on or before the given time                                                              |
| `updated_after`     | datetime | no       | Return merge requests updated on or after the given time                                                               |
| `updated_before`    | datetime | no       | Return merge requests updated on or before the given time                                                              |
| `scope`             | string   | no       | Return merge requests for the given scope: `created-by-me`, `assigned-to-me` or `all`. Defaults to `created-by-me`     |
| `author_id`         | integer  | no       | Returns merge requests created by the given user `id`. Combine with `scope=all` or `scope=assigned-to-me`              |
| `assignee_id`       | integer  | no       | Returns merge requests assigned to the given user `id`                                                                 |
| `my_reaction_emoji` | string   | no       | Return merge requests reacted by the authenticated user by the given `emoji` _([Introduced][ce-14016] in GitLab 10.0)_ |
| `source_branch`     | string   | no       | Return merge requests with the given source branch                                                                     |
| `target_branch`     | string   | no       | Return merge requests with the given target branch                                                                     |
| `search`            | string   | no       | Search merge requests against their `title` and `description`                                                          |

```json
[
  {
    "id": 1,
    "iid": 1,
    "target_branch": "master",
    "source_branch": "test1",
    "project_id": 3,
    "title": "test1",
    "state": "opened",
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "assignee": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [ ],
    "description": "fixed login page css paddings",
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "user_notes_count": 1,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://example.com/example/example/merge_requests/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## List project merge requests

Get all merge requests for this project.
The `state` parameter can be used to get only merge requests with a given state (`opened`, `closed`, or `merged`) or all of them (`all`).
The pagination parameters `page` and `per_page` can be used to restrict the list of merge requests.

```
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

`project_id` represents the ID of the project where the MR resides.
`project_id` will always equal `target_project_id`.

In the case of a merge request from the same project,
`source_project_id`, `target_project_id` and `project_id`
will be the same. In the case of a merge request from a fork,
`target_project_id` and `project_id` will be the same and
`source_project_id` will be the fork project's ID.

**Note**: the `changes_count` value in the response is a string, not an
integer. This is because when an MR has too many changes to display and store,
it will be capped at 1,000. In that case, the API will return the string
`"1000+"` for the changes count.

Parameters:

| Attribute           | Type           | Required | Description                                                                                                                    |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `id`                | integer        | yes      | The ID of a project                                                                                                            |
| `iids[]`            | Array[integer] | no       | Return the request having the given `iid`                                                                                      |
| `state`             | string         | no       | Return all merge requests or just those that are `opened`, `closed`, or `merged`                                               |
| `order_by`          | string         | no       | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`                                        |
| `sort`              | string         | no       | Return requests sorted in `asc` or `desc` order. Default is `desc`                                                             |
| `milestone`         | string         | no       | Return merge requests for a specific milestone                                                                                 |
| `view`              | string         | no       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request                                      |
| `labels`            | string         | no       | Return merge requests matching a comma separated list of labels                                                                |
| `created_after`     | datetime       | no       | Return merge requests created on or after the given time                                                                       |
| `created_before`    | datetime       | no       | Return merge requests created on or before the given time                                                                      |
| `updated_after`     | datetime       | no       | Return merge requests updated on or after the given time                                                                       |
| `updated_before`    | datetime       | no       | Return merge requests updated on or before the given time                                                                      |
| `scope`             | string         | no       | Return merge requests for the given scope: `created-by-me`, `assigned-to-me` or `all` _([Introduced][ce-13060] in GitLab 9.5)_ |
| `author_id`         | integer        | no       | Returns merge requests created by the given user `id` _([Introduced][ce-13060] in GitLab 9.5)_                                 |
| `assignee_id`       | integer        | no       | Returns merge requests assigned to the given user `id` _([Introduced][ce-13060] in GitLab 9.5)_                                |
| `my_reaction_emoji` | string         | no       | Return merge requests reacted by the authenticated user by the given `emoji` _([Introduced][ce-14016] in GitLab 10.0)_         |
| `source_branch`     | string   | no       | Return merge requests with the given source branch                                                                     |
| `target_branch`     | string   | no       | Return merge requests with the given target branch                                                                     |
| `search`            | string         | no       | Search merge requests against their `title` and `description`                                                                  |

```json
[
  {
    "id": 1,
    "iid": 1,
    "target_branch": "master",
    "source_branch": "test1",
    "project_id": 3,
    "title": "test1",
    "state": "opened",
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "assignee": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [ ],
    "description": "fixed login page css paddings",
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "user_notes_count": 1,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": false,
    "web_url": "http://example.com/example/example/merge_requests/1",
    "discussion_locked": false,
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "approvals_before_merge": null
  }
]
```

## Get single MR

Shows information about a single merge request.

```
GET /projects/:id/merge_requests/:merge_request_iid
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "state" : "active",
    "web_url" : "https://gitlab.example.com/root",
    "avatar_url" : null,
    "username" : "root",
    "id" : 1,
    "name" : "Administrator"
  },
  "assignee": {
    "state" : "active",
    "web_url" : "https://gitlab.example.com/root",
    "avatar_url" : null,
    "username" : "root",
    "id" : 1,
    "name" : "Administrator"
  },
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [ ],
  "description": "fixed login page css paddings",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": "9999999999999999999999999999999999999999",
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "approvals_before_merge": null,
  "closed_at": "2018-01-19T14:36:11.086Z",
  "latest_build_started_at": null,
  "latest_build_finished_at": null,
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 8,
    "ref": "master",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0",
    "status": "created"
  },
  "merged_by": null,
  "merged_at": null,
  "closed_by": {
    "state" : "active",
    "web_url" : "https://gitlab.example.com/root",
    "avatar_url" : null,
    "username" : "root",
    "id" : 1,
    "name" : "Administrator"
  }
}
```

## Get single MR participants

Get a list of merge request participants.

```
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request


```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  },
  {
    "id": 2,
    "name": "John Doe2",
    "username": "user2",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
    "web_url": "http://localhost/user2"
  },
]
```

## Get single MR commits

Get a list of merge request commits.

```
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request


```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dzaporozhets@sphereconsultinginc.com",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph"
  }
]
```

## Get single MR changes

Shows information about the merge request including its files and changes.

```
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```json
{
  "id": 21,
  "iid": 1,
  "project_id": 4,
  "title": "Blanditiis beatae suscipit hic assumenda et molestias nisi asperiores repellat et.",
  "state": "reopened",
  "created_at": "2015-02-02T19:49:39.159Z",
  "updated_at": "2015-02-02T20:08:49.959Z",
  "target_branch": "secret_token",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Chad Hamill",
    "username": "jarrett",
    "id": 5,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/b95567800f828948baf5f4160ebb2473?s=40&d=identicon"
  },
  "assignee": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40&d=identicon"
  },
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "Qui voluptatibus placeat ipsa alias quasi. Deleniti rem ut sint. Optio velit qui distinctio.",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  }
  "changes": [
    {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "--- a/VERSION\ +++ b/VERSION\ @@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "approvals_before_merge": null
}
```

## List MR pipelines

> [Introduced][ce-15454] in GitLab 10.5.0.

Get a list of merge request pipelines.

```
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "master",
    "status": "success"
  }
]
```

## Create MR

Creates a new merge request.
```
POST /projects/:id/merge_requests
```

| Attribute              | Type    | Required | Description                                                                     |
| ---------              | ----    | -------- | -----------                                                                     |
| `id`                   | integer/string  | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `source_branch`        | string  | yes      | The source branch                                                               |
| `target_branch`        | string  | yes      | The target branch                                                               |
| `title`                | string  | yes      | Title of MR                                                                     |
| `assignee_id`          | integer | no       | Assignee user ID                                                                |
| `description`          | string  | no       | Description of MR                                                               |
| `target_project_id`    | integer | no       | The target project (numeric id)                                                 |
| `labels`               | string  | no       | Labels for MR as a comma-separated list                                         |
| `milestone_id`         | integer | no       | The ID of a milestone                                                           |
| `remove_source_branch` | boolean | no       | Flag indicating if a merge request should remove the source branch when merging |
| `approvals_before_merge` | integer| no | Number of approvals required before this can be merged (see below) |
| `squash` | boolean| no | Squash commits into a single commit when merging |
| `allow_maintainer_to_push` | boolean | no       | Whether or not a maintainer of the target project can push to the source branch  |

If `approvals_before_merge` is not provided, it inherits the value from the
target project. If it is provided, then the following conditions must hold in
order for it to take effect:

1. The target project's `approvals_before_merge` must be greater than zero. (A
   value of zero disables approvals for that project.)
2. The provided value of `approvals_before_merge` must be greater than the
   target project's `approvals_before_merge`.

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 4,
  "title": "test1",
  "state": "opened",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "source_project_id": 3,
  "target_project_id": 4,
  "labels": [ ],
  "description": "fixed login page css paddings",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "user_notes_count": 0,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "allow_maintainer_to_push": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "approvals_before_merge": null
}
```

## Update MR

Updates an existing merge request. You can change the target branch, title, or even close the MR.

```
PUT /projects/:id/merge_requests/:merge_request_iid
```

| Attribute              | Type    | Required | Description                                                                     |
| ---------              | ----    | -------- | -----------                                                                     |
| `id`                   | integer/string | yes  | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `merge_request_iid`    | integer | yes      | The ID of a merge request                                                       |
| `target_branch`        | string  | no       | The target branch                                                               |
| `title`                | string  | no       | Title of MR                                                                     |
| `assignee_id`          | integer | no       | The ID of the user to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees.  |
| `milestone_id`         | integer | no       | The ID of a milestone to assign the merge request to. Set to `0` or provide an empty value to unassign a milestone.|
| `labels`               | string  | no       | Comma-separated label names for a merge request. Set to an empty string to unassign all labels.                    |
| `description`          | string  | no       | Description of MR                                                               |
| `state_event`          | string  | no       | New state (close/reopen)                                                        |
| `remove_source_branch` | boolean | no       | Flag indicating if a merge request should remove the source branch when merging |
| `squash` | boolean| no | Squash commits into a single commit when merging |
| `discussion_locked`    | boolean | no       | Flag indicating if the merge request's discussion is locked. If the discussion is locked only project members can add, edit or resolve comments. |
| `allow_maintainer_to_push` | boolean | no       | Whether or not a maintainer of the target project can push to the source branch  |

Must include at least one non-required attribute from above.

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "project_id": 4,
  "title": "test1",
  "state": "opened",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "source_project_id": 3,
  "target_project_id": 4,
  "labels": [ ],
  "description": "description1",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "allow_maintainer_to_push": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "approvals_before_merge": null
}
```

## Delete a merge request

Only for admins and project owners. Soft deletes the merge request in question.

```
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| Attribute | Type    | Required | Description                          |
| --------- | ----    | -------- | -----------                          |
| `id`      | integer/string  | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/merge_requests/85
```

## Accept MR

Merge changes submitted with MR using this API.


If it has some conflicts and can not be merged - you'll get a `405` and the error message 'Branch cannot be merged'

If merge request is already merged or closed - you'll get a `406` and the error message 'Method Not Allowed'

If the `sha` parameter is passed and does not match the HEAD of the source - you'll get a `409` and the error message 'SHA does not match HEAD of source branch'

If you don't have permissions to accept this merge request - you'll get a `401`

```
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required)            - Internal ID of MR
- `merge_commit_message` (optional)         - Custom merge commit message
- `should_remove_source_branch` (optional)  - if `true` removes the source branch
- `merge_when_pipeline_succeeds` (optional)    - if `true` the MR is merged when the pipeline succeeds
- `sha` (optional)                          - if present, then this SHA must match the HEAD of the source branch, otherwise the merge will fail

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "merged",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "fixed login page css paddings",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": "9999999999999999999999999999999999999999",
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "approvals_before_merge": null
}
```

## Cancel Merge When Pipeline Succeeds

If you don't have permissions to accept this merge request - you'll get a `401`

If the merge request is already merged or closed - you get `405` and error message 'Method Not Allowed'

In case the merge request is not set to be merged when the pipeline succeeds, you'll also get a `406` error.
```
PUT /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```
Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required)            - Internal ID of MR

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "opened",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "fixed login page css paddings",
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://example.com/example/example/merge_requests/1",
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "approvals_before_merge": null
}
```

## Comments on merge requests

Comments are done via the [notes](notes.md) resource.

## List issues that will close on merge

Get all the issues that would be closed by merging the provided merge request.

```
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues
```

Example response when the GitLab issue tracker is used:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "changes_count": "1",
      "approvals_before_merge": null
   }
]
```

Example response when an external issue tracker (e.g. JIRA) is used:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## Subscribe to a merge request

Subscribes the authenticated user to a merge request to receive notification. If the user is already subscribed to the merge request, the
status code `304` is returned.

```
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| Attribute           | Type    | Required | Description                 |
| ---------           | ----    | -------- | -----------                 |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user         |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe
```

Example response:

```json
{
  "id": 17,
  "iid": 1,
  "project_id": 5,
  "title": "Et et sequi est impedit nulla ut rem et voluptatem.",
  "description": "Consequatur velit eos rerum optio autem. Quia id officia quaerat dolorum optio. Illo laudantium aut ipsum dolorem.",
  "state": "opened",
  "created_at": "2016-04-05T21:42:23.233Z",
  "updated_at": "2016-04-05T22:11:52.900Z",
  "target_branch": "ui-dev-kit",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Eileen Skiles",
    "username": "leila",
    "id": 19,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/39ce4a2822cc896933ffbd68c1470e55?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/leila"
  },
  "assignee": {
    "name": "Celine Wehner",
    "username": "carli",
    "id": 16,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/f4cd5605b769dd2ce405a27c6e6f2684?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/carli"
  },
  "source_project_id": 5,
  "target_project_id": 5,
  "labels": [],
  "work_in_progress": false,
  "milestone": {
    "id": 7,
    "iid": 1,
    "project_id": 5,
    "title": "v2.0",
    "description": "Corrupti eveniet et velit occaecati dolorem est rerum aut.",
    "state": "closed",
    "created_at": "2016-04-05T21:41:40.905Z",
    "updated_at": "2016-04-05T21:41:40.905Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "cannot_be_merged",
  "subscribed": true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null
}
```

## Unsubscribe from a merge request

Unsubscribes the authenticated user from a merge request to not receive
notifications from that merge request. If the user is
not subscribed to the merge request, the status code `304` is returned.

```
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe
```

Example response:

```json
{
  "id": 17,
  "iid": 1,
  "project_id": 5,
  "title": "Et et sequi est impedit nulla ut rem et voluptatem.",
  "description": "Consequatur velit eos rerum optio autem. Quia id officia quaerat dolorum optio. Illo laudantium aut ipsum dolorem.",
  "state": "opened",
  "created_at": "2016-04-05T21:42:23.233Z",
  "updated_at": "2016-04-05T22:11:52.900Z",
  "target_branch": "ui-dev-kit",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Eileen Skiles",
    "username": "leila",
    "id": 19,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/39ce4a2822cc896933ffbd68c1470e55?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/leila"
  },
  "assignee": {
    "name": "Celine Wehner",
    "username": "carli",
    "id": 16,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/f4cd5605b769dd2ce405a27c6e6f2684?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/carli"
  },
  "source_project_id": 5,
  "target_project_id": 5,
  "labels": [],
  "work_in_progress": false,
  "milestone": {
    "id": 7,
    "iid": 1,
    "project_id": 5,
    "title": "v2.0",
    "description": "Corrupti eveniet et velit occaecati dolorem est rerum aut.",
    "state": "closed",
    "created_at": "2016-04-05T21:41:40.905Z",
    "updated_at": "2016-04-05T21:41:40.905Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "cannot_be_merged",
  "subscribed": false,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null
}
```

## Create a todo

Manually creates a todo for the current user on a merge request.
If there already exists a todo for the user on that merge request,
status code `304` is returned.

```
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo
```

Example response:

```json
{
  "id": 113,
  "project": {
    "id": 3,
    "name": "Gitlab Ci",
    "name_with_namespace": "Gitlab Org / Gitlab Ci",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "MergeRequest",
  "target": {
    "id": 27,
    "iid": 7,
    "project_id": 3,
    "title": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
    "description": "Veniam sunt nihil modi earum cumque illum delectus. Nihil ad quis distinctio quia. Autem eligendi at quibusdam repellendus.",
    "state": "opened",
    "created_at": "2016-06-17T07:48:04.330Z",
    "updated_at": "2016-07-01T11:14:15.537Z",
    "target_branch": "allow_regex_for_project_skip_ref",
    "source_branch": "backup",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca",
      "discussion_locked": false
    },
    "assignee": {
      "name": "Dr. Gabrielle Strosin",
      "username": "barrett.krajcik",
      "id": 4,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/733005fcd7e6df12d2d8580171ccb966?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/barrett.krajcik"
    },
    "source_project_id": 3,
    "target_project_id": 3,
    "labels": [],
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 3,
      "title": "v1.0",
      "description": "Quis ea accusantium animi hic fuga assumenda.",
      "state": "active",
      "created_at": "2016-06-17T07:47:33.840Z",
      "updated_at": "2016-06-17T07:47:33.840Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "subscribed": true,
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "user_notes_count": 7,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": true,
    "web_url": "http://example.com/example/example/merge_requests/1"
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/merge_requests/7",
  "body": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
  "state": "pending",
  "created_at": "2016-07-01T11:14:15.530Z"
}
```

## Get MR diff versions

Get a list of merge request diff versions.

```
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| Attribute           | Type    | Required | Description                 |
| ---------           | ------- | -------- | ---------------------       |
| `id`                | String  | yes      | The ID of the project       |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions
```

Example response:

```json
[{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1"
}]
```

## Get a single MR diff version

Get a single merge request diff version.

```
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ------- | -------- | ---------------------                    |
| `id`                | String  | yes      | The ID of the project                    |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request     |
| `version_id`        | integer | yes      | The ID of the merge request diff version |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1
```

Example response:

```json
{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "--- /dev/null\n+++ b/LICENSE\n@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false
  }]
}
```
## Set a time estimate for a merge request

Sets an estimated time of work for this merge request.

```
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ----    | -------- | -----------                              |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                      |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request     |
| `duration`          | string  | yes      | The duration in human format. e.g: 3h30m |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m
```

Example response:

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

## Reset the time estimate for a merge request

Resets the estimated time for this merge request to 0 seconds.

```
POST /projects/:id/merge_requests/:merge_request_iid/reset_time_estimate
```

| Attribute           | Type    | Required | Description                                  |
| ---------           | ----    | -------- | -----------                                  |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                          |
| `merge_request_iid` | integer | yes      | The internal ID of a project's merge_request |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Add spent time for a merge request

Adds spent time for this merge request

```
POST /projects/:id/merge_requests/:merge_request_iid/add_spent_time
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ----    | -------- | -----------                              |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                      |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request     |
| `duration`          | string  | yes      | The duration in human format. e.g: 3h30m |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

## Reset spent time for a merge request

Resets the total spent time for this merge request to 0 seconds.

```
POST /projects/:id/merge_requests/:merge_request_iid/reset_spent_time
```

| Attribute           | Type    | Required | Description                                  |
| ---------           | ----    | -------- | -----------                                  |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                          |
| `merge_request_iid` | integer | yes      | The internal ID of a project's merge_request |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Get time tracking stats

```
GET /projects/:id/merge_requests/:merge_request_iid/time_stats
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request |

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats
```

Example response:

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

[ce-13060]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13060
[ce-14016]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14016
[ce-15454]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15454

## Approvals

For approvals, please see [Merge Request Approvals](merge_request_approvals.md)
