---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Discussions API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Discussions are attached to:

- Snippets
- Issues
- [Epics](../user/group/epics/_index.md)
- Merge requests
- Commits

This includes [comments, threads](../user/discussions/_index.md), and system notes.
System notes are notes about changes to the object (for example, when a milestone changes).

Label notes are not part of this API, but recorded as separate events in
[resource label events](resource_label_events.md).

## Understand note types in the API

Not all discussion types are equally available in the API:

- **Note**: A comment left on the _root_ of an issue, merge request, commit,
  or snippet.
- **Discussion**: A collection, often called a _thread_, of `DiscussionNotes` in
  an issue, merge request, commit, or snippet.
- **DiscussionNote**: An individual item in a discussion on an issue, merge request,
  commit, or snippet. Items of type `DiscussionNote` are not returned as part of the Note API.
  Not available in the [Events API](events.md).

## Discussions pagination

By default, `GET` requests return 20 results at a time because the API results are paginated.

Read more on [pagination](rest/_index.md#pagination).

## Issues

### List project issue discussion items

Gets a list of all discussion items for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`         | integer          | yes        | The IID of an issue. |

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions"
```

### Get single issue discussion item

Returns a single discussion item for a specific project issue.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | yes      | The IID of an issue. |
| `discussion_id` | integer        | yes      | The ID of a discussion item. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>"
```

### Create new issue thread

Creates a new thread to a single project issue. Similar to creating a note, but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the thread. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | yes      | The IID of an issue. |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### Add note to existing issue thread

Adds a new note to the thread. This can also [create a thread from a single comment](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

WARNING:
Notes can be added to other items than comments, such as system notes, making them threads.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | yes      | The IID of an issue. |
| `note_id`       | integer        | yes      | The ID of a thread note. |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes?body=comment"
```

### Modify existing issue thread note

Modify existing thread note of an issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | yes      | The IID of an issue. |
| `note_id`       | integer        | yes      | The ID of a thread note. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### Delete an issue thread note

Deletes an existing thread note of an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | integer        | yes      | The ID of a discussion. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | yes      | The IID of an issue. |
| `note_id`       | integer        | yes      | The ID of a discussion note. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/636"
```

## Snippets

### List project snippet discussion items

Gets a list of all discussion items for a single snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id`        | integer          | yes        | The ID of an snippet. |

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions"
```

### Get single snippet discussion item

Returns a single discussion item for a specific project snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | integer        | yes      | The ID of a discussion item. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id`    | integer        | yes      | The ID of an snippet. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>"
```

### Create new snippet thread

Creates a new thread to a single project snippet. Similar to creating
a note, but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of a discussion. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id`    | integer        | yes      | The ID of an snippet. |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### Add note to existing snippet thread

Adds a new note to the thread.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a thread note. |
| `snippet_id`    | integer        | yes      | The ID of an snippet. |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes?body=comment"
```

### Modify existing snippet thread note

Modify existing thread note of a snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a thread note. |
| `snippet_id`    | integer        | yes      | The ID of an snippet. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### Delete a snippet thread note

Deletes an existing thread note of a snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | integer        | yes      | The ID of a discussion. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a discussion note. |
| `snippet_id`    | integer        | yes      | The ID of an snippet. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/636"
```

## Epics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
and is planned for removal in v5 of the API.
In GitLab 17.4 or later, if your administrator [enabled the new look for epics](../user/group/epics/epic_work_items.md), use the
[Work Items API](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/) instead. For more information, see the [guide how to migrate your existing APIs](graphql/epic_work_items_api_migration_guide.md).
This change is a breaking change.

### List group epic discussion items

Gets a list of all discussion items for a single epic.

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `epic_id`           | integer          | yes        | The ID of an epic. |
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>"\
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions"
```

### Get single epic discussion item

Returns a single discussion item for a specific group epic.

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | integer        | yes      | The ID of a discussion item. |
| `epic_id`       | integer        | yes      | The ID of an epic. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>"
```

### Create new epic thread

Creates a new thread to a single group epic. Similar to creating
a note, but other comments (replies) can be added to it later.

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the thread. |
| `epic_id`       | integer        | yes      | The ID of an epic. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### Add note to existing epic thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of the note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `epic_id`       | integer        | yes      | The ID of an epic. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a thread note. |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes?body=comment"
```

### Modify existing epic thread note

Modify existing thread note of an epic.

```plaintext
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | yes      | The content of note or reply. |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `epic_id`       | integer        | yes      | The ID of an epic. |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a thread note. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/1108?body=comment"
```

### Delete an epic thread note

Deletes an existing thread note of an epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | integer        | yes      | The ID of a thread. |
| `epic_id`       | integer        | yes      | The ID of an epic. |
| `id`            | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `note_id`       | integer        | yes      | The ID of a thread note. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/636"
```

## Merge requests

### List project merge request discussion items

Gets a list of all discussion items for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer          | yes        | The IID of a merge request. |

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "resolved_at": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

Diff comments also contain position:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "commit_id": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27,
          "line_range": {
            "start": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_10_10",
              "type": "new"
            },
            "end": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_11_11",
              "type": "old"
            }
          }
        },
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
```

### Get single merge request discussion item

Returns a single discussion item for a specific project merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `discussion_id`     | string        | yes      | The ID of a discussion item. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | yes      | The IID of a merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>"
```

### Create new merge request thread

Creates a new thread to a single project merge request. Similar to creating
a note but other comments (replies) can be added to it later. For other approaches,
see [Post comment to commit](commits.md#post-comment-to-commit) in the Commits API,
and [Create new merge request note](notes.md#create-new-merge-request-note) in the Notes API.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

Parameters for all comments:

| Attribute                                | Type           | Required                             | Description |
| ---------------------------------------- | -------------- |--------------------------------------| ----------- |
| `body`                                   | string         | yes                                  | The content of the thread. |
| `id`                                     | integer/string | yes                                  | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid`                      | integer        | yes                                  | The IID of a merge request. |
| `position[base_sha]`                     | string         | yes (if `position*` is supplied)     | Base commit SHA in the source branch. |
| `position[head_sha]`                     | string         | yes (if `position*` is supplied)     | SHA referencing HEAD of this merge request. |
| `position[start_sha]`                    | string         | yes (if `position*` is supplied)     | SHA referencing commit in target branch. |
| `position[new_path]`                     | string         | yes (if the position type is `text`) | File path after change. |
| `position[old_path]`                     | string         | yes (if the position type is `text`) | File path before change. |
| `position[position_type]`                | string         | yes (if position* is supplied)       | Type of the position reference. Allowed values: `text`, `image`, or `file`. `file` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) in GitLab 16.4. |
| `commit_id`                              | string         | no                                   | SHA referencing commit to start this thread on. |
| `created_at`                             | string         | no                                   | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |
| `position`                               | hash           | no                                   | Position when creating a diff note. |
| `position[new_line]`                     | integer        | no                                   | For `text` diff notes, the line number after change. |
| `position[old_line]`                     | integer        | no                                   | For `text` diff notes, the line number before change. |
| `position[line_range]`                   | hash           | no                                   | Line range for a multi-line diff note. |
| `position[width]`                        | integer        | no                                   | For `image` diff notes, width of the image. |
| `position[height]`                       | integer        | no                                   | For `image` diff notes, height of the image. |
| `position[x]`                            | float          | no                                   | For `image` diff notes, X coordinate. |
| `position[y]`                            | float          | no                                   | For `image` diff notes, Y coordinate. |

#### Create a new thread on the overview page

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### Create a new thread in the merge request diff

- Both `position[old_path]` and `position[new_path]` are required and must refer
  to the file path before and after the change.
- To create a thread on an added line (highlighted in green in the merge request diff),
  use `position[new_line]` and don't include `position[old_line]`.
- To create a thread on a removed line (highlighted in red in the merge request diff),
  use `position[old_line]` and don't include `position[new_line]`.
- To create a thread on an unchanged line, include both `position[new_line]` and
  `position[old_line]` for the line. These positions might not be the same if earlier
  changes in the file changed the line number. For the discussion about a fix, see
  [issue 32516](https://gitlab.com/gitlab-org/gitlab/-/issues/325161).
- If you specify incorrect `base`, `head`, `start`, or `SHA` parameters, you might run
  into the bug described in [issue #296829)](https://gitlab.com/gitlab-org/gitlab/-/issues/296829).

To create a new thread:

1. [Get the latest merge request version](merge_requests.md#get-merge-request-diff-versions):

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
   ```

1. Note the details of the latest version, which is listed first in the response array.

   ```json
   [
     {
       "id": 164560414,
       "head_commit_sha": "f9ce7e16e56c162edbc9e480108041cf6b0291fe",
       "base_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "start_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "created_at": "2021-03-30T09:18:27.351Z",
       "merge_request_id": 93958054,
       "state": "collected",
       "real_size": "2"
     },
     "previous versions are here"
   ]
   ```

1. Create a new diff thread. This example creates a thread on an added line:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>"\
     --form 'position[position_type]=text'\
     --form 'position[base_sha]=<use base_commit_sha from the versions response>'\
     --form 'position[head_sha]=<use head_commit_sha from the versions response>'\
     --form 'position[start_sha]=<use start_commit_sha from the versions response>'\
     --form 'position[new_path]=file.js'\
     --form 'position[old_path]=file.js'\
     --form 'position[new_line]=18'\
     --form 'body=test comment body'\
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
   ```

#### Parameters for multiline comments

Parameters for multiline comments only:

| Attribute                                | Type           | Required | Description |
| ---------------------------------------- | -------------- | -------- | ----------- |
| `position[line_range][end][line_code]`   | string         | yes      | [Line code](#line-code) for the end line. |
| `position[line_range][end][type]`        | string         | yes      | Use `new` for lines added by this commit, otherwise `old`. |
| `position[line_range][start][line_code]` | string         | yes      | [Line code](#line-code) for the start line. |
| `position[line_range][start][type]`      | string         | yes      | Use `new` for lines added by this commit, otherwise `old`. |
| `position[line_range][end]`              | hash           | no       | Multiline note ending line. |
| `position[line_range][start]`            | hash           | no       | Multiline note starting line. |

#### Line code

A line code is of the form `<SHA>_<old>_<new>`, like this: `adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`

- `<SHA>` is the SHA1 hash of the filename.
- `<old>` is the line number before the change.
- `<new>` is the line number after the change.

For example, if a commit (`<COMMIT_ID>`) deletes line 463 in the README, you can comment
on the deletion by referencing line 463 in the *old* file:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Very clever to remove this unnecessary line!" \
  --form "path=README" \
  --form "line=463" \
  --form "line_type=old" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

If a commit (`<COMMIT_ID>`) adds line 157 to `hello.rb`, you can comment on the
addition by referencing line 157 in the *new* file:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=This is brilliant!" \
  --form "path=hello.rb" \
  --form "line=157" \
  --form "line_type=new" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

### Resolve a merge request thread

Resolve or unresolve a thread of discussion in a merge request.

Prerequisites:

- You must have at least the Developer role, or be the author of the change being reviewed.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `discussion_id`     | string        | yes      | The ID of a thread. |
| `merge_request_iid` | integer        | yes      | The IID of a merge request. |
| `resolved`          | boolean        | yes      | Resolve or unresolve the discussion. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>?resolved=true"
```

### Add note to existing merge request thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `body`              | string         | yes      | The content of the note or reply. |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `discussion_id`     | string        | yes      | The ID of a thread. |
| `merge_request_iid` | integer        | yes      | The IID of a merge request. |
| `note_id`           | integer        | yes      | The ID of a thread note. |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes?body=comment"
```

### Modify an existing merge request thread note

Modify or resolve an existing thread note of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `discussion_id`     | string        | yes      | The ID of a thread. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | yes      | The IID of a merge request. |
| `note_id`           | integer        | yes      | The ID of a thread note. |
| `body`              | string         | no       | The content of the note or reply. Exactly one of `body` or `resolved` must be set. |
| `resolved`          | boolean        | no       | Resolve or unresolve the note. Exactly one of `body` or `resolved` must be set. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/1108?body=comment"
```

Resolving a note:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/1108?resolved=true"
```

### Delete a merge request thread note

Deletes an existing thread note of a merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `discussion_id`     | string        | yes      | The ID of a thread. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | yes      | The IID of a merge request. |
| `note_id`           | integer        | yes      | The ID of a thread note. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/636"
```

## Commits

### List project commit discussion items

Gets a list of all discussion items for a single commit.

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `commit_id`         | string           | yes        | The SHA of a commit. |
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

Diff comments contain also position:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27
        },
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions"
```

### Get single commit discussion item

Returns a single discussion item for a specific project commit

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `commit_id`         | string         | yes      | The SHA of a commit. |
| `discussion_id`     | string         | yes      | The ID of a discussion item. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>"
```

### Create new commit thread

Creates a new thread to a single project commit. Similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions
```

Parameters:

| Attribute                 | Type           | Required                         | Description |
| ------------------------- | -------------- |----------------------------------| ----------- |
| `body`                    | string         | yes                              | The content of the thread. |
| `commit_id`               | string         | yes                              | The SHA of a commit. |
| `id`                      | integer/string | yes                              | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `position[base_sha]`      | string         | yes (if `position*` is supplied) | SHA of the parent commit. |
| `position[head_sha]`      | string         | yes (if `position*` is supplied) | The SHA of this commit. Same as `commit_id`. |
| `position[start_sha]`     | string         | yes (if `position*` is supplied) | SHA of the parent commit. |
| `position[position_type]` | string         | yes (if `position*` is supplied) | Type of the position reference. Allowed values: `text`, `image`, or `file`. `file` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) in GitLab 16.4. |
| `created_at`              | string         | no                               | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |
| `position`                | hash           | no                               | Position when creating a diff note. |

| `position[new_path]`      | string         | no       | File path after change. |
| `position[new_line]`      | integer        | no       | Line number after change. |
| `position[old_path]`      | string         | no       | File path before change. |
| `position[old_line]`      | integer        | no       | Line number before change. |
| `position[height]`        | integer        | no       | For `image` diff notes, image height. |
| `position[width]`         | integer        | no       | For `image` diff notes, image width. |
| `position[x]`             | integer        | no       | For `image` diff notes, X coordinate. |
| `position[y]`             | integer        | no       | For `image` diff notes, Y coordinate. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions?body=comment"
```

The rules for creating the API request are the same as when
[creating a new thread in the merge request diff](#create-a-new-thread-in-the-merge-request-diff).
The exceptions:

- `base_sha`
- `head_sha`
- `start_sha`

### Add note to existing commit thread

Adds a new note to the thread.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `body`              | string         | yes      | The content of the note or reply. |
| `commit_id`         | string         | yes      | The SHA of a commit. |
| `discussion_id`     | string         | yes      | The ID of a thread. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `note_id`           | integer        | yes      | The ID of a thread note. |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, such `2016-03-11T03:45:40Z`. Requires administrator or project/group owner rights. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes?body=comment
```

### Modify an existing commit thread note

Modify or resolve an existing thread note of a commit.

```plaintext
PUT /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `commit_id`         | string         | yes      | The SHA of a commit. |
| `discussion_id`     | string         | yes      | The ID of a thread. |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `note_id`           | integer        | yes      | The ID of a thread note. |
| `body`              | string         | no       | The content of a note. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/1108?body=comment"
```

Resolving a note:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/1108?resolved=true"
```

### Delete a commit thread note

Deletes an existing thread note of a commit.

```plaintext
DELETE /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `commit_id`         | string         | yes      | The SHA of a commit. |
| `discussion_id`     | string         | yes      | The ID of a thread. |
| `note_id`           | integer        | yes      | The ID of a thread note. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/636"
```
