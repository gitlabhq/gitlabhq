# Issues

Every API call to issues must be authenticated.

If a user is not a member of a project and the project is private, a `GET`
request on that project will result to a `404` status code.

## Issues pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

## List issues

Get all issues created by the authenticated user.

```
GET /issues
GET /issues?state=opened
GET /issues?state=closed
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `state`   | string  | no    | Return all issues or just those that are `opened` or `closed`|
| `labels`  | string  | no    | Comma-separated list of label names |
| `order_by`| string  | no    | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at` |
| `sort`    | string  | no    | Return requests sorted in `asc` or `desc` order. Default is `desc`  |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/issues
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
         "web_url" : "https://gitlab.example.com/u/eileen.lowe",
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
         "web_url" : "https://gitlab.example.com/u/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : []
   },
]
```

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
GET /projects/:id/issues?iid=42
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of a project |
| `iid`     | integer | no    | Return the issue having the given `iid` |
| `state`   | string  | no    | Return all issues or just those that are `opened` or `closed`|
| `labels`  | string  | no    | Comma-separated list of label names |
| `milestone` | string| no    | The milestone title |
| `order_by`| string  | no    | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at` |
| `sort`    | string  | no    | Return requests sorted in `asc` or `desc` order. Default is `desc`  |


```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues
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
         "web_url" : "https://gitlab.example.com/u/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/u/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "labels" : [],
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z"
   }
]
```

## Single issue

Get a single project issue.

```
GET /projects/:id/issues/:issue_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of a project |
| `issue_id`| integer | yes   | The ID of a project's issue |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues/41
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
      "updated_at" : "2016-01-04T15:31:39.788Z"
   },
   "author" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/u/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
   },
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "state" : "closed",
   "iid" : 1,
   "assignee" : {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/u/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   },
   "labels" : [],
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z"
}
```

## New issue

Creates a new project issue.

If the operation is successful, a status code of `200` and the newly-created
issue is returned. If an error occurs, an error number and a message explaining
the reason is returned.

```
POST /projects/:id/issues
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | integer | yes | The ID of a project |
| `title`         | string  | yes | The title of an issue |
| `description`   | string  | no  | The description of an issue  |
| `assignee_id`   | integer | no  | The ID of a user to assign issue |
| `milestone_id`  | integer | no  | The ID of a milestone to assign issue |
| `labels`        | string  | no  | Comma-separated label names for an issue  |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues?title=Issues%20with%20auth&labels=bug
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
   "assignee" : null,
   "labels" : [
      "bug"
   ],
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/u/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
   },
   "description" : null,
   "updated_at" : "2016-01-07T12:44:33.959Z",
   "milestone" : null
}
```

## Edit issue

Updates an existing project issue. This call is also used to mark an issue as
closed.

If the operation is successful, a code of `200` and the updated issue is
returned. If an error occurs, an error number and a message explaining the
reason is returned.

```
PUT /projects/:id/issues/:issue_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | integer | yes | The ID of a project |
| `issue_id`      | integer | yes | The ID of a project's issue |
| `title`         | string  | no  | The title of an issue |
| `description`   | string  | no  | The description of an issue  |
| `assignee_id`   | integer | no  | The ID of a user to assign the issue to |
| `milestone_id`  | integer | no  | The ID of a milestone to assign the issue to |
| `labels`        | string  | no  | Comma-separated label names for an issue  |
| `state_event`   | string  | no  | The state event of an issue. Set `close` to close the issue and `reopen` to reopen it |

```bash
curl -X PUT -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues/85?state_event=close
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
      "web_url" : "https://gitlab.example.com/u/eileen.lowe"
   },
   "state" : "closed",
   "title" : "Issues with auth",
   "project_id" : 4,
   "description" : null,
   "updated_at" : "2016-01-07T12:55:16.213Z",
   "iid" : 15,
   "labels" : [
      "bug"
   ],
   "id" : 85,
   "assignee" : null,
   "milestone" : null
}
```

## Delete an issue

Only for admins and project owners. Soft deletes the issue in question.
If the operation is successful, a status code `200` is returned. In case you cannot
destroy this issue, or it is not present, code `404` is given.

```
DELETE /projects/:id/issues/:issue_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | integer | yes | The ID of a project |
| `issue_id`      | integer | yes | The ID of a project's issue |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues/85
```

## Comments on issues

Comments are done via the [notes](notes.md) resource.
