---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Migrations (Bulk Imports) API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64335) in GitLab 14.1.

With the GitLab Migrations API, you can view the progress of migrations initiated with
[GitLab Group Migration](../user/group/import/index.md).

## List all GitLab migrations

```plaintext
GET /bulk_imports
```

| Attribute  | Type    | Required | Description                            |
|:-----------|:--------|:---------|:---------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.  |
| `page`     | integer | no       | Page to retrieve.                      |
| `status`   | string  | no       | Import status.                         |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z"
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z"
    }
]
```

## List all GitLab migrations' entities

```plaintext
GET /bulk_imports/entities
```

| Attribute  | Type    | Required | Description                            |
|:-----------|:--------|:---------|:---------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.  |
| `page`     | integer | no       | Page to retrieve.                      |
| `status`   | string  | no       | Import status.                         |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "source_full_path": "source_group",
        "destination_name": "destination_name",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": []
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "source_full_path": "another_group",
        "destination_name": "another_name",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z"
            }
        ]
    }
]
```

## Get GitLab migration details

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## List GitLab migration entities

```plaintext
GET /bulk_imports/:id/entities
```

| Attribute  | Type    | Required | Description                            |
|:-----------|:--------|:---------|:---------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.  |
| `page`     | integer | no       | Page to retrieve.                      |
| `status`   | string  | no       | Import status.                         |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z"
    }
]
```

## Get GitLab migration entity details

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```
