---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group Markdown uploads API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Markdown uploads are [files uploaded to a group](../security/user_file_uploads.md)
that can be referenced in Markdown text in an epic or a wiki page.

## List uploads

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

Get all uploads of the group sorted by `created_at` in descending order.

You must have at least the Maintainer role to use this endpoint.

```plaintext
GET /groups/:id/uploads
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/uploads"
```

Example response:

```json
[
  {
    "id": 1,
    "size": 1024,
    "filename": "image.png",
    "created_at":"2024-06-20T15:53:03.067Z",
    "uploaded_by": {
      "id": 18,
      "name" : "Alexandra Bashirian",
      "username" : "eileen.lowe"
    }
  },
  {
    "id": 2,
    "size": 512,
    "filename": "other-image.png",
    "created_at":"2024-06-19T15:53:03.067Z",
    "uploaded_by": null
  }
]
```

## Download an uploaded file by ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

You must have at least the Maintainer role to use this endpoint.

```plaintext
GET /groups/:id/uploads/:upload_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `upload_id` | integer           | Yes      | The ID of the upload. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the uploaded file in the response body.

## Download an uploaded file by secret and filename

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) in GitLab 17.4.

You must have at least the Guest role to use this endpoint.

```plaintext
GET /groups/:id/uploads/:secret/:filename
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `secret`    | string            | Yes      | The 32-character secret of the upload. |
| `filename`  | string            | Yes      | The filename of the upload. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the uploaded file in the response body.

## Delete an uploaded file by ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /groups/:id/uploads/:upload_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `upload_id` | integer           | Yes      | The ID of the upload. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

If successful, returns [`204`](rest/troubleshooting.md#status-codes) status code without any response body.

## Delete an uploaded file by secret and filename

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) in GitLab 17.4.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /groups/:id/uploads/:secret/:filename
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `secret`    | string            | Yes      | The 32-character secret of the upload. |
| `filename`  | string            | Yes      | The filename of the upload. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

If successful, returns [`204`](rest/troubleshooting.md#status-codes) status code without any response body.
