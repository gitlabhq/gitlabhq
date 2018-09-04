# Epics API **[ULTIMATE]**

Every API call to epic must be authenticated.

If a user is not a member of a group and the group is private, a `GET` request on that group will result to a `404` status code.

If epics feature is not available a `403` status code will be returned.

## Epic issues API

The [epic issues API](epic_issues.md) allows you to interact with issues associated with an epic.

# Milestone dates integration

> [Introduced][ee-6448] in GitLab 11.3.

Since start date and due date can be dynamically sourced from related issue milestones, when user has edit permission, additional fields will be shown. These include two boolean fields `start_date_is_fixed` and `due_date_is_fixed`, and four date fields `start_date_fixed`, `start_date_from_milestones`, `due_date_fixed` and `due_date_from_milestones`.

`end_date` has been deprecated in favor of `due_date`.

## List epics for a group

Gets all epics of the requested group and its subgroups.

```
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `author_id`         | integer          | no         | Return epics created by the given user `id`                                                                                                        |
| `labels`            | string           | no         | Return epics matching a comma separated list of labels names. Label names from the epic group or a parent group can be used                |
| `order_by`          | string           | no         | Return epics ordered by `created_at` or `updated_at` fields. Default is `created_at`                                                               |
| `sort`              | string           | no         | Return epics sorted in `asc` or `desc` order. Default is `desc`                                                                                    |
| `search`            | string           | no         | Search epics against their `title` and `description`                                                                                               |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics
```

Example response:

```json
[
  {
  "id": 29,
  "iid": 4,
  "group_id": 7,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
  }
]
```

## Single epic

Gets a single epic

```
GET /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `epic_iid`          | integer/string   | yes        | The internal ID  of the epic.  |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics/5
```

Example response:

```json
{
  "id": 30,
  "iid": 5,
  "group_id": 7,
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author":{
    "id": 7,
    "name": "Pamella Huel",
    "username": "arnita",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
    "web_url": "http://localhost:3001/arnita"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```

## New epic

Creates a new epic

```
POST /groups/:id/epics
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `title`             | string           | yes        | The title of the epic |
| `labels`            | string           | no         | The comma separated list of labels |
| `description`       | string           | no         | The description of the epic  |
| `start_date`        | string           | no         | The start date of the epic  |
| `end_date`          | string.          | no         | The end date of the epic |

```bash
curl --header POST "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "title": "Epic",
  "description": "Epic description",
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```

## Update epic

Updates an epic

Note that after [11.3][ee-6448], `start_date` and `end_date` should no longer be updated directly, as they now represent composite values. Users can configure via `_is_fixed` and `_fixed` fields instead.

```
PUT /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `epic_iid`          | integer/string   | yes        | The internal ID  of the epic  |
| `title`             | string           | no         | The title of an epic |
| `description`       | string           | no         | The description of an epic  |
| `labels`            | string           | no         | The comma separated list of labels |
| `start_date_is_fixed` | boolean        | no         | Whether start date should be sourced from `start_date_fixed` (since 11.3) |
| `start_date_fixed`  | string           | no         | The fixed start date of an epic (since 11.3) |
| `due_date_is_fixed` | boolean          | no         | Whether due date should be sourced from `due_date_fixed` (since 11.3) |
| `due_date_fixed`    | string           | no         | The fixed due date of an epic (since 11.3) |

```bash
curl --header PUT "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "title": "New Title",
  "description": "Epic description",
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```

## Delete epic

Deletes an epic

```
DELETE /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `epic_iid`          | integer/string   | yes        | The internal ID  of the epic.  |

```bash
curl --header DELETE "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title
```

## Create a todo

Manually creates a todo for the current user on an epic. If
there already exists a todo for the user on that epic, status code `304` is
returned.

```
POST /groups/:id/epics/:epic_iid/todo
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes   | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `epic_iid ` | integer | yes          | The internal ID of a group's epic |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/1/epics/5/todo
```

Example response:

```json
{
  "id": 112,
  "group": {
    "id": 1,
    "name": "Gitlab",
    "path": "gitlab",
    "kind": "group",
    "full_path": "base/gitlab",
    "parent_id": null
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
  "target_type": "epic",
  "target": {
    "id": 30,
    "iid": 5,
    "group_id": 1,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author":{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null,
    "created_at": "2018-01-21T06:21:13.165Z",
    "updated_at": "2018-01-22T12:41:41.166Z"
  },
  "target_url": "https://gitlab.example.com/groups/epics/5",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

[ee-6448]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6448
