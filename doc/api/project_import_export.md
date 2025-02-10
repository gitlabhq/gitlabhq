---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project import and export API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the project import and export API to import and export projects using file transfers.

Before using the project import and export API, you might want to use the
[group import and export API](group_import_export.md).

After using the project import and export API, you might want to use the
[Project-level CI/CD variables API](project_level_variables.md).

You must still migrate your [Container Registry](../user/packages/container_registry/_index.md)
over a series of Docker pulls and pushes. Re-run any CI/CD pipelines to retrieve any build artifacts.

## Prerequisites

For prerequisites for project import and export API, see:

- Prerequisites for [project export](../user/project/settings/import_export.md#export-a-project-and-its-data).
- Prerequisites for [project import](../user/project/settings/import_export.md#import-a-project-and-its-data).

## Schedule an export

Start a new export.

The endpoint also accepts an `upload` hash parameter. It contains all the necessary information to upload the exported
project to a web server or to any S3-compatible platform. For exports, GitLab:

- Only supports binary data file uploads to the final server.
- Sends the `Content-Type: application/gzip` header with upload requests. Ensure that your pre-signed URL includes this
  as part of the signature.
- Can take some time to complete the project export process. Make sure the upload URL doesn't have a short expiration
  time and is available throughout the export process.
- Administrators can modify the maximum export file size. By default, the maximum is unlimited (`0`). To change this,
  edit `max_export_size` using either:
  - [GitLab UI](../administration/settings/import_and_export_settings.md).
  - [Application settings API](settings.md#update-application-settings)
- Has a fixed limit for the maximum import file size on GitLab.com. For more information, see
  [Account and limit settings](../user/gitlab_com/_index.md#account-and-limit-settings).

The `upload[url]` parameter is required if the `upload` parameter is present.

For uploads to Amazon S3, refer to [Generating a pre-signed URL for uploading objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
documentation scripts to generate the `upload[url]`.
Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430277), you can only upload files with a maximum file size of 5 GB to Amazon S3.

```plaintext
POST /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`                  | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `upload[url]`         | string | yes      | The URL to upload the project. |
| `description`         | string | no | Overrides the project description. |
| `upload`              | hash | no | Hash that contains the information to upload the exported project to a web server. |
| `upload[http_method]` | string | no      | The HTTP method to upload the exported project. Only `PUT` and `POST` methods allowed. Default is `PUT`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
    "https://gitlab.example.com/api/v4/projects/1/export" \
    --data "upload[http_method]=PUT" \
    --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=<your_access_token>%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

## Export status

Get the status of export.

```plaintext
GET /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/1/export"
```

Status can be one of:

- `none`: No exports _queued_, _started_, _finished_, or _being regenerated_.
- `queued`: The request for export is received, and is in the queue to be processed.
- `started`: The export process has started and is in progress. It includes:
  - The process of exporting.
  - Actions performed on the resulting file, such as sending an email notifying
    the user to download the file, or uploading the exported file to a web server.
- `finished`: After the export process has completed and the user has been notified.
- `regeneration_in_progress`: An export file is available to download, and a request to generate a new export is in process.

`_links` are only present when export has finished.

`created_at` is the project create timestamp, not the export start time.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "export_status": "finished",
  "_links": {
    "api_url": "https://gitlab.example.com/api/v4/projects/1/export/download",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export"
  }
}
```

## Export download

Download the finished export.

```plaintext
GET /projects/:id/export/download
```

| Attribute | Type              | Required | Description                              |
| --------- | ----------------- | -------- | ---------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/projects/5/export/download"
```

```shell
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## Import a file

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

```plaintext
POST /projects/import
```

| Attribute   | Type           | Required | Description                              |
| ----------- | -------------- | -------- | ---------------------------------------- |
| `file`      | string | yes | The file to be uploaded. |
| `path`      | string | yes | Name and path for new project. |
| `name`      | string | no | The name of the project to be imported. Defaults to the path of the project if not provided. |
| `namespace` | integer or string | no | The ID or path of the namespace to import the project to. Defaults to the current user's namespace.<br/><br/> Requires at least the Maintainer role on the destination group to import to. |
| `override_params` | Hash | no | Supports all fields defined in the [Project API](projects.md). |
| `overwrite` | boolean | no | If there is a project with the same path the import overwrites it. Defaults to `false`. |

The override parameters passed take precedence over all values defined inside the export file.

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "path=api-project" \
     --form "file=@/path/to/file" "https://gitlab.example.com/api/v4/projects/import"
```

cURL doesn't support posting a file from a remote server. This example imports a project
using Python's `open` method:

```python
import requests

url =  'https://gitlab.example.com/api/v4/projects/import'
files = { "file": open("project_export.tar.gz", "rb") }
data = {
    "path": "example-project",
    "namespace": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "api-project",
  "name_with_namespace": "Administrator / api-project",
  "path": "api-project",
  "path_with_namespace": "root/api-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": []
}
```

NOTE:
The maximum import file size can be set by the Administrator. It defaults to `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](settings.md#update-application-settings) or the [**Admin** area](../administration/settings/account_and_limit_settings.md).

## Import a file from a remote object storage

DETAILS:
**Status:** Beta

FLAG:
On GitLab Self-Managed, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../administration/feature_flags.md) named `import_project_from_remote_file`.
On GitLab.com and GitLab Dedicated, this feature is available.

```plaintext
POST /projects/remote-import
```

| Attribute         | Type              | Required | Description                              |
| ----------------- | ----------------- | -------- | ---------------------------------------- |
| `path`            | string            | yes      | Name and path for the new project. |
| `url`             | string            | yes      | URL for the file to import. |
| `name`            | string            | no       | The name of the project to import. If not provided, defaults to the path of the project. |
| `namespace`       | integer or string | no       | The ID or path of the namespace to import the project to. Defaults to the current user's namespace. |
| `overwrite`       | boolean           | no       | Whether to overwrite a project with the same path when importing. Defaults to `false`. |
| `override_params` | Hash              | no       | Supports all fields defined in the [Project API](projects.md). |

The passed override parameters take precedence over all values defined in the export file.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/remote-import" \
  --data '{"url":"https://remoteobject/file?token=123123","path":"remote-project"}'
```

```json
{
  "id": 1,
  "description": null,
  "name": "remote-project",
  "name_with_namespace": "Administrator / remote-project",
  "path": "remote-project",
  "path_with_namespace": "root/remote-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

The `Content-Length` header must return a valid number. The maximum file size is 10 GB.
The `Content-Type` header must be `application/gzip`.

## Import a single relation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/425798) as a [beta](../policy/development_stages_support.md#beta) in GitLab 16.11 [with a flag](../administration/feature_flags.md) named `single_relation_import`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/455889) in GitLab 17.1. Feature flag `single_relation_import` removed.

This endpoint accepts a project export archive and a named relation (issues,
merge requests, pipelines, or milestones) and re-imports that relation, skipping
items that have already been imported.

The required project export file adheres to the same structure and size requirements described in
[Import a file](#import-a-file).

- The extracted files must adhere to the structure of a GitLab project export.
- The archive must not exceed the maximum import file size configured by the Administrator.

```plaintext
POST /projects/import-relation
```

| Attribute  | Type   | Required | Description                                                                                                    |
|------------|--------|----------|----------------------------------------------------------------------------------------------------------------|
| `file`     | string | yes      | The file to be uploaded.                                                                                       |
| `path`     | string | yes      | Name and path for new project.                                                                                 |
| `relation` | string | yes      | The name of the relation to import. Must be one of `issues`, `milestones`, `ci_pipelines` or `merge_requests`. |

To upload a file from your file system, use the `--form` option, which causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "path=api-project" \
     --form "file=@/path/to/file" \
     --form "relation=issues" \
     "https://gitlab.example.com/api/v4/projects/import-relation"
```

```json
{
  "id": 9,
  "project_path": "namespace1/project1",
  "relation": "issues",
  "status": "finished"
}
```

## Check relation import statuses

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/425798) in GitLab 16.11.

This endpoint fetches the status of any relation imports associated with a project. Because
only one relation import can be scheduled at a time, you can use this endpoint to check whether
the previous import completed successfully.

```plaintext
GET /projects/:id/relation-imports
```

| Attribute | Type               | Required | Description                                                                          |
| --------- |--------------------| -------- |--------------------------------------------------------------------------------------|
| `id`      | integer or string  | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/18/relation-imports"
```

```json
[
  {
    "id": 1,
    "project_path": "namespace1/project1",
    "relation": "issues",
    "status": "created",
    "created_at": "2024-03-25T11:03:48.074Z",
    "updated_at": "2024-03-25T11:03:48.074Z"
  }
]
```

Status can be one of:

- `created`: The import has been scheduled, but has not started.
- `started`: The import is being processed.
- `finished`: The import has completed.
- `failed`: The import was not able to be completed.

## Import a file from AWS S3

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350571) in GitLab 15.11. Feature flag `import_project_from_remote_file_s3` removed.

```plaintext
POST /projects/remote-import-s3
```

| Attribute           | Type           | Required | Description                              |
| ------------------- | -------------- | -------- | ---------------------------------------- |
| `access_key_id`     | string         | yes      | [AWS S3 access key ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). |
| `bucket_name`       | string         | yes      | [AWS S3 bucket name](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) where the file is stored. |
| `file_key`          | string         | yes      | [AWS S3 file key](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html) to identify the file. |
| `path`              | string         | yes      | The full path of the new project. |
| `region`            | string         | yes      | [AWS S3 region name](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html#Regions) where the file is stored. |
| `secret_access_key` | string         | yes      | [AWS S3 secret access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys). |
| `name`              | string         | no       | The name of the project to import. If not provided, defaults to the path of the project. |
| `namespace`         | integer or string | no       | The ID or path of the namespace to import the project to. Defaults to the current user's namespace. |

The passed override parameters take precedence over all values defined in the export file.

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/remote-import-s3" \
  --header "PRIVATE-TOKEN: <your gitlab access key>" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "Sample Project",
  "path": "sample-project",
  "region": "<Your S3 region name>",
  "bucket_name": "<Your S3 bucket name>",
  "file_key": "<Your S3 file key>",
  "access_key_id": "<Your AWS access key id>",
  "secret_access_key": "<Your AWS secret access key>"
}'
```

This example imports from an Amazon S3 bucket, using a module that connects to Amazon S3:

```python
import requests
from io import BytesIO

s3_file = requests.get(presigned_url)

url =  'https://gitlab.example.com/api/v4/projects/import'
files = {'file': ('file.tar.gz', BytesIO(s3_file.content))}
data = {
    "path": "example-project",
    "namespace": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "Sample project",
  "name_with_namespace": "Administrator / sample-project",
  "path": "sample-project",
  "path_with_namespace": "root/sample-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

## Import status

Get the status of an import.

```plaintext
GET /projects/:id/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/1/import"
```

Status can be one of:

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

If the status is `failed`, it includes the import error message under `import_error`.
If the status is `failed`, `started` or `finished`, the `failed_relations` array might
be populated with any occurrences of relations that failed to import due to either:

- Unrecoverable errors.
- Retries were exhausted. A typical example: query timeouts.

NOTE:
An element's `id` field in `failed_relations` references the failure record, not the relation.

NOTE:
The `failed_relations` array is capped to 100 items.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ]
}
```

When importing from GitHub, the a `stats` field lists how many objects were already fetched from
GitHub and how many were already imported:

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ],
  "stats": {
    "fetched": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    },
    "imported": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    }
  }
}
```

## Related topics

- [Migrating projects using file exports](../user/project/settings/import_export.md).
- [Project import and export Rake tasks](../administration/raketasks/project_import_export.md).
- [Group import and export API](group_import_export.md)
