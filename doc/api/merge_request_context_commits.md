---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for merge request context commits in GitLab."
title: Merge request context commits API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If your merge request builds upon a previous merge request, you might
need to [include previously-merged commits for context](../user/project/merge_requests/commits.md#show-commits-from-previous-merge-requests).
Use this API to add commits to a merge request for more context.

## List MR context commits

Get a list of merge request context commits.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

| Attribute           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | integer | Yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer | Yes | The internal ID of the merge request. |

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

| Attribute           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | integer | Yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)  |
| `merge_request_iid` | integer | Yes | The internal ID of the merge request. |
| `commits`           | string array | Yes | The context commits' SHAs. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"commits": ["51856a574ac3302a95f82483d6c7396b1e0783cb"]}' \
  --url "https://gitlab.example.com/api/v4/projects/15/merge_requests/12/context_commits"
```

Example response:

```json
[
    {
        "id": "51856a574ac3302a95f82483d6c7396b1e0783cb",
        "short_id": "51856a57",
        "created_at": "2014-02-27T10:05:10.000+02:00",
        "parent_ids": [
            "57a82e2180507c9e12880c0747f0ea65ad489515"
        ],
        "title": "Commit title",
        "message": "Commit message",
        "author_name": "Example User",
        "author_email": "user@example.com",
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Example User",
        "committer_email": "user@example.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "trailers": {},
        "web_url": "https://gitlab.example.com/project/path/-/commit/b782f6c553653ab4e16469ff34bf3a81638ac304"
    }
]
```

## Delete MR context commits

Delete a list of merge request context commits.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

Parameters:

| Attribute           | Type         | Required | Description  |
|---------------------|--------------|----------|--------------|
| `commits`           | string array | Yes | The context commits' SHA. |
| `id`                | integer      | Yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer      | Yes | The internal ID of the merge request. |
