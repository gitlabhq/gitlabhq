---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group and project migration by direct transfer API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Project migration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

With the group migration by direct transfer API, you can start and view the progress of migrations initiated with
[group migration by direct transfer](../user/group/import/_index.md).

WARNING:
Migrating projects with this API is in [beta](../policy/development_stages_support.md#beta). This feature is not
ready for production use.

## Prerequisites

For information on prerequisites for group migration by direct transfer API, see
prerequisites for [migrating groups by direct transfer](../user/group/import/direct_transfer_migrations.md#prerequisites).

## Start a new group or project migration

> - `project_entity` source type [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

Use this endpoint to start a new group or project migration. Specify:

- `entities[group_entity]` to migrate a group.
- `entities[project_entity]` to migrate a project. (**Status:** Beta)

```plaintext
POST /bulk_imports
```

| Attribute                         | Type   | Required | Description |
| --------------------------------- | ------ | -------- | ----------- |
| `configuration`                   | Hash   | yes      | The source GitLab instance configuration. |
| `configuration[url]`              | String | yes      | Source GitLab instance URL. |
| `configuration[access_token]`     | String | yes      | Access token to the source GitLab instance. |
| `entities`                        | Array  | yes      | List of entities to import. |
| `entities[source_type]`           | String | yes      | Source entity type. Valid values are `group_entity` and `project_entity` (GitLab 15.11 and later). |
| `entities[source_full_path]`      | String | yes      | Source full path of the entity to import. For example, `gitlab-org/gitlab`. |
| `entities[destination_slug]`      | String | yes      | Destination slug for the entity. GitLab uses the slug as the URL path to the entity. The name of the imported entity is copied from the name of the source entity and not the slug. |
| `entities[destination_name]`      | String | no       | Deprecated: Use `destination_slug` instead. Destination slug for the entity. |
| `entities[destination_namespace]` | String | yes      | Full path of the destination group [namespace](../user/namespace/_index.md) for the entity. Must be an existing group in the destination instance. |
| `entities[migrate_projects]`      | Boolean | no      | Also import all nested projects of the group (if `source_type` is `group_entity`). Defaults to `true`. |
| `entities[migrate_memberships]`   | Boolean | no      | Import user memberships. Defaults to `true`. |

```shell
curl --request POST \
  --url "https://destination-gitlab-instance.example.com/api/v4/bulk_imports" \
  --header "PRIVATE-TOKEN: <your_access_token_for_destination_gitlab_instance>" \
  --header "Content-Type: application/json" \
  --data '{
    "configuration": {
      "url": "https://source-gitlab-instance.example.com",
      "access_token": "<your_access_token_for_source_gitlab_instance>"
    },
    "entities": [
      {
        "source_full_path": "source/full/path",
        "source_type": "group_entity",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination/namespace/path"
      }
    ]
  }'
```

```json
{
  "id": 1,
  "status": "created",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

## List all group or project migrations

```plaintext
GET /bulk_imports
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z",
        "has_failures": false
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z",
        "has_failures": false
    }
]
```

## List all group or project migrations' entities

```plaintext
GET /bulk_imports/entities
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "entity_type": "group",
        "source_full_path": "another_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "another_slug",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": { }
    }
]
```

## Get group or project migration details

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## List group or project migration entities

```plaintext
GET /bulk_imports/:id/entities
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": true,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    }
]
```

## Get group or project migration entity details

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
    "id": 1,
    "bulk_import_id": 1,
    "status": "finished",
    "entity_type": "group",
    "source_full_path": "source_group",
    "destination_full_path": "destination/full_path",
    "destination_name": "destination_slug",
    "destination_slug": "destination_slug",
    "destination_namespace": "destination_path",
    "parent_id": null,
    "namespace_id": 1,
    "project_id": null,
    "created_at": "2021-06-18T09:47:37.390Z",
    "updated_at": "2021-06-18T09:47:51.867Z",
    "failures": [
        {
            "relation": "group",
            "step": "extractor",
            "exception_message": "Error!",
            "exception_class": "Exception",
            "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
            "created_at": "2021-06-24T10:40:46.495Z",
            "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
            "pipeline_step": "extractor"
        }
    ],
    "migrate_projects": true,
    "migrate_memberships": true,
    "has_failures": true,
    "stats": {
        "labels": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        },
        "milestones": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        }
    }
}
```

## Get list of failed import records for group or project migration entity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428016) in GitLab 16.6.

```plaintext
GET /bulk_imports/:id/entities/:entity_id/failures
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2/failures"
```

```json
{
  "relation": "issues",
  "exception_message": "Error!",
  "exception_class": "StandardError",
  "correlation_id_value": "06289e4b064329a69de7bb2d7a1b5a97",
  "source_url": "https://gitlab.example/project/full/path/-/issues/1",
  "source_title": "Issue title"
}
```

## Cancel a migration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438281) in GitLab 17.1.

Cancel a direct transfer migration.

```plaintext
POST /bulk_imports/:id/cancel
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/cancel"
```

```json
{
  "id": 1,
  "status": "canceled",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

Possible response status codes:

| Status | Description                     |
|--------|---------------------------------|
| 200    | Migration successfully canceled |
| 401    | Unauthorized                    |
| 403    | Forbidden                       |
| 404    | Migration not found             |
| 503    | Service unavailable             |
