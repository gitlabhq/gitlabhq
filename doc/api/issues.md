---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Issues API **(FREE)**

Interact with [GitLab Issues](../user/project/issues/index.md) using the REST API.

If a user is not a member of a private project, a `GET`
request on that project results in a `404` status code.

## Issues pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

WARNING:
The `reference` attribute in responses is deprecated in favor of `references`.
Introduced in [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354).

NOTE:
The `references.relative` attribute is relative to the group or project of the issue being requested.
When an issue is fetched from its project, the `relative` format is the same as the `short` format.
When requested across groups or projects, it's expected to be the same as the `full` format.

## List issues

> The `weight` property moved to GitLab Premium in 13.9.

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

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`      | boolean          | no         | Filter confidential or public issues.                                                                                                               |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `due_date`          | string           | no         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. _(Introduced in [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/233420))_ |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                                       |
| `in`                | string           | no         | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`             |
| `issue_type`        | string           | no         | Filter to a given type of issue. One of `issue`, `incident`, or `test_case`. _(Introduced in [GitLab 13.12](https://gitlab.com/gitlab-org/gitlab/-/issues/260375))_ |
| `iteration_id` **(PREMIUM)** | integer | no         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `iteration_title` **(PREMIUM)** | string | no       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.                             |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14016) in GitLab 10.0)_ |
| `non_archived`      | boolean          | no         | Return issues only from non-archived projects. If `false`, the response returns issues from both archived and non-archived projects. Default is `true`. _(Introduced in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/197170))_ |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `assignee_id`, `assignee_username`, `author_id`, `author_username`, `iids`, `iteration_id`, `iteration_title`, `labels`, `milestone`, and `weight`. |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5. [Changed to snake_case](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18935) in GitLab 11.0)_ |
| `search`            | string           | no         | Search issues against their `title` and `description`                                                                                               |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                                                    |
| `state`             | string           | no         | Return `all` issues or just those that are `opened` or `closed`                                                                                       |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `weight` **(PREMIUM)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned.              |
| `with_labels_details` | boolean        | no         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. The `description_html` attribute was introduced in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413)|

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/issues"
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
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/1/issues/76",
         "notes":"http://gitlab.example.com/api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/1"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or higher include the `weight` property:

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

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042).
This value is only present for issues closed after GitLab 10.6 and if the user account
that closed the issue still exists.

## List group issues

> The `weight` property moved to GitLab Premium in 13.9.

Get a list of a group's issues.

If the group is private, credentials need to be provided for authorization.
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

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`     | boolean          | no         | Filter confidential or public issues.                                                                                         |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `due_date`          | string           | no         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. _(Introduced in [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/233420))_ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user                 |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                 |
| `issue_type`        | string           | no         | Filter to a given type of issue. One of `issue`, `incident`, or `test_case`. _(Introduced in [GitLab 13.12](https://gitlab.com/gitlab-org/gitlab/-/issues/260375))_ |
| `iteration_id` **(PREMIUM)** | integer | no         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `iteration_title` **(PREMIUM)** | string | no       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14016) in GitLab 10.0)_ |
| `non_archived`      | boolean          | no         | Return issues from non archived projects. Default is true. _(Introduced in [GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23785))_ |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in` |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`.<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5. [Changed to snake_case](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18935) in GitLab 11.0)_ |
| `search`            | string           | no         | Search group issues against their `title` and `description`                                                                   |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `weight` **(PREMIUM)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. |
| `with_labels_details` | boolean        | no         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. The `description_html` attribute was introduced in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4/issues"
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
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or higher include the `weight` property:

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

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042).
This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## List project issues

> The `weight` property moved to GitLab Premium in 13.9.

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

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE, the `assignee_username` array should only contain a single value. Otherwise, an invalid parameter error is returned. |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `confidential`     | boolean          | no         | Filter confidential or public issues.                                                                                         |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `due_date`          | string           | no         | Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month. Accepts: `0` (no due date), `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. _(Introduced in [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/233420))_ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user               |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                              |
| `issue_type`        | string           | no         | Filter to a given type of issue. One of `issue`, `incident`, or `test_case`. _(Introduced in [GitLab 13.12](https://gitlab.com/gitlab-org/gitlab/-/issues/260375))_ |
| `iteration_id` **(PREMIUM)** | integer | no         | Return issues assigned to the given iteration ID. `None` returns issues that do not belong to an iteration. `Any` returns issues that belong to an iteration. Mutually exclusive with `iteration_title`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `iteration_title` **(PREMIUM)** | string | no       | Return issues assigned to the iteration with the given title. Similar to `iteration_id` and mutually exclusive with `iteration_id`. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)_ |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14016) in GitLab 10.0)_ |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in` |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`.<br> For versions before 11.0, use the deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13004) in GitLab 9.5. [Changed to snake_case](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18935) in GitLab 11.0)_ |
| `search`            | string           | no         | Search project issues against their `title` and `description`                                                                 |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `weight` **(PREMIUM)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. |
| `with_labels_details` | boolean        | no         | If `true`, the response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. `description_html` was introduced in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues"
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
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Issues created by users on GitLab Premium or higher include the `weight` property:

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

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## Single issue

Only for administrators. Get a single issue.

The preferred way to do this is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /issues/:id
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer | yes      | The ID of the issue                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/issues/41"
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
    "project": "http://gitlab.example:3000/api/v4/projects/1"
  },
  "moved_to_id": null,
  "service_desk_reply_to": "service.desk@gitlab.com"
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated, and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042).
This value is only present for issues closed after GitLab 10.6 and if the user account
that closed the issue still exists.

## Single project issue

Get a single project issue.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues/41"
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
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## New issue

> The `weight` property moved to GitLab Premium in 13.9.

Creates a new project issue.

```plaintext
POST /projects/:id/issues
```

| Attribute                                 | Type           | Required | Description  |
|-------------------------------------------|----------------|----------|--------------|
| `assignee_id`                             | integer        | no       | The ID of the user to assign the issue to. Only appears on GitLab Free. |
| `assignee_ids` **(PREMIUM)**              | integer array  | no       | The IDs of the users to assign the issue to. |
| `confidential`                            | boolean        | no       | Set an issue to be confidential. Default is `false`.  |
| `created_at`                              | string         | no       | When the issue was created. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |
| `description`                             | string         | no       | The description of an issue. Limited to 1,048,576 characters. |
| `discussion_to_resolve`                   | string         | no       | The ID of a discussion to resolve. This fills out the issue with a default description and mark the discussion as resolved. Use in combination with `merge_request_to_resolve_discussions_of`. |
| `due_date`                                | string         | no       | The due date. Date time string in the format `YYYY-MM-DD`, for example `2016-03-11` |
| `epic_id` **(PREMIUM)** | integer | no | ID of the epic to add the issue to. Valid values are greater than or equal to 0. |
| `epic_iid` **(PREMIUM)** | integer | no | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)) |
| `id`                                      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `iid`                                     | integer/string | no       | The internal ID of the project's issue (requires administrator or project owner rights) |
| `issue_type`                              | string         | no       | The type of issue. One of `issue`, `incident`, or `test_case`. Default is `issue`. |
| `labels`                                  | string         | no       | Comma-separated label names for an issue  |
| `merge_request_to_resolve_discussions_of` | integer        | no       | The IID of a merge request in which to resolve all issues. This fills out the issue with a default description and mark all discussions as resolved. When passing a description or title, these values take precedence over the default values.|
| `milestone_id`                            | integer        | no       | The global ID of a milestone to assign issue. To find the `milestone_id` associated with a milestone, view an issue with the milestone assigned and [use the API](#single-project-issue) to retrieve the issue's details. |
| `title`                                   | string         | yes      | The title of an issue |
| `weight` **(PREMIUM)**                    | integer        | no       | The weight of the issue. Valid values are greater than or equal to 0. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug"
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
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## Rate limits

To help avoid abuse, users can be limited to a specific number of `Create` requests per minute.
See [Issues rate limits](../user/admin_area/settings/rate_limit_on_issues_creation.md).

## Edit issue

> The `weight` property moved to GitLab Premium in 13.9.

Updates an existing project issue. This call is also used to mark an issue as
closed.

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

| Attribute      | Type    | Required | Description                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `add_labels`   | string  | no       | Comma-separated label names to add to an issue.                                                            |
| `assignee_ids` | integer array | no | The ID of the user(s) to assign the issue to. Set to `0` or provide an empty value to unassign all assignees. |
| `confidential` | boolean | no       | Updates an issue to be confidential                                                                        |
| `description`  | string  | no       | The description of an issue. Limited to 1,048,576 characters.        |
| `discussion_locked` | boolean | no  | Flag indicating if the issue's discussion is locked. If the discussion is locked only project members can add or edit comments. |
| `due_date`     | string  | no       | The due date. Date time string in the format `YYYY-MM-DD`, for example `2016-03-11`                                           |
| `epic_id` **(PREMIUM)** | integer | no | ID of the epic to add the issue to. Valid values are greater than or equal to 0. |
| `epic_iid` **(PREMIUM)** | integer | no | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)) |
| `id`           | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid`    | integer | yes      | The internal ID of a project's issue                                                                       |
| `issue_type`   | string  | no       | Updates the type of issue. One of `issue`, `incident`, or `test_case`. |
| `labels`       | string  | no       | Comma-separated label names for an issue. Set to an empty string to unassign all labels.                   |
| `milestone_id` | integer | no       | The global ID of a milestone to assign the issue to. Set to `0` or provide an empty value to unassign a milestone.|
| `remove_labels`| string  | no       | Comma-separated label names to remove from an issue.                                                       |
| `state_event`  | string  | no       | The state event of an issue. Set `close` to close the issue and `reopen` to reopen it                      |
| `title`        | string  | no       | The title of an issue                                                                                      |
| `updated_at`   | string  | no       | When the issue was updated. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` (requires administrator or project owner rights). Empty string or null values are not accepted.|
| `weight` **(PREMIUM)** | integer | no | The weight of the issue. Valid values are greater than or equal to 0. 0                                                                    |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close"
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
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

WARNING:
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

WARNING:
`assignee` column is deprecated. We now show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Delete an issue

Only for administrators and project owners. Deletes an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues/85"
```

## Reorder an issue

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211864) in GitLab 13.2.

Reorders an issue, you can see the results when sorting issues manually

```plaintext
PUT /projects/:id/issues/:issue_iid/reorder
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of the project's issue |
| `move_after_id` | integer | no | The ID of a project's issue that should be placed after this issue |
| `move_before_id` | integer | no | The ID of a project's issue that should be placed before this issue |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues/85/reorder?move_after_id=51&move_before_id=92"
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

| Attribute       | Type    | Required | Description                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid`     | integer | yes      | The internal ID of a project's issue |
| `to_project_id` | integer | yes      | The ID of the new project            |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --form to_project_id=5 "https://gitlab.example.com/api/v4/projects/4/issues/85/move"
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
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## Subscribe to an issue

Subscribes the authenticated user to an issue to receive notifications.
If the user is already subscribed to the issue, the status code `304`
is returned.

```plaintext
POST /projects/:id/issues/:issue_iid/subscribe
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe"
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
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Issues created by users on GitLab Premium or higher include the `weight` property:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Issues created by users on GitLab Premium or higher include the `epic` property:

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
The `epic_iid` attribute is deprecated and [scheduled for removal in API version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/35157).
Please use `iid` of the `epic` attribute instead.

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## Unsubscribe from an issue

Unsubscribes the authenticated user from the issue to not receive notifications
from it. If the user is not subscribed to the issue, the
status code `304` is returned.

```plaintext
POST /projects/:id/issues/:issue_iid/unsubscribe
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe"
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

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/todo"
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

NOTE:
The `closed_by` attribute was [introduced in GitLab 10.6](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17042). This value is only present for issues closed after GitLab 10.6 and if the user account that closed
the issue still exists.

## Promote an issue to an epic **(PREMIUM)**

Promotes an issue to an epic by adding a comment with the `/promote`
[quick action](../user/project/quick_actions.md).

To learn more about promoting issues to epics, visit [Manage epics](../user/group/epics/manage_epics.md#promote-an-issue-to-an-epic).

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| :---------- | :------------- | :------- | :---------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid` | integer        | yes      | The internal ID of a project's issue |
| `body`      | String         | yes      | The content of a note. Must contain `/promote` at the start of a new line. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=Lets%20promote%20this%20to%20an%20epic%0A%0A%2Fpromote"
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

## Set a time estimate for an issue

Sets an estimated time of work for this issue.

```plaintext
POST /projects/:id/issues/:issue_iid/time_estimate
```

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | yes      | The duration in human format. e.g: 3h30m |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `issue_iid` | integer | yes      | The internal ID of a project's issue     |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m"
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

## Reset the time estimate for an issue

Resets the estimated time for this issue to 0 seconds.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate"
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

## Add spent time for an issue

Adds spent time for this issue

```plaintext
POST /projects/:id/issues/:issue_iid/add_spent_time
```

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | yes      | The duration in human format. e.g: 3h30m |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `issue_iid` | integer | yes      | The internal ID of a project's issue     |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h"
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

## Reset spent time for an issue

Resets the total spent time for this issue to 0 seconds.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time"
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

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/time_stats
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats"
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

## List merge requests related to issue

Get all the merge requests that are related to the issue.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/related_merge_requests
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests"
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

## List merge requests that close a particular issue on merge

Get all merge requests that close a particular issue when merged.

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/closed_by
```

| Attribute   | Type           | Required | Description                        |
| ----------- | ---------------| -------- | ---------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid` | integer        | yes      | The internal ID of a project issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by"
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
    "target_branch": "master",
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

## Participants on issues

If the project is private or the issue is confidential, you need to provide credentials to authorize.
The preferred way to do this, is by using [personal access tokens](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/participants
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/participants"
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

Comments are done via the [notes](notes.md) resource.

## Get user agent details

Available only for administrators.

```plaintext
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail"
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

To track which state was set, who did it, and when it happened, check out
[Resource state events API](resource_state_events.md#issues).

## Upload metric image

Available only for Incident issues.

```plaintext
POST /projects/:id/issues/:issue_iid/metric_images
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |
| `file` | file | yes      | The image file to be uploaded |
| `url` | string | no      | The URL to view more metric information |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --form 'file=@/path/to/file.png' \
--form 'url=http://example.com' "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

Example response:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com"
}
```

## List metric images

Available only for Incident issues.

```plaintext
GET /projects/:id/issues/:issue_iid/metric_images
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
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

## Delete metric image

Available only for Incident issues.

```plaintext
DELETE /projects/:id/issues/:issue_iid/metric_images/:image_id
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |
| `image_id` | integer | yes      | The ID of the image |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

Can return the following status codes:

- `204 No Content`, if the image was deleted successfully.
- `400 Bad Request`, if the image could not be deleted.
