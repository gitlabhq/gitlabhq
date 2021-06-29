---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# Discussions API **(FREE)**

Discussions are a set of related notes on:

- Snippets
- Issues
- Epics **(ULTIMATE)**
- Merge requests
- Commits

This includes system notes, which are notes about changes to the object (for example, when a milestone changes, a corresponding system note is added). Label notes are not part of this API, but recorded as separate events in [resource label events](resource_label_events.md).

## Discussions pagination

By default, `GET` requests return 20 results at a time because the API results are paginated.

Read more on [pagination](index.md#pagination).

## Issues

### List project issue discussion items

Gets a list of all discussion items for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`         | integer          | yes        | The IID of an issue |

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
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions"
```

### Get single issue discussion item

Returns a single discussion item for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7"
```

### Create new issue thread

Creates a new thread to a single project issue. This is similar to creating a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `body`          | string         | yes      | The content of the thread |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### Add note to existing issue thread

Adds a new note to the thread. This can also [create a thread from a single comment](../user/discussions/#create-a-thread-by-replying-to-a-standard-comment).

**WARNING**
Notes can be added to other items than comments, such as system notes, making them threads.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment"
```

### Modify existing issue thread note

Modify existing thread note of an issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment"
```

### Delete an issue thread note

Deletes an existing thread note of an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/636"
```

## Snippets

### List project snippet discussion items

Gets a list of all discussion items for a single snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`        | integer          | yes        | The ID of an snippet |

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
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions"
```

### Get single snippet discussion item

Returns a single discussion item for a specific project snippet

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7"
```

### Create new snippet thread

Creates a new thread to a single project snippet. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### Add note to existing snippet thread

Adds a new note to the thread.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment"
```

### Modify existing snippet thread note

Modify existing thread note of a snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment"
```

### Delete a snippet thread note

Deletes an existing thread note of a snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/636"
```

## Epics **(ULTIMATE)**

### List group epic discussion items

Gets a list of all discussion items for a single epic.

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`           | integer          | yes        | The ID of an epic |

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
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions"
```

### Get single epic discussion item

Returns a single discussion item for a specific group epic

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7"
```

### Create new epic thread

Creates a new thread to a single group epic. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `body`          | string         | yes      | The content of the thread |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### Add note to existing epic thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment"
```

### Modify existing epic thread note

Modify existing thread note of an epic.

```plaintext
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of note/reply |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment"
```

### Delete an epic thread note

Deletes an existing thread note of an epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/636"
```

## Merge requests

### List project merge request discussion items

Gets a list of all discussion items for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer          | yes        | The IID of a merge request |

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
        "noteable_type": "Merge request",
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
        "noteable_type": "Merge request",
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
        "noteable_type": "Merge request",
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
        "noteable_type": "Merge request",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
```

### Get single merge request discussion item

Returns a single discussion item for a specific project merge request

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a discussion item |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new merge request thread

> The `commit id` entry was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47130) in GitLab 13.7.

Creates a new thread to a single project merge request. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

Parameters for all comments:

| Attribute                                | Type           | Required | Description |
| ---------------------------------------- | -------------- | -------- | ----------- |
| `id`                                     | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid`                      | integer        | yes      | The IID of a merge request |
| `body`                                   | string         | yes      | The content of the thread |
| `commit_id`                              | string         | no       | SHA referencing commit to start this thread on |
| `created_at`                             | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |
| `position`                               | hash           | no       | Position when creating a diff note |
| `position[base_sha]`                     | string         | yes      | Base commit SHA in the source branch |
| `position[start_sha]`                    | string         | yes      | SHA referencing commit in target branch |
| `position[head_sha]`                     | string         | yes      | SHA referencing HEAD of this merge request |
| `position[position_type]`                | string         | yes      | Type of the position reference', allowed values: `text` or `image` |
| `position[new_path]`                     | string         | yes (if the position type is `text`) | File path after change |
| `position[new_line]`                     | integer        | no       | Line number after change (for `text` diff notes) |
| `position[old_path]`                     | string         | yes (if the position type is `text`) | File path before change |
| `position[old_line]`                     | integer        | no       | Line number before change (for `text` diff notes) |
| `position[line_range]`                   | hash           | no       | Line range for a multi-line diff note |
| `position[width]`                        | integer        | no       | Width of the image (for `image` diff notes) |
| `position[height]`                       | integer        | no       | Height of the image (for `image` diff notes) |
| `position[x]`                            | float          | no       | X coordinate (for `image` diff notes) |
| `position[y]`                            | float          | no       | Y coordinate (for `image` diff notes) |

#### Create a new thread on the overview page

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### Create a new thread in the merge request diff

- Both `position[old_path]` and `position[new_path]` are required and must refer to the file path before and after the change.
- To create a thread on an added line (highlighted in green in the merge request diff), use `position[new_line]` and don't include `position[old_line]`.
- To create a thread on a removed line (highlighted in red in the merge request diff), use `position[old_line]` and don't include `position[new_line]`.
- To create a thread on an unchanged line, include both `position[new_line]` and `position[old_line]` for the line. These positions might not be the same if earlier changes in the file changed the line number. This is a bug that we plan to fix in [GraphQL `createDiffNote` forces clients to compute redundant information (#325161)](https://gitlab.com/gitlab-org/gitlab/-/issues/325161).
- If you specify incorrect `base`/`head`/`start` `SHA` parameters, you might run into the following bug: [Merge request comments receive "download" link instead of inline code (#296829)](https://gitlab.com/gitlab-org/gitlab/-/issues/296829).

To create a new thread:

1. [Get the latest merge request version](merge_requests.md#get-mr-diff-versions):

    ```shell
    curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
    ````

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
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"\
      --form 'position[position_type]=text'\
      --form 'position[base_sha]=<use base_commit_sha from the versions response>'\
      --form 'position[head_sha]=<use head_commit_sha from the versions response>'\
      --form 'position[start_sha]=<use start_commit_sha from the versions response>'\
      --form 'position[new_path]=file.js'\
      --form 'position[old_path]=file.js'\
      --form 'position[new_line]=18'\
      --form 'body=test comment body'\
      "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
    ```

#### Parameters for multiline comments

Parameters for multiline comments only:

| Attribute                                | Type           | Required | Description |
| ---------------------------------------- | -------------- | -------- | ----------- |
| `position[line_range][start]`            | hash           | no       | Multiline note starting line |
| `position[line_range][start][line_code]` | string         | yes      | [Line code](#line-code) for the start line |
| `position[line_range][start][type]`      | string         | yes      | Use `new` for lines added by this commit, otherwise `old`. |
| `position[line_range][end]`              | hash           | no       | Multiline note ending line |
| `position[line_range][end][line_code]`   | string         | yes      | [Line code](#line-code) for the end line |
| `position[line_range][end][type]`        | string         | yes      | Use `new` for lines added by this commit, otherwise `old`. |

#### Line code

A line code is of the form `<SHA>_<old>_<new>`:

- `<SHA>` is the SHA1 hash of the filename.
- `<old>` is the line number before the change.
- `<new>` is the line number after the change.

For example, when commenting on an added line number 5, the line code
looks like `adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`.

### Resolve a merge request thread

Resolve/unresolve whole thread of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `resolved`          | boolean        | yes      | Resolve/unresolve the discussion |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7?resolved=true"
```

### Add note to existing merge request thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | yes      | The content of the note/reply |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment"
```

### Modify an existing merge request thread note

Modify or resolve an existing thread note of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | no       | The content of the note/reply (exactly one of `body` or `resolved` must be set |
| `resolved`          | boolean        | no       | Resolve/unresolve the note (exactly one of `body` or `resolved` must be set |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment"
```

Resolving a note:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?resolved=true"
```

### Delete a merge request thread note

Deletes an existing thread note of a merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/636"
```

## Commits

### List project commit discussion items

Gets a list of all discussion items for a single commit.

```plaintext
GET /projects/:id/commits/:commit_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`         | integer          | yes        | The ID of a commit |

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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions"
```

### Get single commit discussion item

Returns a single discussion item for a specific project commit

```plaintext
GET /projects/:id/commits/:commit_id/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a discussion item |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7"
```

### Create new commit thread

Creates a new thread to a single project commit. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/commits/:commit_id/discussions
```

Parameters:

| Attribute                 | Type           | Required | Description |
| ------------------------- | -------------- | -------- | ----------- |
| `id`                      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`               | integer        | yes      | The ID of a commit |
| `body`                    | string         | yes      | The content of the thread |
| `created_at`              | string         | no       | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |
| `position`                | hash           | no       | Position when creating a diff note |
| `position[base_sha]`      | string         | yes      | Base commit SHA in the source branch |
| `position[start_sha]`     | string         | yes      | SHA referencing commit in target branch |
| `position[head_sha]`      | string         | yes      | SHA referencing HEAD of this commit |
| `position[position_type]` | string         | yes      | Type of the position reference', allowed values: `text` or `image` |
| `position[new_path]`      | string         | no       | File path after change |
| `position[new_line]`      | integer        | no       | Line number after change |
| `position[old_path]`      | string         | no       | File path before change |
| `position[old_line]`      | integer        | no       | Line number before change |
| `position[width]`         | integer        | no       | Width of the image (for `image` diff notes) |
| `position[height]`        | integer        | no       | Height of the image (for `image` diff notes) |
| `position[x]`             | integer        | no       | X coordinate (for `image` diff notes) |
| `position[y]`             | integer        | no       | Y coordinate (for `image` diff notes) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions?body=comment"
```

### Add note to existing commit thread

Adds a new note to the thread.

```plaintext
POST /projects/:id/commits/:commit_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | yes      | The content of the note/reply |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, such `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify an existing commit thread note

Modify or resolve an existing thread note of a commit.

```plaintext
PUT /projects/:id/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | no       | The content of a note |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment"
```

Resolving a note:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?resolved=true"
```

### Delete a commit thread note

Deletes an existing thread note of a commit.

```plaintext
DELETE /projects/:id/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/636"
```
