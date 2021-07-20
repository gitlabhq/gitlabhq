---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project import/export API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41899) in GitLab 10.6.

See also:

- [Project import/export documentation](../user/project/settings/import_export.md).
- [Project import/export administration Rake tasks](../administration/raketasks/project_import_export.md). **(FREE SELF)**

## Schedule an export

Start a new export.

The endpoint also accepts an `upload` parameter. This parameter is a hash. It contains
all the necessary information to upload the exported project to a web server or
to any S3-compatible platform. At the moment we only support binary
data file uploads to the final server.

From GitLab 10.7, the `upload[url]` parameter is required if the `upload` parameter is present.

```plaintext
POST /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `description`      | string | no | Overrides the project description |
| `upload`      | hash | no | Hash that contains the information to upload the exported project to a web server |
| `upload[url]`      | string | yes      | The URL to upload the project |
| `upload[http_method]`      | string | no      | The HTTP method to upload the exported project. Only `PUT` and `POST` methods allowed. Default is `PUT` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/export" \
    --data "upload[http_method]=PUT" \
    --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIMBJHN2O62W8IELQ%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

NOTE:
The upload request is sent with `Content-Type: application/gzip` header. Ensure that your pre-signed URL includes this as part of the signature.

## Export status

Get the status of export.

```plaintext
GET /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/export"
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

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/projects/5/export/download"
```

```shell
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## Import a file

```plaintext
POST /projects/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `namespace` | integer/string | no | The ID or path of the namespace to import the project to. Defaults to the current user's namespace |
| `name` | string | no | The name of the project to be imported. Defaults to the path of the project if not provided |
| `file` | string | yes | The file to be uploaded |
| `path` | string | yes | Name and path for new project |
| `overwrite` | boolean | no | If there is a project with the same path the import overwrites it. Default to false |
| `override_params` | Hash | no | Supports all fields defined in the [Project API](projects.md) |

The override parameters passed take precedence over all values defined inside the export file.

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "path=api-project" \
     --form "file=@/path/to/file" "https://gitlab.example.com/api/v4/projects/import"
```

cURL doesn't support posting a file from a remote server. Importing a project from a remote server can be accomplished through something like the following:

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
The maximum import file size can be set by the Administrator, default is `0` (unlimited)..
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](settings.md#change-application-settings) or the [Admin UI](../user/admin_area/settings/account_and_limit_settings.md). Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50MB to 0 in GitLab 13.8.

## Import a file from a remote object storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/282503) in GitLab 13.12 in [Beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta).

This endpoint is behind a feature flag that is disabled by default.

To enable this endpoint:

```ruby
Feature.enable(:import_project_from_remote_file)
```

To disable this endpoint:

```ruby
Feature.disable(:import_project_from_remote_file)
```

```plaintext
POST /projects/remote-import
```

| Attribute         | Type           | Required | Description                              |
| ----------------- | -------------- | -------- | ---------------------------------------- |
| `namespace`       | integer/string | no       | The ID or path of the namespace to import the project to. Defaults to the current user's namespace. |
| `name`            | string         | no       | The name of the project to import. If not provided, defaults to the path of the project. |
| `url`             | string         | yes      | URL for the file to import. |
| `path`            | string         | yes      | Name and path for the new project. |
| `overwrite`       | boolean        | no       | Whether to overwrite a project with the same path when importing. Defaults to `false`. |
| `override_params` | Hash           | no       | Supports all fields defined in the [Project API](projects.md). |

The passed override parameters take precedence over all values defined in the export file.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
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

The `ContentType` header must return a valid number. The maximum file size is 10 gigabytes.
The `ContentLength` header must be `application/gzip`.

## Import status

Get the status of an import.

```plaintext
GET /projects/:id/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/import"
```

Status can be one of:

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

If the status is `failed`, it includes the import error message under `import_error`.
If the status is `failed`, `started` or `finished`, the `failed_relations` array might
be populated with any occurrences of relations that failed to import either due to
unrecoverable errors or because retries were exhausted (a typical example are query timeouts.)

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
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests"
    }
  ]
}
```
