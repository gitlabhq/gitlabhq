# Issues API

Every API call to issues must be authenticated.

If a user is not a member of a project and the project is private, a `GET`
request on that project will result in a `404` status code.

## Issues pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

CAUTION: **Deprecation**
> `reference` attribute in response is deprecated in favour of `references`.
> Introduced [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)

NOTE: **Note**
> `references.relative` is relative to the group / project that the issue is being requested. When issue is fetched from its project
> `relative` format would be the same as `short` format and when requested across groups / projects it is expected to be the same as `full` format.

## List issues

Get all issues the authenticated user has access to. By default it
returns only issues created by the current user. To get all issues,
use parameter `scope=all`.

```
GET /issues
GET /issues?state=opened
GET /issues?state=closed
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
GET /issues?milestone=1.0.0
GET /issues?milestone=1.0.0&state=opened
GET /issues?iids[]=42&iids[]=43
GET /issues?author_id=5
GET /issues?assignee_id=5
GET /issues?my_reaction_emoji=star
GET /issues?search=foo&in=title
GET /issues?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `state`             | string           | no         | Return `all` issues or just those that are `opened` or `closed`                                                                                       |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `with_labels_details` | Boolean        | no         | If `true`, response will return more details for each label in labels field: `:name`, `:color`, `:description`, `:text_color`. Default is `false`. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.                             |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced][ce-13004] in GitLab 9.5. [Changed to snake_case][ce-18935] in GitLab 11.0)_ |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In CE version `assignee_username` array should only contain a single value or an invalid param error will be returned otherwise. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced][ce-14016] in GitLab 10.0)_ |
| `weight` **(STARTER)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned.              |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                                       |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                                                    |
| `search`            | string           | no         | Search issues against their `title` and `description`                                                                                               |
| `in`                | string           | no         | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`             |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                                                    |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                                                   |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                                                    |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                                                   |
| `confidential`      | Boolean          | no         | Filter confidential or public issues.                                                                                                               |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in` |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/issues
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
      "web_url": "http://example.com/my-group/my-project/issues/6",
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
      "_links":{
         "self":"http://example.com/api/v4/projects/1/issues/76",
         "notes":"`http://example.com/`api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://example.com/api/v4/projects/1"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## List group issues

Get a list of a group's issues.

```
GET /groups/:id/issues
GET /groups/:id/issues?state=opened
GET /groups/:id/issues?state=closed
GET /groups/:id/issues?labels=foo
GET /groups/:id/issues?labels=foo,bar
GET /groups/:id/issues?labels=foo,bar&state=opened
GET /groups/:id/issues?milestone=1.0.0
GET /groups/:id/issues?milestone=1.0.0&state=opened
GET /groups/:id/issues?iids[]=42&iids[]=43
GET /groups/:id/issues?search=issue+title+or+description
GET /groups/:id/issues?author_id=5
GET /groups/:id/issues?assignee_id=5
GET /groups/:id/issues?my_reaction_emoji=star
GET /groups/:id/issues?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                 |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `with_labels_details` | Boolean        | no         | If `true`, response will return more details for each label in labels field: `:name`, `:color`, `:description`, `:text_color`. Default is `false`. |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                 |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`.<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced][ce-13004] in GitLab 9.5. [Changed to snake_case][ce-18935] in GitLab 11.0)_ |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In CE version `assignee_username` array should only contain a single value or an invalid param error will be returned otherwise. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced][ce-14016] in GitLab 10.0)_ |
| `weight` **(STARTER)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `search`            | string           | no         | Search group issues against their `title` and `description`                                                                   |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                              |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                             |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                              |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                             |
| `confidential`     | Boolean          | no         | Filter confidential or public issues.                                                                                         |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in` |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/4/issues
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
      "web_url": "http://example.com/my-group/my-project/issues/1",
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
      "_links":{
         "self":"http://example.com/api/v4/projects/4/issues/41",
         "notes":"`http://example.com/`api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://example.com/api/v4/projects/4"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## List project issues

Get a list of a project's issues.

```
GET /projects/:id/issues
GET /projects/:id/issues?state=opened
GET /projects/:id/issues?state=closed
GET /projects/:id/issues?labels=foo
GET /projects/:id/issues?labels=foo,bar
GET /projects/:id/issues?labels=foo,bar&state=opened
GET /projects/:id/issues?milestone=1.0.0
GET /projects/:id/issues?milestone=1.0.0&state=opened
GET /projects/:id/issues?iids[]=42&iids[]=43
GET /projects/:id/issues?search=issue+title+or+description
GET /projects/:id/issues?author_id=5
GET /projects/:id/issues?assignee_id=5
GET /projects/:id/issues?my_reaction_emoji=star
GET /projects/:id/issues?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user               |
| `iids[]`            | integer array    | no         | Return only the milestone having the given `iid`                                                                              |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. `No+Label` (Deprecated) lists all issues with no labels. Predefined names are case-insensitive. |
| `with_labels_details` | Boolean        | no         | If `true`, response will return more details for each label in labels field: `:name`, `:color`, `:description`, `:text_color`. Default is `false`. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`.<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead.<br> _([Introduced][ce-13004] in GitLab 9.5. [Changed to snake_case][ce-18935] in GitLab 11.0)_ |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. _([Introduced][ce-13004] in GitLab 9.5)_ |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In CE version `assignee_username` array should only contain a single value or an invalid param error will be returned otherwise. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced][ce-14016] in GitLab 10.0)_ |
| `weight` **(STARTER)** | integer       | no         | Return issues with the specified `weight`. `None` returns issues with no weight assigned. `Any` returns issues with a weight assigned. |
| `order_by`          | string           | no         | Return issues ordered by `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` fields. Default is `created_at`                                                               |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `search`            | string           | no         | Search project issues against their `title` and `description`                                                                 |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                              |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                             |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                              |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                             |
| `confidential`     | Boolean          | no         | Filter confidential or public issues.                                                                                         |
| `not`               | Hash             | no         | Return issues that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in` |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/issues
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
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "_links":{
         "self":"http://example.com/api/v4/projects/4/issues/41",
         "notes":"`http://example.com/`api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://example.com/api/v4/projects/4"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Single issue

Get a single project issue.

```
GET /projects/:id/issues/:issue_iid
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/issues/41
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
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Users on GitLab [Ultimate](https://about.gitlab.com/pricing/) will additionally see
the `epic` property:

```javascript
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
   // ...
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

**Note**: The `epic_iid` attribute is deprecated and [will be removed in 13.0](https://gitlab.com/gitlab-org/gitlab/issues/35157).
Please use `iid` of the `epic` attribute instead.

## New issue

Creates a new project issue.

```
POST /projects/:id/issues
```

| Attribute                                 | Type           | Required | Description  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `iid`                                     | integer/string | no       | The internal ID of the project's issue (requires admin or project owner rights) |
| `title`                                   | string         | yes      | The title of an issue |
| `description`                             | string         | no       | The description of an issue. Limited to 1,048,576 characters. |
| `confidential`                            | boolean        | no       | Set an issue to be confidential. Default is `false`.  |
| `assignee_ids`                            | integer array  | no       | The ID of a user to assign issue |
| `milestone_id`                            | integer        | no       | The global ID of a milestone to assign issue  |
| `labels`                                  | string         | no       | Comma-separated label names for an issue  |
| `created_at`                              | string         | no       | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` (requires admin or project/group owner rights) |
| `due_date`                                | string         | no       | Date time string in the format YEAR-MONTH-DAY, e.g. `2016-03-11` |
| `merge_request_to_resolve_discussions_of` | integer        | no       | The IID of a merge request in which to resolve all issues. This will fill the issue with a default description and mark all discussions as resolved. When passing a description or title, these values will take precedence over the default values.|
| `discussion_to_resolve`                   | string         | no       | The ID of a discussion to resolve. This will fill in the issue with a default description and mark the discussion as resolved. Use in combination with `merge_request_to_resolve_discussions_of`. |
| `weight` **(STARTER)**                    | integer        | no       | The weight of the issue. Valid values are greater than or equal to 0. |
| `epic_id` **(ULTIMATE)** | integer | no | ID of the epic to add the issue to. Valid values are greater than or equal to 0. |
| `epic_iid` **(ULTIMATE)** | integer | no | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [will be removed in 13.0](https://gitlab.com/gitlab-org/gitlab/issues/35157)) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug
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
   "web_url": "http://example.com/my-group/my-project/issues/14",
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
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Edit issue

Updates an existing project issue. This call is also used to mark an issue as
closed.

```
PUT /projects/:id/issues/:issue_iid
```

| Attribute      | Type    | Required | Description                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid`    | integer | yes      | The internal ID of a project's issue                                                                       |
| `title`        | string  | no       | The title of an issue                                                                                      |
| `description`  | string  | no       | The description of an issue. Limited to 1,048,576 characters.        |
| `confidential` | boolean | no       | Updates an issue to be confidential                                                                        |
| `assignee_ids` | integer array | no | The ID of the user(s) to assign the issue to. Set to `0` or provide an empty value to unassign all assignees. |
| `milestone_id` | integer | no       | The global ID of a milestone to assign the issue to. Set to `0` or provide an empty value to unassign a milestone.|
| `labels`       | string  | no       | Comma-separated label names for an issue. Set to an empty string to unassign all labels.                   |
| `state_event`  | string  | no       | The state event of an issue. Set `close` to close the issue and `reopen` to reopen it                      |
| `updated_at`   | string  | no       | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` (requires admin or project owner rights) |
| `due_date`     | string  | no       | Date time string in the format YEAR-MONTH-DAY, e.g. `2016-03-11`                                           |
| `weight` **(STARTER)** | integer | no | The weight of the issue. Valid values are greater than or equal to 0. 0                                                                    |
| `discussion_locked` | boolean | no  | Flag indicating if the issue's discussion is locked. If the discussion is locked only project members can add or edit comments. |
| `epic_id` **(ULTIMATE)** | integer | no | ID of the epic to add the issue to. Valid values are greater than or equal to 0. |
| `epic_iid` **(ULTIMATE)** | integer | no | IID of the epic to add the issue to. Valid values are greater than or equal to 0. (deprecated, [will be removed in 13.0](https://gitlab.com/gitlab-org/gitlab/issues/35157)) |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close
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
   "web_url": "http://example.com/my-group/my-project/issues/15",
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
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Delete an issue

Only for admins and project owners. Deletes the issue in question.

```
DELETE /projects/:id/issues/:issue_iid
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/issues/85
```

## Move an issue

Moves an issue to a different project. If the target project
equals the source project or the user has insufficient permissions to move an
issue, error `400` together with an explaining error message is returned.

If a given label and/or milestone with the same name also exists in the target
project, it will then be assigned to the issue that is being moved.

```
POST /projects/:id/issues/:issue_iid/move
```

| Attribute       | Type    | Required | Description                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid`     | integer | yes      | The internal ID of a project's issue |
| `to_project_id` | integer | yes      | The ID of the new project            |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" --form to_project_id=5 https://gitlab.example.com/api/v4/projects/4/issues/85/move
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
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://example.com/my-group/my-project/issues/11",
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
  "_links": {
    "self": "http://example.com/api/v4/projects/1/issues/2",
    "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://example.com/api/v4/projects/1"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Subscribe to an issue

Subscribes the authenticated user to an issue to receive notifications.
If the user is already subscribed to the issue, the status code `304`
is returned.

```
POST /projects/:id/issues/:issue_iid/subscribe
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe
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
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://example.com/my-group/my-project/issues/11",
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
  "_links": {
    "self": "http://example.com/api/v4/projects/1/issues/2",
    "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://example.com/api/v4/projects/1"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `weight` parameter:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Unsubscribe from an issue

Unsubscribes the authenticated user from the issue to not receive notifications
from it. If the user is not subscribed to the issue, the
status code `304` is returned.

```
POST /projects/:id/issues/:issue_iid/unsubscribe
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe
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
  "web_url": "http://example.com/my-group/my-project/issues/12",
  "references": {
    "short": "#12",
    "relative": "#12",
    "full": "my-group/my-project#12"
  },
  "confidential": false,
  "discussion_locked": false,
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

## Create a todo

Manually creates a todo for the current user on an issue. If
there already exists a todo for the user on that issue, status code `304` is
returned.

```
POST /projects/:id/issues/:issue_iid/todo
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/todo
```

Example response:

```json
{
  "id": 112,
  "project": {
    "id": 5,
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
    "web_url": "http://example.com/my-group/my-project/issues/10",
    "references": {
      "short": "#10",
      "relative": "#10",
      "full": "my-group/my-project#10"
    },
    "confidential": false,
    "discussion_locked": false,
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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

**Note**: The `closed_by` attribute was [introduced in GitLab 10.6][ce-17042]. This value will only be present for issues which were closed after GitLab 10.6 and when the user account that closed the issue still exists.

## Set a time estimate for an issue

Sets an estimated time of work for this issue.

```
POST /projects/:id/issues/:issue_iid/time_estimate
```

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `issue_iid` | integer | yes      | The internal ID of a project's issue     |
| `duration`  | string  | yes      | The duration in human format. e.g: 3h30m |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m
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

```
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate
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

```
POST /projects/:id/issues/:issue_iid/add_spent_time
```

| Attribute   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `issue_iid` | integer | yes      | The internal ID of a project's issue     |
| `duration`  | string  | yes      | The duration in human format. e.g: 3h30m |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h
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

```
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time
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
GET /projects/:id/issues/:issue_iid/time_stats
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats
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

```
GET /projects/:id/issues/:issue_id/related_merge_requests
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```sh
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests
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

## List merge requests that will close issue on merge

Get all the merge requests that will close issue when merged.

```
GET /projects/:id/issues/:issue_iid/closed_by
```

| Attribute   | Type    | Required | Description                          |
| ---------   | ----    | -------- | -----------                          |
| `id`        | integer | yes      | The ID of a project                  |
| `issue_iid` | integer | yes      | The internal ID of a project issue   |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by
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

```
GET /projects/:id/issues/:issue_iid/participants
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/participants
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
    "web_url": "http://localhost/user1"
  },
  {
    "id": 5,
    "name": "John Doe5",
    "username": "user5",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80&d=identicon",
    "web_url": "http://localhost/user5"
  }
]
```

## Comments on issues

Comments are done via the [notes](notes.md) resource.

## Get user agent details

Available only for admins.

```
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

[ce-13004]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/13004
[ce-14016]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/14016
[ce-17042]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/17042
[ce-18935]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18935
