---
stage: Foundations
group: Personal Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab To-Do List API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Interact with [to-do items](../user/todos.md) using the REST API.

## Get a list of to-do items

Returns a list of to-do items. When no filter is applied, it
returns all pending to-do items for the current user. Different filters allow the
user to refine the request.

```plaintext
GET /todos
```

Parameters:

| Attribute | Type | Required | Description                                                                                                                                                                                        |
| --------- | ---- | -------- |----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `action` | string | no | The action to be filtered. Can be `assigned`, `mentioned`, `build_failed`, `marked`, `approval_required`, `unmergeable`, `directly_addressed`, `merge_train_removed` or `member_access_requested`. |
| `author_id` | integer | no | The ID of an author                                                                                                                                                                                |
| `project_id` | integer | no | The ID of a project                                                                                                                                                                                |
| `group_id` | integer | no | The ID of a group                                                                                                                                                                                  |
| `state` | string | no | The state of the to-do item. Can be either `pending` or `done`                                                                                                                                     |
| `type` | string | no | The type of to-do item. Can be either `Issue`, `MergeRequest`, `Commit`, `Epic`, `DesignManagement::Design`, `AlertManagement::Alert`, `Project`, `Namespace` or `Vulnerability`                   |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/todos"
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
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
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
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
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
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
  },
  {
    "id": 98,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
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
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
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
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:49:24.624Z",
    "updated_at": "2016-06-17T07:49:24.624Z"
  }
]
```

## Mark a to-do item as done

Marks a single pending to-do item given by its ID for the current user as done. The
to-do item marked as done is returned in the response.

```plaintext
POST /todos/:id/mark_as_done
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of to-do item |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/todos/130/mark_as_done"
```

Example Response:

```json
{
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
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
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
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
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "done",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
}
```

## Mark all to-do items as done

Marks all pending to-do items for the current user as done. It returns the HTTP status code `204` with an empty response.

```plaintext
POST /todos/mark_as_done
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/todos/mark_as_done"
```
