---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project relations export API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - New application setting `bulk_import_enabled` introduced in GitLab 15.8. `bulk_import` feature flag removed.

The project relations export API partially exports a project's structure as separate files for each
top-level
relation (for example, milestones, issues, and labels).

The project relations export API is primarily used in
[group migration](../user/group/import/_index.md) can't
be used with the
[project import and export API](project_import_export.md).

## Schedule new export

Start a new project relations export:

```plaintext
POST /projects/:id/export_relations
```

| Attribute | Type           | Required | Description                                        |
|-----------|----------------|----------|----------------------------------------------------|
| `id`      | integer/string | yes      | ID of the project.                                 |
| `batched` | boolean        | no       | Whether to export in batches.                      |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/export_relations"
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

| Attribute  | Type           | Required | Description                                        |
|------------|----------------|----------|----------------------------------------------------|
| `id`       | integer/string | yes      | ID of the project.                                 |
| `relation` | string         | no       | Name of the project top-level relation to view.    |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

The status can be one of the following:

- `0` - `started`
- `1` - `finished`
- `-1` - `failed`

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

| Attribute      | Type           | Required | Description                                         |
|----------------|----------------|----------|-----------------------------------------------------|
| `id`           | integer/string | yes      | ID of the project.                                  |
| `relation`     | string         | yes      | Name of the project top-level relation to download. |
| `batched`      | boolean        | no       | Whether the export is batched.                      |
| `batch_number` | integer        | no       | Number of export batch to download.                 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## Related topics

- [Group relations export API](group_relations_export.md)
