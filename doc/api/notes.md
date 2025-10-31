---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Notes API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage comments and system records attached to GitLab content. You can:

- Create and modify comments on issues, merge requests, epics, snippets, and commits.
- Retrieve [system-generated notes](../user/project/system_notes.md) about object changes.
- Sort and paginate results.
- Control visibility with confidential and internal flags.
- Prevent abuse with rate limiting.

Some system-generated notes are tracked as separate resource events:

- [Resource label events](resource_label_events.md)
- [Resource state events](resource_state_events.md)
- [Resource milestone events](resource_milestone_events.md)
- [Resource weight events](resource_weight_events.md)
- [Resource iteration events](resource_iteration_events.md)

By default, `GET` requests return 20 results at a time, because the API results are paginated.
For more information, see [Pagination](rest/_index.md#pagination).

## Resource events

Some system notes are not part of this API, but are recorded as separate events:

- [Resource label events](resource_label_events.md)
- [Resource state events](resource_state_events.md)
- [Resource milestone events](resource_milestone_events.md)
- [Resource weight events](resource_weight_events.md)
- [Resource iteration events](resource_iteration_events.md)

## Notes pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](rest/_index.md#pagination).

## Rate limits

To help avoid abuse, you can limit your users to a specific number of `Create` request per minute.
See [Notes rate limits](../administration/settings/rate_limit_on_notes_creation.md).

## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
GET /projects/:id/issues/:issue_iid/notes?activity_filter=only_comments
```

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid` | integer           | yes      | The IID of an issue |
| `activity_filter` | string      | no       | Filter notes by activity type. Valid values: `all_notes`, `only_comments`, `only_activity`. Default is `all_notes` |
| `sort`      | string            | no       | Return issue notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by`  | string            | no       | Return issue notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```json
[
  {
    "id": 302,
    "body": "closed",
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
    "internal": false,
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
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
    "internal": true,
    "imported": false,
    "imported_from": "none"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes"
```

### Get single issue note

Returns a single note for a specific project issue

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid` | integer           | yes      | The IID of a project issue |
| `note_id`   | integer           | yes      | The ID of an issue note |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### Create new issue note

Creates a new note to a single project issue.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`    | integer           | yes      | The IID of an issue. |
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `confidential` | boolean           | no       | **Deprecated**: Scheduled to be removed in GitLab 16.0 and renamed to `internal`. The confidential flag of a note. Default is false. |
| `internal`     | boolean           | no       | The internal flag of a note. Overrides `confidential` when both parameters are submitted. Default is false. |
| `created_at`   | string            | no       | Date time string, ISO 8601 formatted. It must be after 1970-01-01. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### Modify existing issue note

Modify existing note of an issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`    | integer           | yes      | The IID of an issue. |
| `note_id`      | integer           | yes      | The ID of a note. |
| `body`         | string            | no       | The content of a note. Limited to 1,000,000 characters. |
| `confidential` | boolean           | no       | **Deprecated**: Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636?body=note"
```

### Delete an issue note

Deletes an existing note of an issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

Parameters:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid` | integer           | yes      | The IID of an issue |
| `note_id`   | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636"
```

## Snippets

The Snippets Notes API is intended for project-level snippets, and not for personal snippets.

### List all snippet notes

Gets a list of all notes for a single snippet. Snippet notes are comments users can post to a snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `snippet_id` | integer           | yes      | The ID of a project snippet |
| `sort`       | string            | no       | Return snippet notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by`   | string            | no       | Return snippet notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes"
```

### Get single snippet note

Returns a single note for a given snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `snippet_id` | integer           | yes      | The ID of a project snippet |
| `note_id`    | integer           | yes      | The ID of a snippet note |

```json
{
  "id": 302,
  "body": "closed",
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
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11"
```

### Create new snippet note

Creates a new note for a single snippet. Snippet notes are user comments on snippets.
If you create a note where the body only contains an emoji reaction, GitLab returns this object.

```plaintext
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `snippet_id` | integer           | yes      | The ID of a snippet |
| `body`       | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `created_at` | string            | no       | Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### Modify existing snippet note

Modify existing note of a snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `snippet_id` | integer           | yes      | The ID of a snippet |
| `note_id`    | integer           | yes      | The ID of a snippet note |
| `body`       | string            | yes      | The content of a note. Limited to 1,000,000 characters. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/1659?body=note"
```

### Delete a snippet note

Deletes an existing note of a snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `snippet_id` | integer           | yes      | The ID of a snippet |
| `note_id`    | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## Merge requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request |
| `sort`              | string            | no       | Return merge request notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by`          | string            | no       | Return merge request notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes"
```

### Get single merge request note

Returns a single note for a given merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request |
| `note_id`           | integer           | yes      | The ID of a merge request note |

```json
{
  "id": 301,
  "body": "Comment for MR",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### Create new merge request note

Creates a new note for a single merge request. Notes are not attached to specific
lines in a merge request. For other approaches with more granular control, see
[Post comment to commit](commits.md#post-comment-to-commit) in the Commits API,
and [Create a new thread in the merge request diff](discussions.md#create-a-new-thread-in-the-merge-request-diff)
in the Discussions API.

If you create a note where the body only contains an emoji reaction, GitLab returns this object.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

Parameters:

| Attribute                     | Type              | Required | Description |
|-------------------------------|-------------------|----------|-------------|
| `body`                        | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `id`                          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | integer           | yes      | The IID of a project merge request |
| `created_at`                  | string            | no       | Date time string, ISO 8601 formatted. Example: `2016-03-11T03:45:40Z` (requires administrator or project/group owner rights) |
| `internal`                    | boolean           | no       | The internal flag of a note. Default is false. |
| `merge_request_diff_head_sha` | string            | no       | Required for the `/merge` [quick action](../user/project/quick_actions.md). The SHA of the head commit, which ensures the merge request wasn't updated after the API request was sent. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note"
```

### Modify existing merge request note

Modify existing note of a merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request |
| `note_id`           | integer           | no       | The ID of a note |
| `body`              | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `confidential`      | boolean           | no       | **Deprecated**: Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1?body=note"
```

### Delete a merge request note

Deletes an existing note of a merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Parameters:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | integer           | yes      | The IID of a merge request |
| `note_id`           | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## Epics

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
and is planned for removal in v5 of the API.
From GitLab 17.4 to 18.0, if [the new look for epics](../user/group/epics/_index.md#epics-as-work-items) is enabled, and in GitLab 18.1 and later, use the
Work Items API instead. For more information, see [migrate epic APIs to work items](graphql/epic_work_items_api_migration_guide.md).
This change is a breaking change.

{{< /alert >}}

### List all epic notes

Gets a list of all notes for a single epic. Epic notes are comments users can post to an epic.

{{< alert type="note" >}}

The epics notes API uses the epic ID instead of epic IID. If you use the epic's IID, GitLab returns either a 404
error or notes for the wrong epic. It's different from the [issue notes API](#issues) and
[merge requests notes API](#merge-requests).

{{< /alert >}}

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `epic_id`  | integer           | yes      | The ID of a group epic |
| `sort`     | string            | no       | Return epic notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by` | string            | no       | Return epic notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes"
```

### Get single epic note

Returns a single note for a given epic.

```plaintext
GET /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `epic_id` | integer           | yes      | The ID of an epic |
| `note_id` | integer           | yes      | The ID of a note |

```json
{
  "id": 302,
  "body": "Epic note",
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
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1"
```

### Create new epic note

Creates a new note for a single epic. Epic notes are comments users can post to an epic.
If you create a note where the body only contains an emoji reaction, GitLab returns this object.

```plaintext
POST /groups/:id/epics/:epic_id/notes
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `epic_id`      | integer           | yes      | The ID of an epic |
| `id`           | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `confidential` | boolean           | no       | **Deprecated**: Scheduled to be removed in GitLab 16.0 and is renamed to `internal`. The confidential flag of a note. Default is `false`. |
| `internal`     | boolean           | no       | The internal flag of a note. Overrides `confidential` when both parameters are submitted. Default is `false`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### Modify existing epic note

Modify existing note of an epic.

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `epic_id`      | integer           | yes      | The ID of an epic |
| `note_id`      | integer           | yes      | The ID of a note |
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `confidential` | boolean           | no       | **Deprecated**: Scheduled to be removed in GitLab 16.0. The confidential flag of a note. Default is false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1?body=note"
```

### Delete an epic note

Deletes an existing note of an epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `epic_id` | integer           | yes      | The ID of an epic |
| `note_id` | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```

## Project wikis

### List all project wiki notes

Gets a list of all notes for a project wiki page. Project wiki notes are comments users can post to a wiki page.

{{< alert type="note" >}}

The wiki page notes API uses the wiki page meta ID instead of wiki page slug. If you use the page's slug, GitLab returns a 404
error. You can retrieve the meta ID from the [project wikis API](wikis.md).

{{< /alert >}}

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `sort`     | string            | no       | Return wiki page notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by` | string            | no       | Return wiki page notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes"
```

### Get single wiki page note

Returns a single note for a given wiki page.

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id` | integer           | yes      | The ID of a note |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": 5,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

### Create new wiki page note

Creates a new note for a single wiki page. Wiki page notes are comments users can post to a wiki page.

```plaintext
POST /projects/:id/wiki_pages/:wiki_page_meta_id/notes
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes?body=note"
```

### Modify existing wiki page note

Modifies an existing note on a wiki page.

```plaintext
PUT /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id`      | integer           | yes      | The ID of a note |
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218?body=note"
```

### Delete a wiki page note

Deletes a note from a wiki page.

```plaintext
DELETE /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id` | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

## Group wikis

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### List all group wiki notes

Gets a list of all notes for a group wiki page. Group wiki notes are comments users can post to a wiki page.

{{< alert type="note" >}}

The wiki page notes API uses the wiki page meta ID instead of wiki page slug. If you use the page's slug, GitLab returns a 404
error. You can retrieve the meta ID from the [group wikis API](group_wikis.md).

{{< /alert >}}

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `sort`     | string            | no       | Return wiki page notes sorted in `asc` or `desc` order. Default is `desc` |
| `order_by` | string            | no       | Return wiki page notes ordered by `created_at` or `updated_at` fields. Default is `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes"
```

### Get single wiki page note

Returns a single note for a given wiki page.

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id` | integer           | yes      | The ID of a note |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": null,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```

### Create new wiki page note

Creates a new note for a single wiki page. Wiki page notes are comments users can post to a wiki page.

```plaintext
POST /groups/:id/wiki_pages/:wiki_page_meta_id/notes
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `id`           | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes?body=note"
```

### Modify existing wiki page note

Modifies an existing note on a wiki page.

```plaintext
PUT /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id`      | integer           | yes      | The ID of a note |
| `body`         | string            | yes      | The content of a note. Limited to 1,000,000 characters. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218?body=note"
```

### Delete a wiki page note

Deletes a note from a wiki page.

```plaintext
DELETE /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Parameters:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `wiki_page_meta_id`  | integer           | yes      | The ID of a wiki page meta |
| `note_id` | integer           | yes      | The ID of a note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```
