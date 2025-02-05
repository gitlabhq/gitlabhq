---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API for Git tags in GitLab."
title: Tags API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## List project repository tags

> - `version` value for the `order_by` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95150) in GitLab 15.4.
> - `created_at` response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) in GitLab 16.11.

Get a list of repository tags from a project, sorted by update date and time in
descending order.

NOTE:
If the repository is publicly accessible, authentication
(`--header "PRIVATE-TOKEN: <your_access_token>"`) is not required.

```plaintext
GET /projects/:id/repository/tags
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `order_by` | string            | no       | Return tags ordered by `name`, `updated`, or `version`. Default is `updated`. |
| `sort`     | string            | no       | Return tags sorted in `asc` or `desc` order. Default is `desc`. |
| `search`   | string            | no       | Return a list of tags matching the search criteria. You can use `^term` and `term$` to find tags that begin and end with `term`. No other regular expressions are supported. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/repository/tags"
```

Example Response:

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
    "protected": true,
    "created_at": "2017-07-26T11:08:53.000+02:00"
  }
]
```

## Get a single repository tag

> - `created_at` response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) in GitLab 16.11.

Get a specific repository tag determined by its name. This endpoint can be
accessed without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | yes      | The name of a tag. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
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
  "protected": false,
  "created_at": "2017-07-26T11:08:53.000+02:00"
}
```

## Create a new tag

> - `created_at` response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) in GitLab 16.11.

Creates a new tag in the repository that points to the supplied ref.

```plaintext
POST /projects/:id/repository/tags
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | yes      | The name of a tag. |
| `ref`      | string            | yes      | Create a tag from a commit SHA, another tag name, or branch name. |
| `message`  | string            | no       | Create an annotated tag. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=main"
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
  "protected": false,
  "created_at": null
}
```

The type of tag created determines the contents of `created_at`, `target` and `message`:

- For annotated tags:
  - `created_at` contains the timestamp of tag creation.
  - `message` contains the annotation.
  - `target` contains the tag object's ID.
- For lightweight tags:
  - `created_at` is null.
  - `message` is null.
  - `target` contains the commit ID.

Errors return status code `405` with an explanatory error message.

## Delete a tag

Deletes a tag of a repository with given name.

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | yes      | The name of a tag. |

## Get X.509 signature of a tag

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106578) in GitLab 15.7.

Get the [X.509 signature from a tag](../user/project/repository/signed_commits/x509.md),
if it is signed. Unsigned tags return a `404 Not Found` response.

```plaintext
GET /projects/:id/repository/tags/:tag_name/signature
```

Parameters:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | yes      | The name of a tag. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/tags/v1.1.1/signature"
```

Example response if tag is X.509 signed:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  }
}
```

Example response if tag is unsigned:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
