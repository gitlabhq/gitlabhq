---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Data management API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/537707) in GitLab 18.3 with a [flag](../../administration/feature_flags/_index.md) named `geo_primary_verification_view`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use the data management API to manage an instance's data.

Prerequisites:

- You must be an administrator.

## Get information about a model

This endpoint is an [experiment](../../policy/development_stages_support.md) and might be changed or removed without notice.

```plaintext
GET /admin/data_management/:model_name
```

The `:model_name` parameter must be one of:

- `ci_job_artifact`
- `ci_pipeline_artifact`
- `ci_secure_file`
- `container_repository`
- `dependency_proxy_blob`
- `dependency_proxy_manifest`
- `design_management_repository`
- `group_wiki_repository`
- `lfs_object`
- `merge_request_diff`
- `packages_package_file`
- `pages_deployment`
- `project`
- `projects_wiki_repository`
- `snippet_repository`
- `terraform_state_version`
- `upload`

Supported attributes:

| Attribute         | Type   | Required | Description                                                                                                                 |
|-------------------|--------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`      | string | Yes      | The name of the requested model. Must belong to the `:model_name` list above.                                               |
| `checksum_state`  | string | No       | Search by checksum status. Allowed values: pending, started, succeeded, failed, disabled.                                   |
| `identifiers`     | array  | No       | Filter results with an array of unique identifiers of the requested model, which can be integers or base64 encoded strings. |

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the model. It includes the following
response attributes:

| Attribute              | Type              | Description                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo-specific checksum information, if available.                               |
| `created_at`           | timestamp         | Creation timestamp, if available.                                              |
| `file_size`            | integer           | Size of the object, if available.                                              |
| `model_class`          | string            | Class name of the model.                                                       |
| `record_identifier`    | string or integer | Unique identifier of the record. Can be an integer or a base64 encoded string. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/project"
```

Example response:

```json
[
  {
    "record_identifier": 1,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:10.173Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.643Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  },
  {
    "record_identifier": 2,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:14.402Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.214Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  }
]
```

## Recalculate the checksum of all model records

```plaintext
PUT /admin/data_management/:model_name/checksum
```

| Attribute           | Type              | Required | Description                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | string            | Yes      | The name of the requested model. Must belong to the `:model_name` list above.               |

This endpoint marks all records from the model for checksum recalculation. It enqueues a background job to do so. If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and a JSON response containing the following information:

| Attribute | Type   | Description                                       |
|-----------|--------|---------------------------------------------------|
| `message` | string | A information message about the success or error. |
| `status`  | string | Can be "success" or "error".                      |

```json
{
  "status": "success",
  "message": "Batch update job has been successfully enqueued."
}
```

## Get information about a specific model record

```plaintext
GET /admin/data_management/:model_name/:id
```

| Attribute           | Type              | Required | Description                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | string            | Yes      | The name of the requested model. Must belong to the `:model_name` list above.               |
| `record_identifier` | string or integer | Yes      | The unique identifier of the requested model. Can be an integer or a base64 encoded string. |

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the specific model record. It includes the following
response attributes:

| Attribute              | Type              | Description                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo-specific checksum information, if available.                               |
| `created_at`           | timestamp         | Creation timestamp, if available.                                              |
| `file_size`            | integer           | Size of the object, if available.                                              |
| `model_class`          | string            | Class name of the model.                                                       |
| `record_identifier`    | string or integer | Unique identifier of the record. Can be an integer or a base64 encoded string. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/project/1"
```

Example response:

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<object checksum>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```

## Recalculate the checksum of a specific model record

```plaintext
PUT /admin/data_management/:model_name/:record_identifier/checksum
```

| Attribute           | Type              | Required | Description                                                                                                               |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `model_name`        | string            | Yes      | The name of the requested model. Must belong to the `:model_name` list above.                                             |
| `record_identifier` | string or integer | Yes      | Unique identifier of the record. Can be an integer or a base64 encoded string (taken from the response of the GET query). |

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the specific model record. The checksum value is a representation of the queried model hashed with the md5 or sha256 algorithm.

Example response:

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<sha256 or md5 string>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```
