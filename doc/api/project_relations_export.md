---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project relations export API
description: "Export project relations with the REST API."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to migrate a project structure. Each top-level
relation (for example, milestones, boards, and labels) is stored as a separate file.

This API is primarily used during [group migration by direct transfer](../user/group/import/_index.md).
You cannot use this API with the [project import and export API](project_import_export.md).

## Schedule new export

Start a new project relations export:

```plaintext
POST /projects/:id/export_relations
```

| Attribute | Type              | Required | Description                                        |
|-----------|-------------------|----------|----------------------------------------------------|
| `id`      | integer or string | Yes      | ID of the project.                                 |
| `batched` | boolean           | No       | Whether to export in batches.                      |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## Export status

View the status of the relations export:

```plaintext
GET /projects/:id/export_relations/status
```

| Attribute  | Type              | Required | Description                                        |
|------------|-------------------|----------|----------------------------------------------------|
| `id`       | integer or string | Yes      | ID of the project.                                 |
| `relation` | string            | No       | Name of the project top-level relation to view.    |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

The status can be one of the following:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

```json
[
  {
    "relation": "project_badges",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.423Z",
    "batched": true,
    "batches_count": 1,
    "batches": [
      {
        "status": 1,
        "batch_number": 1,
        "objects_count": 1,
        "error": null,
        "updated_at": "2021-05-04T11:25:20.423Z"
      }
    ]
  },
  {
    "relation": "boards",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.085Z",
    "batched": false,
    "batches_count": 0
  }
]
```

## Export download

Download the finished relations export:

```plaintext
GET /projects/:id/export_relations/download
```

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | integer or string | Yes      | ID of the project. |
| `relation`     | string            | Yes      | Name of the project top-level relation to download. |
| `batched`      | boolean           | No       | Whether the export is batched. |
| `batch_number` | integer           | No       | Number of export batch to download. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## Related topics

- [Group relations export API](group_relations_export.md)
