# Project import/export API

[Introduced][ce-41899] in GitLab 10.6

[See also the project import/export documentation](../user/project/settings/import_export.md)

## Schedule an export

Start a new export.

```http
POST /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `description`      | string | no | Overrides the project description |

```console
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "description=Foo Bar" https://gitlab.example.com/api/v4/projects/1/export
```

```json
{
  "message": "202 Accepted"
}
```

## Export status

Get the status of export.

```http
GET /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```console
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/export
```

Status can be one of `none`, `started`, or `finished`.

`_links` are only present when export has finished.

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
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export",
  }
}
```

## Export download

Download the finished export.

```http
GET /projects/:id/export/download
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```console
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --remote-header-name --remote-name https://gitlab.example.com/api/v4/projects/5/export/download
```

```console
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## Import a file

```http
POST /projects/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `namespace` | integer/string | no | The ID or path of the namespace that the project will be imported to. Defaults to the current user's namespace |
| `file` | string | yes | The file to be uploaded |
| `path` | string | yes | Name and path for new project |

To upload a file from your filesystem, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your filesystem and be preceded
by `@`. For example:

```console
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "path=api-project" --form "file=@/path/to/file" https://gitlab.example.com/api/v4/projects/import
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
  "import_status": "scheduled"
}
```

## Import status

Get the status of an import.

```http
GET /projects/:id/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```console
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/import
```

Status can be one of `none`, `scheduled`, `failed`, `started`, or `finished`.

If the status is `failed`, it will include the import error message under `import_error`.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started"
}
```

[ce-41899]: https://gitlab.com/gitlab-org/gitlab-ce/issues/41899
