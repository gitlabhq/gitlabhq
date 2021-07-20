---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Notes API **(FREE)**

Notes are comments on:

- Snippets
- Issues
- Merge requests
- Epics **(PREMIUM)**

This includes system notes, which are notes about changes to the object (for example, when an
assignee changes, GitLab posts a system note).

## Resource events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38096) in GitLab 13.3 for state, milestone, and weight events.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40850) in GitLab 13.4 for iteration events.

Some system notes are not part of this API, but are recorded as separate events:

- [Resource label events](resource_label_events.md)
- [Resource state events](resource_state_events.md)
- [Resource milestone events](resource_milestone_events.md)
- [Resource weight events](resource_weight_events.md)
- [Resource iteration events](resource_iteration_events.md)

## Notes pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

## Rate limits

To help avoid abuse, you can limit your users to a specific number of `Create` request per minute.
See [Notes rate limits](../user/admin_area/settings/rate_limit_on_notes_creation.md).

## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
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
    "resolvable": false,
    "confidential": false
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
    "resolvable": false,
    "confidential": true
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes"
```

### Get single issue note

Returns a single note for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `issue_iid` (required) - The IID of a project issue
- `note_id` (required) - The ID of an issue note

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### Create new issue note

Creates a new note to a single project issue.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `issue_iid` (required) - The IID of an issue
- `body` (required) - The content of a note. Limited to 1,000,000 characters.
- `confidential` (optional) - The confidential flag of a note. Default is false.
- `created_at` (optional) - Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights)

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### Modify existing issue note

Modify existing note of an issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).
- `issue_iid` (required) - The IID of an issue.
- `note_id` (required) - The ID of a note.
- `body` (optional) - The content of a note. Limited to 1,000,000 characters.
- `confidential` (optional) - The confidential flag of a note.

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### Delete an issue note

Deletes an existing note of an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `issue_iid` | integer | yes | The IID of an issue |
| `note_id` | integer | yes | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636"
```

## Snippets

The Snippets Notes API is intended for project-level snippets, and not for personal snippets.

### List all snippet notes

Gets a list of all notes for a single snippet. Snippet notes are comments users can post to a snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
| `snippet_id`        | integer          | yes        | The ID of a project snippet
| `sort`              | string           | no         | Return snippet notes sorted in `asc` or `desc` order. Default is `desc`
| `order_by`          | string           | no         | Return snippet notes ordered by `created_at` or `updated_at` fields. Default is `created_at`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes"
```

### Get single snippet note

Returns a single note for a given snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
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

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11"
```

### Create new snippet note

Creates a new note for a single snippet. Snippet notes are user comments on snippets.
If you create a note where the body only contains an Award Emoji, GitLab returns this object.

```plaintext
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `snippet_id` (required) - The ID of a snippet
- `body` (required) - The content of a note. Limited to 1,000,000 characters.
- `created_at` (optional) - Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights)

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### Modify existing snippet note

Modify existing note of a snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `snippet_id` (required) - The ID of a snippet
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note. Limited to 1,000,000 characters.

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes?body=note"
```

### Delete a snippet note

Deletes an existing note of a snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `snippet_id` | integer | yes | The ID of a snippet |
| `note_id` | integer | yes | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## Merge Requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
| `merge_request_iid` | integer          | yes        | The IID of a project merge request
| `sort`              | string           | no         | Return merge request notes sorted in `asc` or `desc` order. Default is `desc`
| `order_by`          | string           | no         | Return merge request notes ordered by `created_at` or `updated_at` fields. Default is `created_at`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes"
```

### Get single merge request note

Returns a single note for a given merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
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
  "resolvable": false,
  "confidential": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### Create new merge request note

Creates a new note for a single merge request.
If you create a note where the body only contains an Award Emoji, GitLab returns this object.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `merge_request_iid` (required) - The IID of a merge request
- `body` (required) - The content of a note. Limited to 1,000,000 characters.
- `created_at` (optional) - Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights)

### Modify existing merge request note

Modify existing note of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding)
- `merge_request_iid` (required) - The IID of a merge request
- `note_id` (required) - The ID of a note
- `body` (required) - The content of a note. Limited to 1,000,000 characters.

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note"
```

### Delete a merge request note

Deletes an existing note of a merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes | The IID of a merge request |
| `note_id` | integer | yes | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## Epics **(ULTIMATE)**

### List all epic notes

Gets a list of all notes for a single epic. Epic notes are comments users can post to an epic.

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ----------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id`           | integer          | yes        | The ID of a group epic |
| `sort`              | string           | no         | Return epic notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by`          | string           | no         | Return epic notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes"
```

### Get single epic note

Returns a single note for a given epic.

```plaintext
GET /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
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
  "created_at": "2013-10-02T07:34:20Z",
  "confidential": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1"
```

### Create new epic note

Creates a new note for a single epic. Epic notes are comments users can post to an epic.
If you create a note where the body only contains an Award Emoji, GitLab returns this object.

```plaintext
POST /groups/:id/epics/:epic_id/notes
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `body`    | string  | yes  | The content of a note. Limited to 1,000,000 characters. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### Modify existing epic note

Modify existing note of an epic.

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |
| `body`    | string  | yes  | The content of a note. Limited to 1,000,000 characters. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### Delete an epic note

Deletes an existing note of an epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```
