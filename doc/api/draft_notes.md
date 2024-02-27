---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Draft Notes API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Draft notes are pending, unpublished comments on merge requests. They can be either start a discussion, or be associated with an existing discussion as a reply. They are viewable only by the author until they are published.

## List all merge request draft notes

Gets a list of all draft notes for a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request |

```json
[{
  id: 5,
  author_id: 23,
  merge_request_id: 11,
  resolve_discussion: false,
  discussion_id: nil,
  note: "Example title",
  commit_id: nil,
  line_code: nil,
  position:
  {
    base_sha: nil,
    start_sha: nil,
    head_sha: nil,
    old_path: nil,
    new_path: nil,
    position_type: "text",
    old_line: nil,
    new_line: nil,
    line_range: nil
  }
}]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes"
```

## Get a single draft note

Returns a single draft note for a given merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `draft_note_id`     | integer           | yes      | The ID of a draft note. |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request. |

```json
{
  id: 5,
  author_id: 23,
  merge_request_id: 11,
  resolve_discussion: false,
  discussion_id: nil,
  note: "Example title",
  commit_id: nil,
  line_code: nil,
  position:
  {
    base_sha: nil,
    start_sha: nil,
    head_sha: nil,
    old_path: nil,
    new_path: nil,
    position_type: "text",
    old_line: nil,
    new_line: nil,
    line_range: nil
  }
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Create a draft note

Create a draft note for a given merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| Attribute                                | Type              | Required    | Description           |
| ---------------------------------------- | ----------------- | ----------- | --------------------- |
| `id`                                     | integer or string | yes         | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `merge_request_iid`                      | integer           | yes         | The IID of a project merge request. |
| `note`                                   | string            | yes         | The content of a note. |
| `commit_id`                              | string            | no          | The SHA of a commit to associate the draft note to. |
| `in_reply_to_discussion_id`              | string            | no          | The ID of a discussion the draft note replies to. |
| `resolve_discussion`                     | boolean           | no          | The associated discussion should be resolved. |
| `position[base_sha]`                     | string            | yes         | Base commit SHA in the source branch. |
| `position[head_sha]`                     | string            | yes         | SHA referencing HEAD of this merge request. |
| `position[start_sha]`                    | string            | yes         | SHA referencing commit in target branch. |
| `position[new_path]`                     | string            | yes (if the position type is `text`) | File path after change. |
| `position[old_path]`                     | string            | yes (if the position type is `text`) | File path before change. |
| `position[position_type]`                | string            | yes         | Type of the position reference. Allowed values: `text` or `image`. |
| `position`                               | hash              | no          | Position when creating a diff note. |
| `position[new_line]`                     | integer           | no          | For `text` diff notes, the line number after change. |
| `position[old_line]`                     | integer           | no          | For `text` diff notes, the line number before change. |
| `position[line_range]`                   | hash              | no          | Line range for a multi-line diff note. |
| `position[width]`                        | integer           | no          | For `image` diff notes, width of the image. |
| `position[height]`                       | integer           | no          | For `image` diff notes, height of the image. |
| `position[x]`                            | float             | no          | For `image` diff notes, X coordinate. |
| `position[y]`                            | float             | no          | For `image` diff notes, Y coordinate. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes?note=note"
```

## Modify existing draft note

Modify a draft note for a given merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribute                                | Type              | Required    | Description           |
| -------------------                      | ----------------- | ----------- | --------------------- |
| `id`                                     | integer or string | yes         | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `draft_note_id`                          | integer           | yes         | The ID of a draft note. |
| `merge_request_iid`                      | integer           | yes         | The IID of a project merge request. |
| `note`                                   | string            | no          | The content of a note. |
| `position[base_sha]`                     | string            | yes         | Base commit SHA in the source branch. |
| `position[head_sha]`                     | string            | yes         | SHA referencing HEAD of this merge request. |
| `position[start_sha]`                    | string            | yes         | SHA referencing commit in target branch. |
| `position[new_path]`                     | string            | yes (if the position type is `text`) | File path after change. |
| `position[old_path]`                     | string            | yes (if the position type is `text`) | File path before change. |
| `position[position_type]`                | string            | yes         | Type of the position reference. Allowed values: `text` or `image`. |
| `position`                               | hash              | no          | Position when creating a diff note. |
| `position[new_line]`                     | integer           | no          | For `text` diff notes, the line number after change. |
| `position[old_line]`                     | integer           | no          | For `text` diff notes, the line number before change. |
| `position[line_range]`                   | hash              | no          | Line range for a multi-line diff note. |
| `position[width]`                        | integer           | no          | For `image` diff notes, width of the image. |
| `position[height]`                       | integer           | no          | For `image` diff notes, height of the image. |
| `position[x]`                            | float             | no          | For `image` diff notes, X coordinate. |
| `position[y]`                            | float             | no          | For `image` diff notes, Y coordinate. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Delete a draft note

Deletes an existing draft note for a given merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| Attribute           | Type             | Required    | Description           |
| ------------------- | ---------------- | ----------- | --------------------- |
| `draft_note_id`     | integer           | yes        | The ID of a draft note. |
| `id`                | integer or string | yes        | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `merge_request_iid` | integer           | yes        | The IID of a project merge request. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## Publish a draft note

Publishes an existing draft note for a given merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id/publish
```

| Attribute           | Type             | Required    | Description           |
| ------------------- | ---------------- | ----------- | --------------------- |
| `draft_note_id`     | integer           | yes        | The ID of a draft note. |
| `id`                | integer or string | yes        | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `merge_request_iid` | integer           | yes        | The IID of a project merge request. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5/publish"
```

## Publish all pending draft notes

Bulk publishes all existing draft notes for a given merge request that belong to the user.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes/bulk_publish
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `merge_request_iid` | integer           | yes      | The IID of a project merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/bulk_publish"
```
