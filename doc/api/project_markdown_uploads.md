---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Markdown uploads API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Markdown uploads are [files uploaded to a project](../security/user_file_uploads.md) that can be referenced in Markdown
text in an issue, merge request, snippet, or wiki page.

## Upload a file

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450) in GitLab 15.10. Feature flag `enforce_max_attachment_size_upload_api` removed.
> - `full_path` response attribute pattern [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150939) in GitLab 17.1.
> - `id` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161160) in GitLab 17.3.

Uploads a file to the specified project to be used in an issue or merge request description, or a comment.

```plaintext
POST /projects/:id/uploads
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `file`    | string            | Yes      | File to be uploaded. |
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

To upload a file from your file system, use the `--form` argument. This causes cURL to post data using the
`Content-Type: multipart/form-data` header. The `file=` parameter must point to a file on your file system and be
preceded by `@`.

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Example response:

```json
{
  "id": 5,
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/-/project/1234/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

In the response, the:

- `full_path` is the absolute path to the file.
- `url` can be used in Markdown contexts. The link is expanded when the format in `markdown` is used.

## List uploads

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

Get all uploads of the project sorted by `created_at` in descending order.

Prerequisites:

- At least the Maintainer role.

```plaintext
GET /projects/:id/uploads
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads"
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

Download an uploaded file by ID.

Prerequisites:

- At least the Maintainer role.

```plaintext
GET /projects/:id/uploads/:upload_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `upload_id` | integer           | Yes      | ID of the upload. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the uploaded file in the response body.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## Download an uploaded file by secret and filename

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) in GitLab 17.4.

Download an uploaded file by secret and filename.

Prerequisites:

- At least the Guest role.

```plaintext
GET /projects/:id/uploads/:secret/:filename
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|:-----------|:------------------|:---------|:------------|
| `id`       | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `secret`   | string            | Yes      | 32-character secret of the upload. |
| `filename` | string            | Yes      | Filename of the upload. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the uploaded file in the response body.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

## Delete an uploaded file by ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

Delete an uploaded file by ID.

Prerequisites:

- At least the Maintainer role.

```plaintext
DELETE /projects/:id/uploads/:upload_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `upload_id` | integer           | Yes      | ID of the upload. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) status code without any response body.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## Delete an uploaded file by secret and filename

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441) in GitLab 17.4.

Delete an uploaded file by secret and filename.

Prerequisites:

- At least the Maintainer role.

```plaintext
DELETE /projects/:id/uploads/:secret/:filename
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|:-----------|:------------------|:---------|:------------|
| `id`       | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `secret`   | string            | Yes      | 32-character secret of the upload. |
| `filename` | string            | Yes      | Filename of the upload. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) status code without any response body.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```
