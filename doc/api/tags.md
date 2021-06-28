---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Tags API **(FREE)**

## List project repository tags

Get a list of repository tags from a project, sorted by name in reverse
alphabetical order. This endpoint can be accessed without authentication if the
repository is publicly accessible.

```plaintext
GET /projects/:id/repository/tags
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string| yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user|
| `order_by` | string | no | Return tags ordered by `name` or `updated` fields. Default is `updated` |
| `sort` | string | no | Return tags sorted in `asc` or `desc` order. Default is `desc` |
| `search` | string | no | Return list of tags matching the search criteria. You can use `^term` and `term$` to find tags that begin and end with `term` respectively. |

> Support for `search` was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/54401) in GitLab 11.8.

```json
[
  {
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "short_id": "2695effb",
      "title": "Initial commit",
      "created_at": "2017-07-26T11:08:53.000+02:00",
      "parent_ids": [
        "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
      ],
      "message": "Initial commit",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committer_name": "Jack Smith",
      "committer_email": "jack@example.com",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "release": {
      "tag_name": "1.0.0",
      "description": "Amazing release. Wow"
    },
    "name": "v1.0.0",
    "target": "2695effb5807a22ff3d138d593fd856244e155e7",
    "message": null,
    "protected": true
  }
]
```

## Get a single repository tag

Get a specific repository tag determined by its name. This endpoint can be
accessed without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `tag_name` | string | yes | The name of the tag |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
```

Example Response:

```json
{
  "name": "v5.0.0",
  "message": null,
  "target": "60a8ff033665e1207714d6670fcd7b65304ec02f",
  "commit": {
    "id": "60a8ff033665e1207714d6670fcd7b65304ec02f",
    "short_id": "60a8ff03",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "f61c062ff8bcbdb00e0a1b3317a91aed6ceee06b"
    ],
    "message": "v5.0.0\n",
    "author_name": "Arthur Verschaeve",
    "author_email": "contact@arthurverschaeve.be",
    "authored_date": "2015-02-01T21:56:31.000+01:00",
    "committer_name": "Arthur Verschaeve",
    "committer_email": "contact@arthurverschaeve.be",
    "committed_date": "2015-02-01T21:56:31.000+01:00"
  },
  "release": null,
  "protected": false
}
```

## Create a new tag

Creates a new tag in the repository that points to the supplied ref.

```plaintext
POST /projects/:id/repository/tags
```

Parameters:

| Attribute             | Type           | Required | Description                                                                                                     |
| --------------------- | -------------- | -------- | --------------------------------------------------------------------------------------------------------------- |
| `id`                  | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `tag_name`            | string         | yes      | The name of a tag                                                                                               |
| `ref`                 | string         | yes      | Create tag using commit SHA, another tag name, or branch name                                                   |
| `message`             | string         | no       | Creates annotated tag                                                                                           |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=master"
```

Example response:

```json
{
  "commit": {
    "id": "2695effb5807a22ff3d138d593fd856244e155e7",
    "short_id": "2695effb",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
    ],
    "message": "Initial commit",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-05-28T04:42:42-07:00",
    "committer_name": "Jack Smith",
    "committer_email": "jack@example.com",
    "committed_date": "2012-05-28T04:42:42-07:00"
  },
  "release": null,
  "name": "v1.0.0",
  "target": "2695effb5807a22ff3d138d593fd856244e155e7",
  "message": null,
  "protected": false
}
```

The message is `null` when creating a lightweight tag. Otherwise, it contains the annotation.

The target contains the tag objects ID when creating annotated tags,
otherwise it contains the commit ID when creating lightweight tags.

In case of an error,
status code `405` with an explaining error message is returned.

## Delete a tag

Deletes a tag of a repository with given name.

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

Parameters:

| Attribute  | Type           | Required | Description                                                                                                     |
| ---------- | -------------- | -------- | --------------------------------------------------------------------------------------------------------------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `tag_name` | string         | yes      | The name of a tag                                                                                               |
