---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Issues API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Interact with [GitLab Issues](../user/project/issues/_index.md) using the REST API.

If a user is not a member of a private project, a `GET`
request on that project results in a `404` status code.

## Issues pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.
Read more on [pagination](rest/_index.md#pagination).

NOTE:
The `references.relative` attribute is relative to the group or project of the issue being requested.
When an issue is fetched from its project, the `relative` format is the same as the `short` format.
When requested across groups or projects, it's expected to be the same as the `full` format.

## List issues

Get all issues the authenticated user has access to. By default it
returns only issues created by the current user. To get all issues,
use parameter `scope=all`.

```plaintext
GET /issues
GET /issues?assignee_id=5
GET /issues?author_id=5
GET /issues?confidential=true
GET /issues?iids[]=42&iids[]=43
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
GET /issues?milestone=1.0.0
GET /issues?milestone=1.0.0&state=opened
GET /issues?my_reaction_emoji=star
GET /issues?search=foo&in=title
GET /issues?state=closed
GET /issues?state=opened
```

Supported attributes:

| Attribute                       | Type          | Required   | Description                                                                                                                                         |
|---------------------------------|---------------| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assignee_id`                   | integer       | No         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username`             | string array  | No         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`                     | integer       | No         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`               | string        | No         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`                  | boolean       | No         | Filter confidential or public issues.                                                                                                               |
| `created_after`                 | datetime      | No         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime      | No         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `due_date`                      | string        | No         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`        | integer       | No         | Return issues associated with the given epic ID. `None` returns issues that are not associated with an epic. `Any` returns issues that are associated with an epic. Premium and Ultimate only. |
| `health_status`  | string        | No         | Return issues with the specified `health_status`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/370721) in GitLab 15.4)._ In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/370721), `None` returns issues with no health status assigned, and `Any` returns issues with a health status assigned. Ultimate only. |
| `iids[]`                        | integer array | No         | Return only the issues having the given `iid`.                                                                                                       |
| `in`                            | string        | No         | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`.             |
| `issue_type`                    | string        | No         | Filter to a given type of issue. One of `issue`, `incident`, `test_case` or `task`. |
| `iteration_id`                  | integer       | No         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. Premium and Ultimate only. |
| `iteration_title`               | string        | No       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. Premium and Ultimate only. |
| `labels`                        | string        | No         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone_id`                  | string        | No         | Returns issues assigned to milestones with a given timebox value (`None`, `Any`, `Upcoming`, and `Started`). `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone. `Upcoming` lists all issues assigned to milestones due in the future. `Started` lists all issues assigned to open, started milestones. `milestone` and `milestone_id` are mutually exclusive. |
| `milestone`                     | string        | No         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone. Using `None` or `Any` will be [deprecated in the future](https://gitlab.com/gitlab-org/gitlab/-/issues/336044). Use `milestone_id` attribute instead. `milestone` and `milestone_id` are mutually exclusive. |
| `my_reaction_emoji`             | string        | No         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `non_archived`                  | boolean       | No         | Return issues only from non-archived projects. If `false`, the response returns issues from both archived and non-archived projects. Default is `true`. |
| `not`                           | Hash          | No         | Return issues that do not match the parameters supplied. Accepts: `assignee_id`, `assignee_username`, `author_id`, `author_username`, `iids`, `iteration_id`, `iteration_title`, `labels`, `milestone`, `milestone_id` and `weight`. |
| `order_by`                      | string        | No         | Return issues ordered by `created_at`, `due_date`, `label_priority`, `milestone_due`, `popularity`, `priority`, `relative_position`, `title`, `updated_at`, or `weight` fields. Default is `created_at`. |
| `scope`                         | string        | No         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`. |
| `search`                        | string        | No         | Search issues against their `title` and `description`.                                                                                               |
| `sort`                          | string        | No         | Return issues sorted in `asc` or `desc` order. Default is `desc`.                                                                                    |
| `state`                         | string        | No         | Return `all` issues or just those that are `opened` or `closed`.                                                                                       |
| `updated_after`                 | datetime      | No         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime      | No         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `weight`                        | integer       | No         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. Premium and Ultimate only.   |
| `with_labels_details`           | boolean       | No         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues"
```

Example response:

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
      "assignees" : [{
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      }],
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "type" : "ISSUE",
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "closed_at" : null,
      "closed_by" : null,
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "moved_to_id" : null,
      "iid" : 6,
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported":false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/6",
      "references": {
        "short": "#6",
        "relative": "my-group/my-project#6",
        "full": "my-group/my-project#6"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/1/issues/76",
         "notes":"http://gitlab.example.com/api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/1",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "weight": null,
      ...
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `iteration` property:

```json
{
   "iteration": {
      "id":90,
      "iid":4,
      "sequence":2,
      "group_id":162,
      "title":null,
      "description":null,
      "state":2,
      "created_at":"2022-03-14T05:21:11.929Z",
      "updated_at":"2022-03-14T05:21:11.929Z",
      "start_date":"2022-03-08",
      "due_date":"2022-03-14",
      "web_url":"https://gitlab.com/groups/my-group/-/iterations/90"
   }
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform
to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## List group issues

Get a list of a group's issues.

If the group is private, you must provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /groups/:id/issues
GET /groups/:id/issues?assignee_id=5
GET /groups/:id/issues?author_id=5
GET /groups/:id/issues?confidential=true
GET /groups/:id/issues?iids[]=42&iids[]=43
GET /groups/:id/issues?labels=foo
GET /groups/:id/issues?labels=foo,bar
GET /groups/:id/issues?labels=foo,bar&state=opened
GET /groups/:id/issues?milestone=1.0.0
GET /groups/:id/issues?milestone=1.0.0&state=opened
GET /groups/:id/issues?my_reaction_emoji=star
GET /groups/:id/issues?search=issue+title+or+description
GET /groups/:id/issues?state=closed
GET /groups/:id/issues?state=opened
```

Supported attributes:

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | Yes        | The global ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).                 |
| `assignee_id`       | integer          | No         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username` | string array     | No         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`         | integer          | No         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`   | string           | No         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`     | boolean          | No         | Filter confidential or public issues.                                                                                         |
| `created_after`     | datetime         | No         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`    | datetime         | No         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `due_date`          | string           | No         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`           | integer      | No         | Return issues associated with the given epic ID. `None` returns issues that are not associated with an epic. `Any` returns issues that are associated with an epic. Premium and Ultimate only. |
| `iids[]`            | integer array    | No         | Return only the issues having the given `iid`.                                                                                 |
| `issue_type`        | string           | No         | Filter to a given type of issue. One of `issue`, `incident`, `test_case` or `task`. |
| `iteration_id`      | integer | No         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. Premium and Ultimate only. |
| `iteration_title`   | string | No       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. Premium and Ultimate only.|
| `labels`            | string           | No         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone`         | string           | No         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `my_reaction_emoji` | string           | No         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `non_archived`      | boolean          | No         | Return issues from non archived projects. Default is true. |
| `not`               | Hash             | No         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`          | string           | No         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `scope`             | string           | No         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `all`. |
| `search`            | string           | No         | Search group issues against their `title` and `description`.                                                                   |
| `sort`              | string           | No         | Return issues sorted in `asc` or `desc` order. Default is `desc`.                                                              |
| `state`             | string           | No         | Return all issues or just those that are `opened` or `closed`.                                                                 |
| `updated_after`     | datetime         | No         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`    | datetime         | No         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `weight` | integer       | No         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. Premium and Ultimate only. |
| `with_labels_details` | boolean        | No         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues"
```

Example response:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : null,
      "closed_by" : null,
      "user_notes_count": 1,
      "due_date": null,
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "my-project#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## List project issues

Get a list of a project's issues.

If the project is private, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues
GET /projects/:id/issues?assignee_id=5
GET /projects/:id/issues?author_id=5
GET /projects/:id/issues?confidential=true
GET /projects/:id/issues?iids[]=42&iids[]=43
GET /projects/:id/issues?labels=foo
GET /projects/:id/issues?labels=foo,bar
GET /projects/:id/issues?labels=foo,bar&state=opened
GET /projects/:id/issues?milestone=1.0.0
GET /projects/:id/issues?milestone=1.0.0&state=opened
GET /projects/:id/issues?my_reaction_emoji=star
GET /projects/:id/issues?search=issue+title+or+description
GET /projects/:id/issues?state=closed
GET /projects/:id/issues?state=opened
```

Supported attributes:

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | Yes        | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).               |
| `assignee_id`       | integer          | No         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username` | string array     | No         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`         | integer          | No         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`   | string           | No         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`     | boolean          | No         | Filter confidential or public issues.                                                                                         |
| `created_after`     | datetime         | No         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`    | datetime         | No         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `due_date`          | string           | No         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`           | integer      | No         | Return issues associated with the given epic ID. `None` returns issues that are not associated with an epic. `Any` returns issues that are associated with an epic. Premium and Ultimate only. |
| `iids[]`            | integer array    | No         | Return only the issues having the given `iid`.                                                                              |
| `issue_type`        | string           | No         | Filter to a given type of issue. One of `issue`, `incident`, `test_case` or `task`. |
| `iteration_id`      | integer | No         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. Premium and Ultimate only. |
| `iteration_title`   | string | No       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. Premium and Ultimate only. |
| `labels`            | string           | No         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone`         | string           | No         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `my_reaction_emoji` | string           | No         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `not`               | Hash             | No         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`          | string           | No         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`.                                                               |
| `scope`             | string           | No         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `all`. |
| `search`            | string           | No         | Search project issues against their `title` and `description`.                                                                 |
| `sort`              | string           | No         | Return issues sorted in `asc` or `desc` order. Default is `desc`.                                                              |
| `state`             | string           | No         | Return all issues or just those that are `opened` or `closed`.                                                                 |
| `updated_after`     | datetime         | No         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`    | datetime         | No         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `weight`            | integer       | No         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. Premium and Ultimate only. |
| `with_labels_details` | boolean        | No         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues"
```

Example response:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : "2016-01-05T15:31:46.176Z",
      "closed_by" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## Single issue

Only for administrators.

Get a single issue.

The preferred way to do this is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /issues/:id
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer | Yes      | The ID of the issue.                 |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues/41"
```

Example response:

```json
{
  "id": 1,
  "milestone": {
    "due_date": null,
    "project_id": 4,
    "state": "closed",
    "description": "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
    "iid": 3,
    "id": 11,
    "title": "v3.0",
    "created_at": "2016-01-04T15:31:39.788Z",
    "updated_at": "2016-01-04T15:31:39.788Z",
    "closed_at": "2016-01-05T15:31:46.176Z"
  },
  "author": {
    "state": "active",
    "web_url": "https://gitlab.example.com/root",
    "avatar_url": null,
    "username": "root",
    "id": 1,
    "name": "Administrator"
  },
  "description": "Omnis vero earum sunt corporis dolor et placeat.",
  "state": "closed",
  "iid": 1,
  "assignees": [
    {
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/lennie",
      "state": "active",
      "username": "lennie",
      "id": 9,
      "name": "Dr. Luella Kovacek"
    }
  ],
  "assignee": {
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/lennie",
    "state": "active",
    "username": "lennie",
    "id": 9,
    "name": "Dr. Luella Kovacek"
  },
  "type": "ISSUE",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "title": "Ut commodi ullam eos dolores perferendis nihil sunt.",
  "updated_at": "2016-01-04T15:31:46.176Z",
  "created_at": "2016-01-04T15:31:46.176Z",
  "closed_at": null,
  "closed_by": null,
  "subscribed": false,
  "user_notes_count": 1,
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://example.com/my-group/my-project/issues/1",
  "references": {
    "short": "#1",
    "relative": "#1",
    "full": "my-group/my-project#1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "weight": null,
  "has_tasks": false,
  "_links": {
    "self": "http://gitlab.example:3000/api/v4/projects/1/issues/1",
    "notes": "http://gitlab.example:3000/api/v4/projects/1/issues/1/notes",
    "award_emoji": "http://gitlab.example:3000/api/v4/projects/1/issues/1/award_emoji",
    "project": "http://gitlab.example:3000/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "moved_to_id": null,
  "service_desk_reply_to": "service.desk@gitlab.com"
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic": {
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Users of [GitLab Ultimate](https://about.gitlab.com/pricing/) can also see the `health_status`
property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform
to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated, and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## Single project issue

Get a single project issue.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/41"
```

Example response:

```json
{
   "project_id" : 4,
   "milestone" : {
      "due_date" : null,
      "project_id" : 4,
      "state" : "closed",
      "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
      "iid" : 3,
      "id" : 11,
      "title" : "v3.0",
      "created_at" : "2016-01-04T15:31:39.788Z",
      "updated_at" : "2016-01-04T15:31:39.788Z",
      "closed_at" : "2016-01-05T15:31:46.176Z"
   },
   "author" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
   },
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "state" : "closed",
   "iid" : 1,
   "assignees" : [{
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   }],
   "assignee" : {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   },
   "type" : "ISSUE",
   "labels" : [],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z",
   "closed_at" : null,
   "closed_by" : null,
   "subscribed": false,
   "user_notes_count": 1,
   "due_date": null,
   "imported": false,
   "imported_from": "none",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
   "references": {
     "short": "#1",
     "relative": "#1",
     "full": "my-group/my-project#1"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Users of [GitLab Ultimate](https://about.gitlab.com/pricing/) can also see the `health_status`
property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## New issue

Creates a new project issue.

```plaintext
POST /projects/:id/issues
```

Supported attributes:

| Attribute                                 | Type           | Required | Description  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `assignee_id`                             | integer        | No       | The ID of the user to assign the issue to. Only appears on GitLab Free. |
| `assignee_ids`                            | integer array  | No       | The IDs of the users to assign the issue to. Premium and Ultimate only.|
| `confidential`                            | boolean        | No       | Set an issue to be confidential. Default is `false`.  |
| `created_at`                              | string         | No       | When the issue was created. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |
| `description`                             | string         | No       | The description of an issue. Limited to 1,048,576 characters. |
| `discussion_to_resolve`                   | string         | No       | The ID of a discussion to resolve. This fills out the issue with a default description and mark the discussion as resolved. Use in combination with `merge_request_to_resolve_discussions_of`. |
| `due_date`                                | string         | No       | The due date. Date time string in the format `YYYY-MM-DD`, for example `2016-03-11`. |
| `epic_id`                                 | integer | No | ID of the epic to add the issue to. Valid values are greater than or equal to 0. Premium and Ultimate only. |
| `epic_iid`                                | integer | No | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5). Premium and Ultimate only. |
| `iid`                                     | integer/string | No       | The internal ID of the project's issue (requires administrator or project owner rights). |
| `issue_type`                              | string         | No       | The type of issue. One of `issue`, `incident`, `test_case` or `task`. Default is `issue`. |
| `labels`                                  | string         | No       | Comma-separated label names to assign to the new issue. If a label does not already exist, this creates a new project label and assigns it to the issue.  |
| `merge_request_to_resolve_discussions_of` | integer        | No       | The IID of a merge request in which to resolve all issues. This fills out the issue with a default description and mark all discussions as resolved. When passing a description or title, these values take precedence over the default values.|
| `milestone_id`                            | integer        | No       | The global ID of a milestone to assign issue. To find the `milestone_id` associated with a milestone, view an issue with the milestone assigned and [use the API](#single-project-issue) to retrieve the issue's details. |
| `title`                                   | string         | Yes      | The title of an issue. |
| `weight`                                  | integer        | No       | The weight of the issue. Valid values are greater than or equal to 0. Premium and Ultimate only. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug"
```

Example response:

```json
{
   "project_id" : 4,
   "id" : 84,
   "created_at" : "2016-01-07T12:44:33.959Z",
   "iid" : 14,
   "title" : "Issues with auth",
   "state" : "opened",
   "assignees" : [],
   "assignee" : null,
   "type" : "ISSUE",
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
   },
   "description" : null,
   "updated_at" : "2016-01-07T12:44:33.959Z",
   "closed_at" : null,
   "closed_by" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": null,
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/14",
   "references": {
     "short": "#14",
     "relative": "#14",
     "full": "my-group/my-project#14"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

### Rate limits

To help avoid abuse, users can be limited to a specific number of `Create` requests per minute.
See [Issues rate limits](../administration/settings/rate_limit_on_issues_creation.md).

## Edit an issue

Updates an existing project issue. This request is also used to close or reopen an issue (with `state_event`).

At least one of the following parameters is required for the request to be successful:

- `:assignee_id`
- `:assignee_ids`
- `:confidential`
- `:created_at`
- `:description`
- `:discussion_locked`
- `:due_date`
- `:issue_type`
- `:labels`
- `:milestone_id`
- `:state_event`
- `:title`

```plaintext
PUT /projects/:id/issues/:issue_iid
```

Supported attributes:

| Attribute      | Type    | Required | Description                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | integer/string | Yes | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`    | integer | Yes      | The internal ID of a project's issue.                                                                       |
| `add_labels`   | string  | No       | Comma-separated label names to add to an issue. If a label does not already exist, this creates a new project label and assigns it to the issue. |
| `assignee_ids` | integer array | No | The ID of the users to assign the issue to. Set to `0` or provide an empty value to unassign all assignees. |
| `confidential` | boolean | No       | Updates an issue to be confidential.                                                                        |
| `description`  | string  | No       | The description of an issue. Limited to 1,048,576 characters.        |
| `discussion_locked` | boolean | No  | Flag indicating if the issue's discussion is locked. If the discussion is locked only project members can add or edit comments. |
| `due_date`     | string  | No       | The due date. Date time string in the format `YYYY-MM-DD`, for example `2016-03-11`.                                           |
| `epic_id`      | integer | No | ID of the epic to add the issue to. Valid values are greater than or equal to 0. Premium and Ultimate only. |
| `epic_iid`     | integer | No | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5). Premium and Ultimate only. |
| `issue_type`   | string  | No       | Updates the type of issue. One of `issue`, `incident`, `test_case` or `task`. |
| `labels`       | string  | No       | Comma-separated label names for an issue. Set to an empty string to unassign all labels. If a label does not already exist, this creates a new project label and assigns it to the issue. |
| `milestone_id` | integer | No       | The global ID of a milestone to assign the issue to. Set to `0` or provide an empty value to unassign a milestone.|
| `remove_labels`| string  | No       | Comma-separated label names to remove from an issue.                                                       |
| `state_event`  | string  | No       | The state event of an issue. To close the issue, use `close`, and to reopen it, use `reopen`.                      |
| `title`        | string  | No       | The title of an issue.                                                                                      |
| `updated_at`   | string  | No       | When the issue was updated. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` (requires administrator or project owner rights). Empty string or null values are not accepted.|
| `weight`       | integer | No       | The weight of the issue. Valid values are greater than or equal to 0. Premium and Ultimate only.           |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close"
```

Example response:

```json
{
   "created_at" : "2016-01-07T12:46:01.410Z",
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "username" : "eileen.lowe",
      "id" : 18,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe"
   },
   "state" : "closed",
   "title" : "Issues with auth",
   "project_id" : 4,
   "description" : null,
   "updated_at" : "2016-01-07T12:55:16.213Z",
   "closed_at" : "2016-01-08T12:55:16.213Z",
   "closed_by" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
    },
   "iid" : 15,
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 85,
   "assignees" : [],
   "assignee" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": "2016-07-22",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/15",
   "references": {
     "short": "#15",
     "relative": "#15",
     "full": "my-group/my-project#15"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"

   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

WARNING:
`assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Delete an issue

Only for administrators and project owners.

Deletes an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85"
```

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

## Reorder an issue

Reorders an issue. You can see the results when [sorting issues manually](../user/project/issues/sorting_issue_lists.md#manual-sorting).

```plaintext
PUT /projects/:id/issues/:issue_iid/reorder
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of the project's issue. |
| `move_after_id` | integer | No | The global ID of a project's issue that should be placed after this issue. |
| `move_before_id` | integer | No | The global ID of a project's issue that should be placed before this issue. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/reorder?move_after_id=51&move_before_id=92"
```

## Move an issue

Moves an issue to a different project. If the target project
is the source project or the user has insufficient permissions,
an error message with status code `400` is returned.

If a given label or milestone with the same name also exists in the target
project, it's then assigned to the issue being moved.

```plaintext
POST /projects/:id/issues/:issue_iid/move
```

Supported attributes:

| Attribute       | Type    | Required | Description                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid`     | integer | Yes      | The internal ID of a project's issue. |
| `to_project_id` | integer | Yes      | The ID of the new project.            |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form to_project_id=5 \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/move"
```

Example response:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

## Clone an issue

Clone the issue to given project.
Copies as much data as possible as long as the target project contains equivalent
criteria, such as labels or milestones.

If you have insufficient permissions, an error message with status code `400` is returned.

```plaintext
POST /projects/:id/issues/:issue_iid/clone
```

Supported attributes:

| Attribute       | Type           | Required               | Description                       |
| --------------- | -------------- | ---------------------- | --------------------------------- |
| `id`            | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | Yes | Internal ID of a project's issue. |
| `to_project_id` | integer        | Yes | ID of the new project.            |
| `with_notes`    | boolean        | No | Clone the issue with [notes](notes.md). Default is `false`. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/1/clone?with_notes=true&to_project_id=6"
```

Example response:

```json
{
  "id":290,
  "iid":1,
  "project_id":143,
  "title":"foo",
  "description":"closed",
  "state":"opened",
  "created_at":"2021-09-14T22:24:11.696Z",
  "updated_at":"2021-09-14T22:24:11.696Z",
  "closed_at":null,
  "closed_by":null,
  "labels":[

  ],
  "milestone":null,
  "assignees":[
    {
      "id":179,
      "name":"John Doe2",
      "username":"john",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/john"
    }
  ],
  "author":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "type":"ISSUE",
  "assignee":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "user_notes_count":1,
  "merge_requests_count":0,
  "upvotes":0,
  "downvotes":0,
  "due_date":null,
  "imported":false,
  "imported_from": "none",
  "confidential":false,
  "discussion_locked":null,
  "issue_type":"issue",
  "severity": "UNKNOWN",
  "web_url":"https://gitlab.example.com/namespace1/project2/-/issues/1",
  "time_stats":{
    "time_estimate":0,
    "total_time_spent":0,
    "human_time_estimate":null,
    "human_total_time_spent":null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "blocking_issues_count":0,
  "has_tasks":false,
  "_links":{
    "self":"https://gitlab.example.com/api/v4/projects/143/issues/1",
    "notes":"https://gitlab.example.com/api/v4/projects/143/issues/1/notes",
    "award_emoji":"https://gitlab.example.com/api/v4/projects/143/issues/1/award_emoji",
    "project":"https://gitlab.example.com/api/v4/projects/143",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "references":{
    "short":"#1",
    "relative":"#1",
    "full":"namespace1/project2#1"
  },
  "subscribed":true,
  "moved_to_id":null,
  "service_desk_reply_to":null
}
```

## Notifications

The following requests are related to [email notifications](../user/profile/notifications.md) for issues.

### Subscribe to an issue

Subscribes the authenticated user to an issue to receive notifications.
If the user is already subscribed to the issue, the status code `304`
is returned.

```plaintext
POST /projects/:id/issues/:issue_iid/subscribe
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe"
```

Example response:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Issues created by users on GitLab Premium or Ultimate include the `weight` property:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Issues created by users on GitLab Premium or Ultimate include the `epic` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Issues created by users on GitLab Ultimate include the `health_status` property:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) in API version 5.
Use `iid` of the `epic` attribute instead.

### Unsubscribe from an issue

Unsubscribes the authenticated user from the issue to not receive notifications
from it. If the user is not subscribed to the issue, the
status code `304` is returned.

```plaintext
POST /projects/:id/issues/:issue_iid/unsubscribe
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe"
```

Example response:

```json
{
  "id": 93,
  "iid": 12,
  "project_id": 5,
  "title": "Incidunt et rerum ea expedita iure quibusdam.",
  "description": "Et cumque architecto sed aut ipsam.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.217Z",
  "updated_at": "2016-04-07T13:02:37.905Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignee": {
    "name": "Edwardo Grady",
    "username": "keyon",
    "id": 21,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/3e6f06a86cf27fa8b56f3f74f7615987?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/keyon"
  },
  "type" : "ISSUE",
  "closed_at": null,
  "closed_by": null,
  "author": {
    "name": "Vivian Hermann",
    "username": "orville",
    "id": 11,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/orville"
  },
  "subscribed": false,
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/12",
  "references": {
    "short": "#12",
    "relative": "#12",
    "full": "my-group/my-project#12"
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

## Create a to-do item

Manually creates a to-do item for the current user on an issue. If
there already exists a to-do item for the user on that issue, status code `304` is
returned.

```plaintext
POST /projects/:id/issues/:issue_iid/todo
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/todo"
```

Example response:

```json
{
  "id": 112,
  "project": {
    "id": 5,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
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
  "target_type": "Issue",
  "target": {
    "id": 93,
    "iid": 10,
    "project_id": 5,
    "title": "Vel voluptas atque dicta mollitia adipisci qui at.",
    "description": "Tempora laboriosam sint magni sed voluptas similique.",
    "state": "closed",
    "created_at": "2016-06-17T07:47:39.486Z",
    "updated_at": "2016-07-01T11:09:13.998Z",
    "labels": [],
    "milestone": {
      "id": 26,
      "iid": 1,
      "project_id": 5,
      "title": "v0.0",
      "description": "Accusantium nostrum rerum quae quia quis nesciunt suscipit id.",
      "state": "closed",
      "created_at": "2016-06-17T07:47:33.832Z",
      "updated_at": "2016-06-17T07:47:33.832Z",
      "due_date": null
    },
    "assignees": [{
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    }],
    "assignee": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    },
    "type" : "ISSUE",
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "subscribed": true,
    "user_notes_count": 7,
    "upvotes": 0,
    "downvotes": 0,
    "merge_requests_count": 0,
    "due_date": null,
    "web_url": "http://gitlab.example.com/my-group/my-project/issues/10",
    "references": {
      "short": "#10",
      "relative": "#10",
      "full": "my-group/my-project#10"
    },
    "confidential": false,
    "discussion_locked": false,
    "issue_type": "issue",
    "severity": "UNKNOWN",
    "task_completion_status":{
       "count":0,
       "completed_count":0
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/issues/10",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

WARNING:
The `assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Promote an issue to an epic

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Promotes an issue to an epic by adding a comment with the `/promote`
[quick action](../user/project/quick_actions.md).

For more information about promoting issues to epics, see
[Promote an issue to an epic](../user/project/issues/managing_issues.md#promote-an-issue-to-an-epic).

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| :---------- | :------------- | :------- | :---------- |
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | Yes      | The internal ID of a project's issue. |
| `body`      | String         | Yes      | The content of a note. Must contain `/promote` at the start of a new line. If the note only contains `/promote`, promotes the issue, but doesn't add a comment. Otherwise, the other lines form a comment.|

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=Lets%20promote%20this%20to%20an%20epic%0A%0A%2Fpromote"
```

Example response:

```json
{
   "id":699,
   "type":null,
   "body":"Lets promote this to an epic",
   "attachment":null,
   "author": {
      "id":1,
      "name":"Alexandra Bashirian",
      "username":"eileen.lowe",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url":"https://gitlab.example.com/eileen.lowe"
   },
   "created_at":"2020-12-03T12:27:17.844Z",
   "updated_at":"2020-12-03T12:27:17.844Z",
   "system":false,
   "noteable_id":461,
   "noteable_type":"Issue",
   "resolvable":false,
   "confidential":false,
   "noteable_iid":33,
   "commands_changes": {
      "promote_to_epic":true
   }
}
```

## Time tracking

The following requests are related to [time tracking](../user/project/time_tracking.md) on issues.

### Set a time estimate for an issue

Sets an estimated time of work for this issue.

```plaintext
POST /projects/:id/issues/:issue_iid/time_estimate
```

Supported attributes:

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | Yes      | The duration in human-readable format. For example: `3h30m`. |
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).      |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue.     |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m"
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

### Reset the time estimate for an issue

Resets the estimated time for this issue to 0 seconds.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate"
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

### Add spent time for an issue

Adds spent time for this issue.

```plaintext
POST /projects/:id/issues/:issue_iid/add_spent_time
```

Supported attributes:

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | Yes      | The duration in human-readable format. For example: `3h30m` |
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue.    |
| `summary`   | string  | No       | A summary of how the time was spent.  |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h"
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

### Reset spent time for an issue

Resets the total spent time for this issue to 0 seconds.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time"
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

### Get time tracking stats

Gets time tracking stats for an issue in human-readable format (for example, `1h30m`) and in number of seconds.

If the project is private or the issue is confidential, you must provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/time_stats
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats"
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

## Merge requests

The following requests are related to relationships between issues and merge requests.

### List merge requests related to issue

Gets all the merge requests that are related to the issue.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/related_merge_requests
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests"
```

Example response:

```json
[
  {
    "id": 29,
    "iid": 11,
    "project_id": 1,
    "title": "Provident eius eos blanditiis consequatur neque odit.",
    "description": "Ut consequatur ipsa aspernatur quisquam voluptatum fugit. Qui harum corporis quo fuga ut incidunt veritatis. Autem necessitatibus et harum occaecati nihil ea.\r\n\r\ntwitter/flight#8",
    "state": "opened",
    "created_at": "2018-09-18T14:36:15.510Z",
    "updated_at": "2018-09-19T07:45:13.089Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "v2.x",
    "source_branch": "so_long_jquery",
    "user_notes_count": 9,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 14,
      "name": "Verna Hills",
      "username": "lawanda_reinger",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/de68a91aeab1cff563795fb98a0c2cc0?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/lawanda_reinger"
    },
    "assignee": {
      "id": 19,
      "name": "Jody Baumbach",
      "username": "felipa.kuvalis",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/felipa.kuvalis"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 1,
      "title": "v1.0",
      "description": "Et tenetur voluptatem minima doloribus vero dignissimos vitae.",
      "state": "active",
      "created_at": "2018-09-18T14:35:44.353Z",
      "updated_at": "2018-09-18T14:35:44.353Z",
      "due_date": null,
      "start_date": null,
      "web_url": "https://gitlab.example.com/twitter/flight/milestones/2"
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "cannot_be_merged",
    "sha": "3b7b528e9353295c1c125dad281ac5b5deae5f12",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "reference": "!11",
    "web_url": "https://gitlab.example.com/twitter/flight/merge_requests/4",
    "references": {
      "short": "!4",
      "relative": "!4",
      "full": "twitter/flight!4"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "changes_count": "10",
    "latest_build_started_at": "2018-12-05T01:16:41.723Z",
    "latest_build_finished_at": "2018-12-05T02:35:54.046Z",
    "first_deployed_to_production_at": null,
    "pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.com/gitlab-org/gitlab/pipelines/38980952"
    },
    "head_pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.example.com/twitter/flight/pipelines/38980952",
      "before_sha": "3c738a37eb23cf4c0ed0d45d6ddde8aad4a8da51",
      "tag": false,
      "yaml_errors": null,
      "user": {
        "id": 19,
        "name": "Jody Baumbach",
        "username": "felipa.kuvalis",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/felipa.kuvalis"
      },
      "created_at": "2018-12-05T01:16:13.342Z",
      "updated_at": "2018-12-05T02:35:54.086Z",
      "started_at": "2018-12-05T01:16:41.723Z",
      "finished_at": "2018-12-05T02:35:54.046Z",
      "committed_at": null,
      "duration": 4436,
      "coverage": "46.68",
      "detailed_status": {
        "icon": "status_warning",
        "text": "passed",
        "label": "passed with warnings",
        "group": "success-with-warnings",
        "tooltip": "passed",
        "has_details": true,
        "details_path": "/twitter/flight/pipelines/38",
        "illustration": null,
        "favicon": "https://gitlab.example.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
      }
    },
    "diff_refs": {
      "base_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb",
      "head_sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "start_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb"
    },
    "merge_error": null,
    "user": {
      "can_merge": true
    }
  }
]
```

### List merge requests that close a particular issue on merge

Gets all merge requests that close a particular issue when merged.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/closed_by
```

Supported attributes:

| Attribute   | Type           | Required | Description                        |
| ----------- | ---------------| -------- | ---------------------------------- |
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | Yes      | The internal ID of a project issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by"
```

Example response:

```json
[
  {
    "id": 6471,
    "iid": 6432,
    "project_id": 1,
    "title": "add a test for cgi lexer options",
    "description": "closes #11",
    "state": "opened",
    "created_at": "2017-04-06T18:33:34.168Z",
    "updated_at": "2017-04-09T20:10:24.983Z",
    "target_branch": "main",
    "source_branch": "feature.custom-highlighting",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "assignee": null,
    "source_project_id": 1,
    "target_project_id": 1,
    "closed_at": null,
    "closed_by": null,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "sha": "5a62481d563af92b8e32d735f2fa63b94e806835",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/6432",
    "reference": "!6432",
    "references": {
      "short": "!6432",
      "relative": "!6432",
      "full": "gitlab-org/gitlab-test!6432"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## List participants in an issue

Lists users that are participants in the issue.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/participants
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/participants"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user1"
  },
  {
    "id": 5,
    "name": "John Doe5",
    "username": "user5",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user5"
  }
]
```

## Comments on issues

Interact with comments using the [Notes API](notes.md).

## Get user agent details

Available only for administrators.

Gets the user agent string and IP of the user who created the issue.
Used for spam tracking.

```plaintext
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail"
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

## List issue state events

To track which state was set, who did it, and when it happened, use
[Resource state events API](resource_state_events.md#issues).

## Incidents

The following requests are available only for [incidents](../operations/incident_management/incidents.md).

### Upload metric image

Available only for [incidents](../operations/incident_management/incidents.md).

Uploads a screenshot of metric charts to show in the incident's **Metrics** tab.
When you upload an image, you can associate the image with text or a link to the original graph.
If you add a URL, you can access the original graph by selecting the hyperlink above the uploaded image.

```plaintext
POST /projects/:id/issues/:issue_iid/metric_images
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |
| `file` | file | Yes      | The image file to be uploaded. |
| `url` | string | No      | The URL to view more metric information. |
| `url_text` | string | No      | A description of the image or URL. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

Example response:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### List metric images

Available only for [incidents](../operations/incident_management/incidents.md).

Lists screenshots of metric charts shown in the incident's **Metrics** tab.

```plaintext
GET /projects/:id/issues/:issue_iid/metric_images
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

Example response:

```json
[
    {
        "id": 17,
        "created_at": "2020-11-12T20:07:58.156Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/17/sample_2054.png",
        "url": "example.com/metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/18/sample_2054.png",
        "url": "example.com/metric"
    }
]
```

### Update metric image

Available only for [incidents](../operations/incident_management/incidents.md).

Edits attributes of a screenshot of metric charts shown in the incident's **Metrics** tab.

```plaintext
PUT /projects/:id/issues/:issue_iid/metric_images/:image_id
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |
| `image_id` | integer | Yes      | The ID of the image. |
| `url` | string | No      | The URL to view more metric information. |
| `url_text` | string | No      | A description of the image or URL. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

Example response:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### Delete metric image

Available only for [incidents](../operations/incident_management/incidents.md).

Delete a screenshot of metric charts shown in the incident's **Metrics** tab.

```plaintext
DELETE /projects/:id/issues/:issue_iid/metric_images/:image_id
```

Supported attributes:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | Yes      | The global ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Yes      | The internal ID of a project's issue. |
| `image_id` | integer | Yes      | The ID of the image. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

Can return the following status codes:

- `204 No Content`, if the image was deleted successfully.
- `400 Bad Request`, if the image could not be deleted.
