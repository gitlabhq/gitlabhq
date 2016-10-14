# Todos

> [Introduced][ce-3188] in GitLab 8.10.

## Get a list of todos

Returns a list of todos. When no filter is applied, it returns all pending todos
for the current user. Different filters allow the user to precise the request.

```
GET /todos
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `action` | string | no | The action to be filtered. Can be `assigned`, `mentioned`, `build_failed`, `marked`, or `approval_required`. |
| `author_id` | integer | no | The ID of an author |
| `project_id` | integer | no | The ID of a project |
| `state` | string | no | The state of the todo. Can be either `pending` or `done` |
| `type` | string | no | The type of a todo. Can be either `Issue` or `MergeRequest` |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos
```

Example Response:

```json
[
  {
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-ce",
      "path_with_namespace": "gitlab-org/gitlab-ce"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_build_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ce/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:52:35.225Z"
  },
  {
    "id": 98,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-ce",
      "path_with_namespace": "gitlab-org/gitlab-ce"
    },
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/craig_rutherford"
    },
    "action_name": "assigned",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_build_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ce/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:49:24.624Z"
  }
]
```

## Mark a todo as done

Marks a single pending todo given by its ID for the current user as done. The
todo marked as done is returned in the response.

```
DELETE /todos/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a todo |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos/130
```

Example Response:

```json
{
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-ce",
      "path_with_namespace": "gitlab-org/gitlab-ce"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/u/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/u/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_build_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ce/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "done",
    "created_at": "2016-06-17T07:52:35.225Z"
}
```

## Mark all todos as done

Marks all pending todos for the current user as done. It returns the number of marked todos.

```
DELETE /todos
```

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/todos
```

Example Response:

```json
3
```

[ce-3188]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3188
