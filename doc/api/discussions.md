# Discussions API

Discussions are a set of related notes on:

- Snippets
- Issues
- Epics **(ULTIMATE)**
- Merge requests
- Commits

This includes system notes, which are notes about changes to the object (for example, when a milestone changes, there will be a corresponding system note). Label notes are not part of this API, but recorded as separate events in [resource label events](resource_label_events.md).

## Discussions pagination

By default, `GET` requests return 20 results at a time because the API results are paginated.

Read more on [pagination](README.md#pagination).

## Issues

### List project issue discussion items

Gets a list of all discussion items for a single issue.

```
GET /projects/:id/issues/:issue_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
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

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions
```

### Get single issue discussion item

Returns a single discussion item for a specific project issue

```
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new issue thread

Creates a new thread to a single project issue. This is similar to creating a note but other comments (replies) can be added to it later.

```
POST /projects/:id/issues/:issue_iid/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `body`          | string         | yes      | The content of the thread |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment
```

### Add note to existing issue thread

Adds a new note to the thread. This can also [create a thread from a single comment](../user/discussions/#start-a-thread-by-replying-to-a-standard-comment).

**WARNING**
Notes can be added to other items than comments (system notes, etc.) making them threads. 

```
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify existing issue thread note

Modify existing thread note of an issue.

```
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

### Delete an issue thread note

Deletes an existing thread note of an issue.

```
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/636
```

## Snippets

### List project snippet discussion items

Gets a list of all discussion items for a single snippet.

```
GET /projects/:id/snippets/:snippet_id/discussions
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
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
        "noteable_id": null
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
        "noteable_id": null,
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
        "noteable_id": null,
        "resolvable": false
      }
    ]
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions
```

### Get single snippet discussion item

Returns a single discussion item for a specific project snippet

```
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new snippet thread

Creates a new thread to a single project snippet. This is similar to creating
a note but other comments (replies) can be added to it later.

```
POST /projects/:id/snippets/:snippet_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment
```

### Add note to existing snippet thread

Adds a new note to the thread.

```
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify existing snippet thread note

Modify existing thread note of a snippet.

```
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

### Delete a snippet thread note

Deletes an existing thread note of a snippet.

```
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/636
```

## Epics **(ULTIMATE)**

### List group epic discussion items

Gets a list of all discussion items for a single epic.

```
GET /groups/:id/epics/:epic_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
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
        "noteable_id": null,
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
        "noteable_id": null,
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
        "noteable_id": null,
        "resolvable": false
      }
    ]
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions
```

### Get single epic discussion item

Returns a single discussion item for a specific group epic

```
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a discussion item |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new epic thread

Creates a new thread to a single group epic. This is similar to creating
a note but but other comments (replies) can be added to it later.

```
POST /groups/:id/epics/:epic_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `body`          | string         | yes      | The content of the thread |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment
```

### Add note to existing epic thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/#start-a-thread-by-replying-to-a-standard-comment).

```
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of the note/reply |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify existing epic thread note

Modify existing thread note of an epic.

```
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |
| `body`          | string         | yes      | The content of note/reply |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

### Delete an epic thread note

Deletes an existing thread note of an epic.

```
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`       | integer        | yes      | The ID of an epic |
| `discussion_id` | integer        | yes      | The ID of a thread |
| `note_id`       | integer        | yes      | The ID of a thread note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/636
```

## Merge requests

### List project merge request discussion items

Gets a list of all discussion items for a single merge request.

```
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
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
        "resolved_by": null
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

Diff comments contain also position:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": DiffNote,
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
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions
```

### Get single merge request discussion item

Returns a single discussion item for a specific project merge request

```
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a discussion item |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new merge request thread

Creates a new thread to a single project merge request. This is similar to creating
a note but other comments (replies) can be added to it later.

```
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

Parameters:

| Attribute                 | Type           | Required | Description |
| ------------------------- | -------------- | -------- | ----------- |
| `id`                      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid`       | integer        | yes      | The IID of a merge request |
| `body`                    | string         | yes      | The content of the thread |
| `created_at`              | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |
| `position`                | hash           | no       | Position when creating a diff note |
| `position[base_sha]`      | string         | yes      | Base commit SHA in the source branch |
| `position[start_sha]`     | string         | yes      | SHA referencing commit in target branch |
| `position[head_sha]`      | string         | yes      | SHA referencing HEAD of this merge request |
| `position[position_type]` | string         | yes      | Type of the position reference', allowed values: 'text' or 'image' |
| `position[new_path]`      | string         | no       | File path after change |
| `position[new_line]`      | integer        | no       | Line number after change (for 'text' diff notes) |
| `position[old_path]`      | string         | no       | File path before change |
| `position[old_line]`      | integer        | no       | Line number before change (for 'text' diff notes) |
| `position[width]`         | integer        | no       | Width of the image (for 'image' diff notes) |
| `position[height]`        | integer        | no       | Height of the image (for 'image' diff notes) |
| `position[x]`             | integer        | no       | X coordinate (for 'image' diff notes) |
| `position[y]`             | integer        | no       | Y coordinate (for 'image' diff notes) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment
```

### Resolve a merge request thread

Resolve/unresolve whole thread of a merge request.

```
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `resolved`          | boolean        | yes      | Resolve/unresolve the discussion |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7?resolved=true
```

### Add note to existing merge request thread

Adds a new note to the thread. This can also
[create a thread from a single comment](../user/discussions/#start-a-thread-by-replying-to-a-standard-comment).

```
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | yes      | The content of the note/reply |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify an existing merge request thread note

Modify or resolve an existing thread note of a merge request.

```
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | no       | The content of the note/reply (exactly one of `body` or `resolved` must be set |
| `resolved`          | boolean        | no       | Resolve/unresolve the note (exactly one of `body` or `resolved` must be set |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

Resolving a note:

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?resolved=true
```

### Delete a merge request thread note

Deletes an existing thread note of a merge request.

```
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a merge request |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/636
```

## Commits

### List project commit discussion items

Gets a list of all discussion items for a single commit.

```
GET /projects/:id/commits/:commit_id/discussions
```

| Attribute           | Type             | Required   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
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
        "type": DiffNote,
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

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions
```

### Get single commit discussion item

Returns a single discussion item for a specific project commit

```
GET /projects/:id/commits/:commit_id/discussions/:discussion_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a discussion item |

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new commit thread

Creates a new thread to a single project commit. This is similar to creating
a note but other comments (replies) can be added to it later.

```
POST /projects/:id/commits/:commit_id/discussions
```

Parameters:

| Attribute                 | Type           | Required | Description |
| ------------------------- | -------------- | -------- | ----------- |
| `id`                      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `commit_id`               | integer        | yes      | The ID of a commit |
| `body`                    | string         | yes      | The content of the thread |
| `created_at`              | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |
| `position`                | hash           | no       | Position when creating a diff note |
| `position[base_sha]`      | string         | yes      | Base commit SHA in the source branch |
| `position[start_sha]`     | string         | yes      | SHA referencing commit in target branch |
| `position[head_sha]`      | string         | yes      | SHA referencing HEAD of this commit |
| `position[position_type]` | string         | yes      | Type of the position reference', allowed values: 'text' or 'image' |
| `position[new_path]`      | string         | no       | File path after change |
| `position[new_line]`      | integer        | no       | Line number after change |
| `position[old_path]`      | string         | no       | File path before change |
| `position[old_line]`      | integer        | no       | Line number before change |
| `position[width]`         | integer        | no       | Width of the image (for 'image' diff notes) |
| `position[height]`        | integer        | no       | Height of the image (for 'image' diff notes) |
| `position[x]`             | integer        | no       | X coordinate (for 'image' diff notes) |
| `position[y]`             | integer        | no       | Y coordinate (for 'image' diff notes) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions?body=comment
```

### Add note to existing commit thread

Adds a new note to the thread.

```
POST /projects/:id/commits/:commit_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | yes      | The content of the note/reply |
| `created_at`        | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z (requires admin or project/group owner rights) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify an existing commit thread note

Modify or resolve an existing thread note of a commit.

```
PUT /projects/:id/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |
| `body`              | string         | no       | The content of a note |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

Resolving a note:

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?resolved=true
```

### Delete a commit thread note

Deletes an existing thread note of a commit.

```
DELETE /projects/:id/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `commit_id`         | integer        | yes      | The ID of a commit |
| `discussion_id`     | integer        | yes      | The ID of a thread |
| `note_id`           | integer        | yes      | The ID of a thread note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/commits/11/discussions/636
```
