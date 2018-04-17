# Epics API **[ULTIMATE]**

Every API call to epic must be authenticated.

If a user is not a member of a group and the group is private, a `GET` request on that group will result to a `404` status code.

If epics feature is not available a `403` status code will be returned.

## Epic issues API

The [epic issues API](epic_issues.md) allows you to interact with issues associated with an epic.

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
  "labels": [],
  "start_date": null,
  "end_date": null,
  "created_at": "2018-01-21T06:21:13.165Z",
  "updated_at": "2018-01-22T12:41:41.166Z"
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
  "end_date": null,
  "created_at": "2018-01-21T06:21:13.165Z",
  "updated_at": "2018-01-22T12:41:41.166Z"
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
  "labels": [],
  "start_date": null,
  "end_date": null,
  "created_at": "2018-01-21T06:21:13.165Z",
  "updated_at": "2018-01-22T12:41:41.166Z"
}
```

## Update epic

Updates an epic

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
| `start_date`        | string           | no         | The start date of an epic  |
| `end_date`          | string.          | no         | The end date of an epic |

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
  "labels": [],
  "start_date": null,
  "end_date": null,
  "created_at": "2018-01-21T06:21:13.165Z",
  "updated_at": "2018-01-22T12:41:41.166Z"
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
