---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Notes API **(FREE)**

Notes are comments on:

- Snippets
- Issues
- Merge requests
- [Epics](../user/group/epics/index.md)

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

Read more on [pagination](rest/index.md#pagination).

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
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)
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
    "project_id": 5,
    "noteable_iid": 377,
    "resolvable": false,
    "confidential": false,
    "internal": false
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
    "project_id": 5,
    "noteable_iid": 121,
    "resolvable": false,
    "confidential": true,
    "internal": true
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

| Attribute   | Type           | Required | Description                                                                     |
|-------------|----------------|----------|---------------------------------------------------------------------------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `issue_iid` | integer        | yes      | The IID of a project issue                                                      |
| `note_id`   | integer        | yes      | The ID of an issue note                                                         |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### Create new issue note

Creates a new note to a single project issue.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Parameters:

| Attribute      | Type           | Required | Description                                                                                                                  |
|----------------|----------------|----------|------------------------------------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                           |
| `issue_iid`    | integer        | yes      | The IID of an issue.                                                                                                         |
| `body`         | string         | yes      | The content of a note. Limited to 1,000,000 characters.                                                                      |
| `confidential` | boolean        | no       | **Deprecated:** Scheduled to be removed in GitLab 16.0 and renamed to `internal`. The confidential flag of a note. Default is false.                                                                           |
| `internal`     | boolean        | no       | The internal flag of a note. Overrides `confidential` when both parameters are submitted. Default is false.                                                                               |
| `created_at`   | string         | no       | Date time string, ISO 8601 formatted. It must be after 1970-01-01. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### Modify existing issue note

Modify existing note of an issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute      | Type           | Required    | Description                                                                                        |
|----------------|----------------|-------------|----------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                    |
| `issue_iid`    | integer           | yes      | The IID of an issue.                                                                               |
| `note_id`      | integer           | yes      | The ID of a note.                                                                                  |
| `body`         | string            | no       | The content of a note. Limited to 1,000,000 characters.                                            |
| `confidential` | boolean           | no       | **Deprecated:** Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636?body=note"
```

### Delete an issue note

Deletes an existing note of an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
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
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)
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

| Attribute    | Type           | Required | Description                                                                     |
|--------------|----------------|----------|---------------------------------------------------------------------------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `snippet_id` | integer        | yes      | The ID of a project snippet                                                     |
| `note_id`    | integer        | yes      | The ID of a snippet note                                                        |

```json
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
  "project_id": 5,
  "noteable_iid": 377,
  "resolvable": false,
  "confidential": false,
  "internal": false
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

| Attribute    | Type           | Required | Description                                                                                                                  |
|--------------|----------------|----------|------------------------------------------------------------------------------------------------------------------------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)                                              |
| `snippet_id` | integer        | yes      | The ID of a snippet                                                                                                          |
| `body`       | string         | yes      | The content of a note. Limited to 1,000,000 characters.                                                                      |
| `created_at` | string         | no       | Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### Modify existing snippet note

Modify existing note of a snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute    | Type           | Required | Description                                                                                                                  |
|--------------|----------------|----------|------------------------------------------------------------------------------------------------------------------------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)                                              |
| `snippet_id` | integer        | yes      | The ID of a snippet                                                                                                          |
| `note_id`    | integer        | yes      | The ID of a snippet note                                                        |
| `body`       | string         | yes      | The content of a note. Limited to 1,000,000 characters.                                                                      |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/1659?body=note"
```

### Delete a snippet note

Deletes an existing note of a snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `snippet_id` | integer | yes | The ID of a snippet |
| `note_id` | integer | yes | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## Merge requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)
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

| Attribute           | Type           | Required | Description                                                                     |
|---------------------|----------------|----------|---------------------------------------------------------------------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer        | yes      | The IID of a project merge request                                              |
| `note_id`           | integer        | yes      | The ID of a merge request note                                                        |

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
  "project_id": 5,
  "noteable_iid": 2,
  "resolvable": false,
  "confidential": false,
  "internal": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### Create new merge request note

Creates a new note for a single merge request. Notes are not attached to specific
lines in a merge request. For other approaches with more granular control, see
[Post comment to commit](commits.md#post-comment-to-commit) in the Commits API,
and [Create a new thread in the merge request diff](discussions.md#create-a-new-thread-in-the-merge-request-diff)
in the Discussions API.

If you create a note where the body only contains an award emoji, GitLab returns this object.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

Parameters:

| Attribute           | Type           | Required | Description                                                                                                                  |
|---------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------------------|
| `id`                    | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)                                              |
| `merge_request_iid`     | integer        | yes      | The IID of a project merge request                                                                                           |
| `body`                  | string         | yes      | The content of a note. Limited to 1,000,000 characters.                                                                      |
| `created_at`            | string         | no       | Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |
| `merge_request_diff_head_sha`| string         | no       | Required for the `/merge` [quick action](../user/project/quick_actions.md). The SHA of the head commit, which ensures the merge request wasn't updated after the API request was sent. |

### Modify existing merge request note

Modify existing note of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute           | Type              | Required | Description                                                                                        |
|---------------------|-------------------|----------|----------------------------------------------------------------------------------------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)                     |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request                                                                 |
| `note_id`           | integer           | no       | The ID of a note                                                                                   |
| `body`              | string            | yes      | The content of a note. Limited to 1,000,000 characters.                                            |
| `confidential`      | boolean           | no       | **Deprecated:** Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1?body=note"
```

### Delete a merge request note

Deletes an existing note of a merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes | The IID of a merge request |
| `note_id` | integer | yes | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## Epics **(PREMIUM)**

### List all epic notes

Gets a list of all notes for a single epic. Epic notes are comments users can post to an epic.

NOTE:
The epics notes API uses the epic ID instead of epic IID. If you use the epic's IID, GitLab returns either a 404
error or notes for the wrong epic. It's different from the [issue notes API](#issues) and
[merge requests notes API](#merge-requests).

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type             | Required   | Description |
| ------------------- | ---------------- | ---------- | ----------- |
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
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
| `id`      | integer or string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |

```json
{
  "id": 302,
  "body": "Epic note",
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
  "noteable_id": 11,
  "noteable_type": "Epic",
  "project_id": 5,
  "noteable_iid": 11,
  "resolvable": false,
  "confidential": false,
  "internal": false
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

| Attribute      | Type           | Required | Description |
| ---------      | -------------- | -------- | ----------- |
| `body`         | string  | yes  | The content of a note. Limited to 1,000,000 characters. |
| `epic_id`      | integer | yes  | The ID of an epic |
| `id`           | integer or string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `confidential` | boolean        | no       | **Deprecated:** Scheduled to be removed in GitLab 16.0 and is renamed to `internal`. The confidential flag of a note. Default is `false`. |
| `internal`     | boolean        | no       | The internal flag of a note. Overrides `confidential` when both parameters are submitted. Default is `false`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### Modify existing epic note

Modify existing note of an epic.

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute      | Type              | Required | Description                                                                                        |
| ---------------| ----------------- | -------- | ---------------------------------------------------------------------------------------------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding)                       |
| `epic_id`      | integer           | yes      | The ID of an epic                                                                                  |
| `note_id`      | integer           | yes      | The ID of a note                                                                                   |
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters.                                            |
| `confidential` | boolean           | no       | **Deprecated:** Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1?body=note"
```

### Delete an epic note

Deletes an existing note of an epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `epic_id` | integer | yes  | The ID of an epic |
| `note_id` | integer | yes  | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```
