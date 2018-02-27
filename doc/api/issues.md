# Issues API

Every API call to issues must be authenticated.

If a user is not a member of a project and the project is private, a `GET`
request on that project will result to a `404` status code.

## Issues pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

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
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                                       |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `No+Label` lists all issues with no labels                         |
| `milestone`         | string           | no         | The milestone title                                                                                                                                 |
| `scope`             | string           | no         | Return issues for the given scope: `created-by-me`, `assigned-to-me` or `all`. Defaults to `created-by-me` _([Introduced][ce-13004] in GitLab 9.5)_ |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Combine with `scope=all` or `scope=assigned-to-me`. _([Introduced][ce-13004] in GitLab 9.5)_          |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id` _([Introduced][ce-13004] in GitLab 9.5)_                                                              |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji` _([Introduced][ce-14016] in GitLab 10.0)_                                      |
| `iids[]`            | Array[integer]   | no         | Return only the issues having the given `iid`                                                                                                       |
| `order_by`          | string           | no         | Return issues ordered by `created_at` or `updated_at` fields. Default is `created_at`                                                               |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                                                    |
| `search`            | string           | no         | Search issues against their `title` and `description`                                                                                               |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                                                    |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                                                   |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                                                    |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                                                   |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/issues
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
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "web_url": "http://example.com/example/example/issues/6",
      "confidential": false,
      "weight": null,
      "discussion_locked": false,
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
   }
]
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                 |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `No+Label` lists all issues with no labels   |
| `iids[]`            | Array[integer]   | no         | Return only the issues having the given `iid`                                                                                 |
| `milestone`         | string           | no         | The milestone title                                                                                                           |
| `scope`             | string           | no         | Return issues for the given scope: `created-by-me`, `assigned-to-me` or `all` _([Introduced][ce-13004] in GitLab 9.5)_        |
| `author_id`         | integer          | no         | Return issues created by the given user `id` _([Introduced][ce-13004] in GitLab 9.5)_                                         |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id` _([Introduced][ce-13004] in GitLab 9.5)_                                        |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji` _([Introduced][ce-14016] in GitLab 10.0)_                |
| `order_by`          | string           | no         | Return issues ordered by `created_at` or `updated_at` fields. Default is `created_at`                                         |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `search`            | string           | no         | Search group issues against their `title` and `description`                                                                   |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                              |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                             |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                              |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                             |


```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/4/issues
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
      "labels" : [],
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : null,
      "closed_by" : null,
      "user_notes_count": 1,
      "due_date": null,
      "web_url": "http://example.com/example/example/issues/1",
      "confidential": false,
      "weight": null,
      "discussion_locked": false,
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
   }
]
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user               |
| `iids[]`            | Array[integer]   | no         | Return only the milestone having the given `iid`                                                                              |
| `state`             | string           | no         | Return all issues or just those that are `opened` or `closed`                                                                 |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `No+Label` lists all issues with no labels   |
| `milestone`         | string           | no         | The milestone title                                                                                                           |
| `scope`             | string           | no         | Return issues for the given scope: `created-by-me`, `assigned-to-me` or `all` _([Introduced][ce-13004] in GitLab 9.5)_        |
| `author_id`         | integer          | no         | Return issues created by the given user `id` _([Introduced][ce-13004] in GitLab 9.5)_                                         |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id` _([Introduced][ce-13004] in GitLab 9.5)_                                        |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji` _([Introduced][ce-14016] in GitLab 10.0)_                |
| `order_by`          | string           | no         | Return issues ordered by `created_at` or `updated_at` fields. Default is `created_at`                                         |
| `sort`              | string           | no         | Return issues sorted in `asc` or `desc` order. Default is `desc`                                                              |
| `search`            | string           | no         | Search project issues against their `title` and `description`                                                                 |
| `created_after`     | datetime         | no         | Return issues created on or after the given time                                                                              |
| `created_before`    | datetime         | no         | Return issues created on or before the given time                                                                             |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time                                                                              |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time                                                                             |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/issues
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
      "labels" : [],
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
      "web_url": "http://example.com/example/example/issues/1",
      "confidential": false,
      "weight": null,
      "discussion_locked": false,
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
   }
]
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/issues/41
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
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z",
   "closed_at" : null,
   "closed_by" : null,
   "subscribed": false,
   "user_notes_count": 1,
   "due_date": null,
   "web_url": "http://example.com/example/example/issues/1",
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "weight": null,
   "discussion_locked": false,
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## New issue

Creates a new project issue.

```
POST /projects/:id/issues
```

| Attribute                                 | Type           | Required | Description  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `title`                                   | string         | yes      | The title of an issue |
| `description`                             | string         | no       | The description of an issue  |
| `confidential`                            | boolean        | no       | Set an issue to be confidential. Default is `false`.  |
| `assignee_ids`                            | Array[integer] | no       | The ID of a user to assign issue |
| `milestone_id`                            | integer        | no       | The ID of a milestone to assign issue  |
| `labels`                                  | string         | no       | Comma-separated label names for an issue  |
| `created_at`                              | string         | no       | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` (requires admin or project owner rights) |
| `due_date`                                | string         | no       | Date time string in the format YEAR-MONTH-DAY, e.g. `2016-03-11` |
| `merge_request_to_resolve_discussions_of` | integer        | no       | The IID of a merge request in which to resolve all issues. This will fill the issue with a default description and mark all discussions as resolved. When passing a description or title, these values will take precedence over the default values.|
| `discussion_to_resolve`                   | string         | no       | The ID of a discussion to resolve. This will fill in the issue with a default description and mark the discussion as resolved. Use in combination with `merge_request_to_resolve_discussions_of`. |
| `weight` | integer                                         | no | The weight of the issue in range 0 to 9 |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug
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
   "web_url": "http://example.com/example/example/issues/14",
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "weight": null,
   "discussion_locked": false,
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Edit issue

Updates an existing project issue. This call is also used to mark an issue as
closed.

```
PUT /projects/:id/issues/:issue_iid
```

| Attribute      | Type    | Required | Description                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid`    | integer | yes      | The internal ID of a project's issue                                                                       |
| `title`        | string  | no       | The title of an issue                                                                                      |
| `description`  | string  | no       | The description of an issue                                                                                |
| `confidential` | boolean | no       | Updates an issue to be confidential                                                                        |
| `assignee_ids`  | Array[integer] | no  | The ID of the user(s) to assign the issue to. Set to `0` or provide an empty value to unassign all assignees.  |
| `milestone_id` | integer | no       | The ID of a milestone to assign the issue to. Set to `0` or provide an empty value to unassign a milestone.|
| `labels`       | string  | no       | Comma-separated label names for an issue. Set to an empty string to unassign all labels.                   |
| `state_event`  | string  | no       | The state event of an issue. Set `close` to close the issue and `reopen` to reopen it                      |
| `updated_at`   | string  | no       | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` (requires admin or project owner rights) |
| `due_date`     | string  | no       | Date time string in the format YEAR-MONTH-DAY, e.g. `2016-03-11`                                           |
| `weight`       | integer | no       | The weight of the issue in range 0 to 9                                                                    |
| `discussion_locked` | boolean | no  | Flag indicating if the issue's discussion is locked. If the discussion is locked only project members can add or edit comments. |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close
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
   "id" : 85,
   "assignees" : [],
   "assignee" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": "2016-07-22",
   "web_url": "http://example.com/example/example/issues/15",
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "weight": null,
   "discussion_locked": false,
   "_links": {
      "self": "http://example.com/api/v4/projects/1/issues/2",
      "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://example.com/api/v4/projects/1"
   }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Delete an issue

Only for admins and project owners. Soft deletes the issue in question.

```
DELETE /projects/:id/issues/:issue_iid
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/4/issues/85
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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data '{"to_project_id": 5}' https://gitlab.example.com/api/v4/projects/4/issues/85/move
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
  "web_url": "http://example.com/example/example/issues/11",
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "weight": null,
  "discussion_locked": false,
  "_links": {
    "self": "http://example.com/api/v4/projects/1/issues/2",
    "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://example.com/api/v4/projects/1"
  }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe
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
  "web_url": "http://example.com/example/example/issues/11",
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "weight": null,
  "discussion_locked": false,
  "_links": {
    "self": "http://example.com/api/v4/projects/1/issues/2",
    "notes": "http://example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://example.com/api/v4/projects/1"
  }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe
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
  "milestone": null,
  "assignee": {
    "name": "Edwardo Grady",
    "username": "keyon",
    "id": 21,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/3e6f06a86cf27fa8b56f3f74f7615987?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/keyon"
  },
  "closed_at":null,
  "closed_by":null,
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
  "web_url": "http://example.com/example/example/issues/12",
  "confidential": false,
  "discussion_locked": false
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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/todo
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
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/110",
    "confidential": false,
    "weight": null,
    "discussion_locked": false
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/issues/10",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m
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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate
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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h
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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time
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
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats
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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by
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
    "user_notes_count": 1,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/6432",
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
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/participants
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
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

[ce-13004]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13004
[ce-14016]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14016
