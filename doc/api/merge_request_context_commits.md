# Merge request context commits  API

## List MR context commits

Get a list of merge request context commits.

```
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
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
        "author_name": "Luke \"Jared\" Bennett",
        "author_email": "lbennett@gitlab.com",
        "authored_date": "2017-04-11T10:08:59.000Z",
        "committer_name": "Luke \"Jared\" Bennett",
        "committer_email": "lbennett@gitlab.com",
        "committed_date": "2017-04-11T10:08:59.000Z"
    }
]
```

## Create MR context commits

Create a list of merge request context commits.

```
POST /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

```
POST /projects/:id/merge_requests/
```

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `commits`             | string array | yes | The context commits' sha  |

```json
[
    {
        "id": "6d394385cf567f80a8fd85055db1ab4c5295806f",
        "message": "Added contributing guide\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n",
        "parent_ids": [
            "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
        ],
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "author_name": "Dmitriy Zaporozhets",
        "author_email": "dmitriy.zaporozhets@gmail.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Dmitriy Zaporozhets",
        "committer_email": "dmitriy.zaporozhets@gmail.com"
    }
]
```

## Delete MR context commits

Delete a list of merge request context commits.

```
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `merge_request_iid` (required) - The internal ID of the merge request

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `commits`             | string array | yes | The context commits' sha  |
