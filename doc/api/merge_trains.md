---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge Trains API **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36146) in GitLab 12.9.
> - Using this API you can consume [Merge Train](../ci/pipelines/merge_trains.md) entries.

Every API call to merge trains must be authenticated with Developer or higher [permissions](../user/permissions.md).

If a user is not a member of a project and the project is private, a `GET` request on that project returns a `404` status code.

If Merge Trains is not available for the project, a `403` status code is returned.

## Merge Trains API pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

## List Merge Trains for a project

Get all Merge Trains of the requested project:

```shell
GET /projects/:id/merge_trains
GET /projects/:id/merge_trains?scope=complete
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).                                            |
| `scope`             | string           | no         | Return Merge Trains filtered by the given scope. Available scopes are `active` (to be merged) and `complete` (have been merged). |
| `sort`              | string           | no         | Return Merge Trains sorted in `asc` or `desc` order. Default is `desc`.                                                     |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

Example response:

```json
[
  {
    "id": 110,
    "merge_request": {
      "id": 126,
      "iid": 59,
      "project_id": 20,
      "title": "Test MR 1580978354",
      "description": "",
      "state": "merged",
      "created_at": "2020-02-06T08:39:14.883Z",
      "updated_at": "2020-02-06T08:40:57.038Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59"
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://local.gitlab.test:8181/root"
    },
    "pipeline": {
      "id": 246,
      "sha": "bcc17a8ffd51be1afe45605e714085df28b80b13",
      "ref": "refs/merge-requests/59/train",
      "status": "success",
      "created_at": "2020-02-06T08:40:42.410Z",
      "updated_at": "2020-02-06T08:40:46.912Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/pipelines/246"
    },
    "created_at": "2020-02-06T08:39:47.217Z",
    "updated_at": "2020-02-06T08:40:57.720Z",
    "target_branch": "feature-1580973432",
    "status": "merged",
    "merged_at": "2020-02-06T08:40:57.719Z",
    "duration": 70
  }
]
```
