# Todos

**Note:** This feature was [introduced][ce-3188] in GitLab 8.10

## Get a list of todos

Returns a list of todos. When no filter is applied, it returns all pending todos
for the current user. Different filters allow the user to

```
GET /todos
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `action_id` | integer | no | The ID of the action of the todo. See the table below for the ID mapping |
| `author_id` | integer | no | The ID of an author |
| `project_id` | integer | no | The ID of a project |
| `state` | string | no | The state of the todo. Can be either `pending` or `done` |
| `type` | string | no | The type of an todo. Can be either `Issue` or `MergeRequest` |

| `action_id` | Action |
| ----------- | ------ |
| 1           | Issuable assigned |
| 2           | Mentioned in issuable |
| 3           | Build failed |
| 4           | Todo marked for you |


```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos
```

Example Response:

```json
[
  {
    "id": 130,
    "project": {
      "id": 1,
      "name": "Underscore",
      "name_with_namespace": "Documentcloud / Underscore",
      "path": "underscore",
      "path_with_namespace": "documentcloud/underscore"
    },
    "author": {
      "name": "Juwan Abbott",
      "username": "halle",
      "id": 8,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0086c7b9e0d73312f32ff745fdcb43e?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/halle"
    },
    "action_name": "assigned",
    "target_id": 71,
    "target_type": "Issue",
    "target_reference": "#1",
    "target_url": "https://gitlab.example.com/documentcloud/underscore/issues/1",
    "body": "At voluptas qui nulla soluta qui et.",
    "state": "pending",
    "created_at": "2016-05-20T20:52:00.626Z"
  },
  {
    "id": 129,
    "project": {
      "id": 1,
      "name": "Underscore",
      "name_with_namespace": "Documentcloud / Underscore",
      "path": "underscore",
      "path_with_namespace": "documentcloud/underscore"
    },
    "author": {
      "name": "Juwan Abbott",
      "username": "halle",
      "id": 8,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0086c7b9e0d73312f32ff745fdcb43e?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/halle"
    },
    "action_name": "mentioned",
    "target_id": 79,
    "target_type": "Issue",
    "target_reference": "#9",
    "target_url": "https://gitlab.example.com/documentcloud/underscore/issues/9#note_959",
    "body": "@root Fix this shit",
    "state": "pending",
    "created_at": "2016-05-20T20:51:51.503Z"
  }
]
```

## Mark a todo as done

Marks a single pending todo given by its ID for the current user as done. The to
marked as done is returned in the response.

```
DELETE /todos/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a todo |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos/130
```

Example Response:

```json
{
  "id": 130,
  "project": {
    "id": 1,
    "name": "Underscore",
    "name_with_namespace": "Documentcloud / Underscore",
    "path": "underscore",
    "path_with_namespace": "documentcloud/underscore"
  },
  "author": {
    "name": "Juwan Abbott",
    "username": "halle",
    "id": 8,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a0086c7b9e0d73312f32ff745fdcb43e?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/halle"
  },
  "action_name": "assigned",
  "target_id": 71,
  "target_type": "Issue",
  "target_reference": "#1",
  "target_url": "https://gitlab.example.com/documentcloud/underscore/issues/1",
  "body": "At voluptas qui nulla soluta qui et.",
  "state": "done",
  "created_at": "2016-05-20T20:52:00.626Z"
}
```

## Mark all todos as done

Marks all pending todos for the current user as done. All todos marked as done
are returned in the response.

```
DELETE /todos
```

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos
```

Example Response:

```json
[
  {
    "id": 130,
    "project": {
      "id": 1,
      "name": "Underscore",
      "name_with_namespace": "Documentcloud / Underscore",
      "path": "underscore",
      "path_with_namespace": "documentcloud/underscore"
    },
    "author": {
      "name": "Juwan Abbott",
      "username": "halle",
      "id": 8,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0086c7b9e0d73312f32ff745fdcb43e?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/halle"
    },
    "action_name": "assigned",
    "target_id": 71,
    "target_type": "Issue",
    "target_reference": "#1",
    "target_url": "https://gitlab.example.com/documentcloud/underscore/issues/1",
    "body": "At voluptas qui nulla soluta qui et.",
    "state": "done",
    "created_at": "2016-05-20T20:52:00.626Z"
  },
  {
    "id": 129,
    "project": {
      "id": 1,
      "name": "Underscore",
      "name_with_namespace": "Documentcloud / Underscore",
      "path": "underscore",
      "path_with_namespace": "documentcloud/underscore"
    },
    "author": {
      "name": "Juwan Abbott",
      "username": "halle",
      "id": 8,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0086c7b9e0d73312f32ff745fdcb43e?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/halle"
    },
    "action_name": "mentioned",
    "target_id": 79,
    "target_type": "Issue",
    "target_reference": "#9",
    "target_url": "https://gitlab.example.com/documentcloud/underscore/issues/9#note_959",
    "body": "@root Fix this shit",
    "state": "done",
    "created_at": "2016-05-20T20:51:51.503Z"
  }
]
```

[ce-3188]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3188
