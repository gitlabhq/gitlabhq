# Notes

Notes are comments on snippets, issues or merge requests.

## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```
GET /projects/:id/issues/:issue_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of an issue

```json
[
  {
    "id": 302,
    "body": "Status changed to closed",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:22:45Z",
    "updated_at": "2013-10-02T10:22:45Z",
    "system": true,
    "upvote": false,
    "downvote": false,
    "noteable_id": 377,
    "noteable_type": "Issue"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:56:03Z",
    "updated_at": "2013-10-02T09:56:03Z",
    "system": true,
    "upvote": false,
    "downvote": false,
    "noteable_id": 121,
    "noteable_type": "Issue"
  }
]
```

### Get single issue note

Returns a single note for a specific project issue

```
GET /projects/:id/issues/:issue_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of a project issue
- `note_id` (required) - The ID of an issue note

### Create new issue note

Creates a new note to a single project issue. If you create a note where the body
only contains an Award Emoji, you'll receive this object back.

```
POST /projects/:id/issues/:issue_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of an issue
- `body` (required) - The content of a note
- `created_at` (optional) - Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z

### Modify existing issue note

Modify existing note of an issue.

```
PUT /projects/:id/issues/:issue_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of an issue
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

### Delete an issue note

Deletes an existing note of an issue. On success, this API method returns 200
and the deleted note. If the note does not exist, the API returns 404.

```
DELETE /projects/:id/issues/:issue_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `issue_id` | integer | yes | The ID of an issue |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/issues/11/notes/636
```

Example Response:

```json
{
  "id": 636,
  "body": "This is a good idea.",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/pipin"
  },
  "created_at": "2016-04-05T22:10:44.164Z",
  "system": false,
  "noteable_id": 11,
  "noteable_type": "Issue",
  "upvote": false,
  "downvote": false
}
```

## Snippets

### List all snippet notes

Gets a list of all notes for a single snippet. Snippet notes are comments users can post to a snippet.

```
GET /projects/:id/snippets/:snippet_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project snippet

### Get single snippet note

Returns a single note for a given snippet.

```
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project snippet
- `note_id` (required) - The ID of an snippet note

```json
{
  "id": 52,
  "title": "Snippet",
  "file_name": "snippet.rb",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "expires_at": null,
  "updated_at": "2013-10-02T07:34:20Z",
  "created_at": "2013-10-02T07:34:20Z"
}
```

### Create new snippet note

Creates a new note for a single snippet. Snippet notes are comments users can post to a snippet.
If you create a note where the body only contains an Award Emoji, you'll receive this object back.

```
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a snippet
- `body` (required) - The content of a note

### Modify existing snippet note

Modify existing note of a snippet.

```
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a snippet
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

### Delete a snippet note

Deletes an existing note of a snippet. On success, this API method returns 200
and the deleted note. If the note does not exist, the API returns 404.

```
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `snippet_id` | integer | yes | The ID of a snippet |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/snippets/52/notes/1659
```

Example Response:

```json
{
  "id": 1659,
  "body": "This is a good idea.",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/pipin"
  },
  "created_at": "2016-04-06T16:51:53.239Z",
  "system": false,
  "noteable_id": 52,
  "noteable_type": "Snippet",
  "upvote": false,
  "downvote": false
}
```

## Merge Requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```
GET /projects/:id/merge_requests/:merge_request_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `merge_request_id` (required) - The ID of a project merge request

### Get single merge request note

Returns a single note for a given merge request.

```
GET /projects/:id/merge_requests/:merge_request_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `merge_request_id` (required) - The ID of a project merge request
- `note_id` (required) - The ID of a merge request note

```json
{
  "id": 301,
  "body": "Comment for MR",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T08:57:14Z",
  "updated_at": "2013-10-02T08:57:14Z",
  "system": false,
  "upvote": false,
  "downvote": false,
  "noteable_id": 2,
  "noteable_type": "MergeRequest"
}
```

### Create new merge request note

Creates a new note for a single merge request.
If you create a note where the body only contains an Award Emoji, you'll receive
this object back.

```
POST /projects/:id/merge_requests/:merge_request_id/notes
```

Parameters:

- `id` (required) - The ID of a project
- `merge_request_id` (required) - The ID of a merge request
- `body` (required) - The content of a note

### Modify existing merge request note

Modify existing note of a merge request.

```
PUT /projects/:id/merge_requests/:merge_request_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID of a project
- `merge_request_id` (required) - The ID of a merge request
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

### Delete a merge request note

Deletes an existing note of a merge request. On success, this API method returns
200 and the deleted note. If the note does not exist, the API returns 404.

```
DELETE /projects/:id/merge_requests/:merge_request_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `merge_request_id` | integer | yes | The ID of a merge request |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/merge_requests/7/notes/1602
```

Example Response:

```json
{
  "id": 1602,
  "body": "This is a good idea.",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/u/pipin"
  },
  "created_at": "2016-04-05T22:11:59.923Z",
  "system": false,
  "noteable_id": 7,
  "noteable_type": "MergeRequest",
  "upvote": false,
  "downvote": false
}
```
