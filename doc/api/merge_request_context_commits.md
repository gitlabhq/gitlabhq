---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Merge request context commits API **(FREE)**

## List MR context commits

Get a list of merge request context commits.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```json
[
    {
        "id": "4a24d82dbca5c11c61556f3b35ca472b7463187e",
        "short_id": "4a24d82d",
        "created_at": "2017-04-11T10:08:59.000Z",
        "parent_ids": null,
        "title": "Update README.md to include `Usage in testing and development`",
        "message": "Update README.md to include `Usage in testing and development`",
        "author_name": "Example \"Sample\" User",
        "author_email": "user@example.com",
        "authored_date": "2017-04-11T10:08:59.000Z",
        "committer_name": "Example \"Sample\" User",
        "committer_email": "user@example.com",
        "committed_date": "2017-04-11T10:08:59.000Z"
    }
]
```

## Create MR context commits

Create a list of merge request context commits.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```plaintext
POST /projects/:id/merge_requests/
```

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `commits`             | string array | yes | The context commits' SHA  |

```json
[
    {
        "id": "6d394385cf567f80a8fd85055db1ab4c5295806f",
        "message": "Added contributing guide\n\nSigned-off-by: Example User <user@example.com>\n",
        "parent_ids": [
            "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
        ],
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "author_name": "Example User",
        "author_email": "user@example.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Example User",
        "committer_email": "user@example.com"
    }
]
```

## Delete MR context commits

Delete a list of merge request context commits.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `commits`             | string array | yes | The context commits' SHA  |
