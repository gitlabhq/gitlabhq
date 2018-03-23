# Discussions API

Discussions are set of related notes on snippets or issues.

## Issues

### List project issue discussions

Gets a list of all discussions for a single issue.

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
        "noteable_iid": null
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
        "noteable_iid": null
      }
    ]
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions
```

### Get single issue discussion

Returns a single discussion for a specific project issue

```
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion |

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new issue discussion

Creates a new discussion to a single project issue. This is similar to creating
a note but but another comments (replies) can be added to it later.

```
POST /projects/:id/issues/:issue_iid/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment
```

### Add note to existing issue discussion

Adds a new note to the discussion.

```
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify existing issue discussion note

Modify existing discussion note of an issue.

```
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid`     | integer        | yes      | The IID of an issue |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |
| `body`          | string         | yes      | The content of a discussion |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

### Delete an issue discussion note

Deletes an existing discussion note of an issue.

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
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/636
```

## Snippets

### List project snippet discussions

Gets a list of all discussions for a single snippet.

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
        "noteable_id": null
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
        "noteable_id": null
      }
    ]
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions
```

### Get single snippet discussion

Returns a single discussion for a specific project snippet

```
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7
```

### Create new snippet discussion

Creates a new discussion to a single project snippet. This is similar to creating
a note but but another comments (replies) can be added to it later.

```
POST /projects/:id/snippets/:snippet_id/discussions
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment
```

### Add note to existing snippet discussion

Adds a new note to the discussion.

```
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |
| `body`          | string         | yes      | The content of a discussion |
| `created_at`    | string         | no       | Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes?body=comment
```

### Modify existing snippet discussion note

Modify existing discussion note of an snippet.

```
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id`    | integer        | yes      | The ID of an snippet |
| `discussion_id` | integer        | yes      | The ID of a discussion |
| `note_id`       | integer        | yes      | The ID of a discussion note |
| `body`          | string         | yes      | The content of a discussion |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/6a9c1750b37d513a43987b574953fceb50b03ce7/notes/1108?body=comment
```

### Delete an snippet discussion note

Deletes an existing discussion note of an snippet.

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
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/636
```
