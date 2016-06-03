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
      "labels" : [],
      "subscribed" : false
   }
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
      "created_at" : "2016-01-04T15:31:46.176Z",
      "subscribed" : false
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
   "created_at" : "2016-01-04T15:31:46.176Z",
   "subscribed": false
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
| `created_at`    | string  | no  | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` |

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
   "milestone" : null,
   "subscribed" : true
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
| `updated_at`    | string  | no  | Date time string, ISO 8601 formatted, e.g. `2016-03-11T03:45:40Z` |

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
   "milestone" : null,
   "subscribed" : true
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

## Move an issue

Moves an issue to a different project. If the operation is successful, a status
code `201` together with moved issue is returned. If the project, issue, or
target project is not found, error `404` is returned. If the target project
equals the source project or the user has insufficient permissions to move an
issue, error `400` together with an explaining error message is returned.

```
POST /projects/:id/issues/:issue_id/move
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of a project's issue |
| `to_project_id` | integer | yes | The ID of the new project |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/4/issues/85/move
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
  "labels": [],
  "milestone": null,
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/axel.block"
  },
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/solon.cremin"
  }
}
```

## Subscribe to an issue

Subscribes the authenticated user to an issue to receive notifications. If the
operation is successful, status code `201` together with the updated issue is
returned. If the user is already subscribed to the issue, the status code `304`
is returned. If the project or issue is not found, status code `404` is
returned.

```
POST /projects/:id/issues/:issue_id/subscription
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of a project's issue |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/issues/93/subscription
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
  "labels": [],
  "milestone": null,
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/axel.block"
  },
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/solon.cremin"
  }
}
```

## Unsubscribe from an issue

Unsubscribes the authenticated user from the issue to not receive notifications
from it. If the operation is successful, status code `200` together with the
updated issue is returned. If the user is not subscribed to the issue, the
status code `304` is returned. If the project or issue is not found, status code
`404` is returned.

```
DELETE /projects/:id/issues/:issue_id/subscription
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of a project's issue |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/issues/93/subscription
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
    "web_url": "https://gitlab.example.com/u/keyon"
  },
  "author": {
    "name": "Vivian Hermann",
    "username": "orville",
    "id": 11,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "http://lgitlab.example.com/u/orville"
  },
  "subscribed": false
}
```

## Comments on issues

Comments are done via the [notes](notes.md) resource.
