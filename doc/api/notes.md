# Notes API

Notes are comments on snippets, issues, merge requests or epics.

## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
| `issue_iid`         | integer          | yes        | The IID of an issue
| `sort`              | string           | no         | Return issue notes sorted in `asc` or `desc` order. Default is `desc`
| `order_by`          | string           | no         | Return issue notes ordered by `created_at` or `updated_at` fields. Default is `created_at`

```json
[
  {
    "id": 302,
    "body": "closed",
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
    "noteable_id": 377,
    "noteable_type": "Issue",
    "noteable_iid": 377,
    "resolvable": false
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
    "noteable_id": 121,
    "noteable_type": "Issue",
    "noteable_iid": 121,
    "resolvable": false
  }
]
```

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/notes
```

### Get single issue note

Returns a single note for a specific project issue

```
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `issue_iid` (required) - The IID of a project issue
- `note_id` (required) - The ID of an issue note

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1
```

### Create new issue note

Creates a new note to a single project issue.

```
POST /projects/:id/issues/:issue_iid/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `issue_id` (required) - The IID of an issue
- `body` (required) - The content of a note
- `created_at` (optional) - Date time string, ISO 8601 formatted, e.g. 2016-03-11T03:45:40Z

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note
```

### Modify existing issue note

Modify existing note of an issue.

```
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `issue_iid` (required) - The IID of an issue
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note
```

### Delete an issue note

Deletes an existing note of an issue.

```
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid` | integer | yes | The IID of an issue |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636
```

## Snippets

### List all snippet notes

Gets a list of all notes for a single snippet. Snippet notes are comments users can post to a snippet.

```
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
| `snippet_id`        | integer          | yes        | The ID of a project snippet
| `sort`              | string           | no         | Return snippet notes sorted in `asc` or `desc` order. Default is `desc`
| `order_by`          | string           | no         | Return snippet notes ordered by `created_at` or `updated_at` fields. Default is `created_at`

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/notes
```

### Get single snippet note

Returns a single note for a given snippet.

```
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `snippet_id` (required) - The ID of a project snippet
- `note_id` (required) - The ID of a snippet note

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

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11
```

### Create new snippet note

Creates a new note for a single snippet. Snippet notes are comments users can post to a snippet.
If you create a note where the body only contains an Award Emoji, you'll receive this object back.

```
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `snippet_id` (required) - The ID of a snippet
- `body` (required) - The content of a note

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note
```

### Modify existing snippet note

Modify existing note of a snippet.

```
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `snippet_id` (required) - The ID of a snippet
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/11/notes?body=note
```

### Delete a snippet note

Deletes an existing note of a snippet.

```
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `snippet_id` | integer | yes | The ID of a snippet |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659
```

## Merge Requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
| `merge_request_iid` | integer          | yes        | The IID of a project merge request
| `sort`              | string           | no         | Return merge request notes sorted in `asc` or `desc` order. Default is `desc`
| `order_by`          | string           | no         | Return merge request notes ordered by `created_at` or `updated_at` fields. Default is `created_at`

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes
```

### Get single merge request note

Returns a single note for a given merge request.

```
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `merge_request_iid` (required) - The IID of a project merge request
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
  "noteable_id": 2,
  "noteable_type": "MergeRequest",
  "noteable_iid": 2,
  "resolvable": false
}
```

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1
```

### Create new merge request note

Creates a new note for a single merge request.
If you create a note where the body only contains an Award Emoji, you'll receive
this object back.

```
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `merge_request_iid` (required) - The IID of a merge request
- `body` (required) - The content of a note

### Modify existing merge request note

Modify existing note of a merge request.

```
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding)
- `merge_request_iid` (required) - The IID of a merge request
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note
```

### Delete a merge request note

Deletes an existing note of a merge request.

```
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes | The IID of a merge request |
| `note_id` | integer | yes | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602
```

## Epics

### List all epic notes

Gets a list of all notes for a single epic. Epic notes are comments users can post to an epic.

```
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ----------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id`           | integer          | yes        | The ID of a group epic |
| `sort`              | string           | no         | Return epic notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by`          | string           | no         | Return epic notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/epics/11/notes
```

### Get single epic note

Returns a single note for a given epic.

```
GET /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |

```json
{
  "id": 52,
  "title": "Epic",
  "file_name": "epic.rb",
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

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1
```

### Create new epic note

Creates a new note for a single epic. Epic notes are comments users can post to an epic.
If you create a note where the body only contains an Award Emoji, you'll receive this object back.

```
POST /groups/:id/epics/:epic_id/notes
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `body`    | string  | yes  | The content of a note |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note
```

### Modify existing epic note

Modify existing note of an epic.

```
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |
| `body`    | string  | yes  | The content of a note |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note
```

### Delete an epic note

Deletes an existing note of an epic.

```
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659
```
