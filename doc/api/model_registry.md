---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Model registry API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with the machine learning [model registry](../user/project/ml/model_registry/_index.md).

The `:model_version_id` attribute in each endpoint accepts either a model version ID or a candidate run ID.
For more information, see [Model version and candidate IDs](#model-version-and-candidate-ids).

## Download a machine learning model package file

Downloads a specified file from a machine learning model package.

```plaintext
GET /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

Supported attributes:

| Attribute          | Type              | Required | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `model_version_id` | integer or string | Yes      | The model version ID or candidate run ID. See [Model version and candidate IDs](#model-version-and-candidate-ids). |
| `file_name`        | string            | Yes      | The filename. |
| `path`             | string            | No       | The directory path for the file. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the file contents.

Example request:

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt"
```

Example request with a directory path:

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/foo.txt"
```

## Upload a model package file

Uploads a file to a machine learning model package.

### Authorize the upload

Authorizes a file upload to a machine learning model package.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name/authorize
```

Supported attributes:

| Attribute          | Type              | Required | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `model_version_id` | integer or string | Yes      | The model version ID or candidate run ID. See [Model version and candidate IDs](#model-version-and-candidate-ids). |
| `file_name`        | string            | Yes      | The filename. |
| `path`             | string            | No       | The directory path for the file. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl/authorize"
```

### Send the file

Uploads the file to a machine learning model package.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

Supported attributes:

| Attribute          | Type              | Required | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `model_version_id` | integer or string | Yes      | The model version ID or candidate run ID. See [Model version and candidate IDs](#model-version-and-candidate-ids). |
| `file_name`        | string            | Yes      | The filename. |
| `path`             | string            | No       | The directory path for the file. |
| `file`             | file              | Yes      | The file to upload. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl"
```

Example request with a directory path:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/model.pkl"
```

## Model version and candidate IDs

The `:model_version_id` attribute accepts either a model version ID or
a candidate run ID.

To find the model version ID, check the URL of the model version page.
For example, in `https://gitlab.example.com/my-namespace/my-project/-/ml/models/1/versions/5`,
the model version ID is `5`.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/5/files/model.pkl"
```

To use a candidate run ID, prepend the internal ID of the candidate
with `candidate:`. For example, in
`https://gitlab.example.com/my-namespace/my-project/-/ml/candidates/5`,
the value for `:model_version_id` is `candidate:5`.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/candidate:5/files/model.pkl"
```
