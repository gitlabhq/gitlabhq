---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Group relations export API
description: "Export group relations with the REST API."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This API is used by the destination instance during [group migration by direct transfer](../user/group/import/_index.md)
to migrate a group structure. You don't usually need to use this API yourself.

In this context, a {{< glossary-tooltip text="relation" >}} is an exportable item such as an epic. When exported, the
relation includes any items related to the relation such as a label.

If you want to use this API, your GitLab instance must meet certain
[prerequisites](../user/group/import/direct_transfer_migrations.md#prerequisites).

> [!note]
> This API can't be used with the [group import and export API](group_import_export.md), which is for file-based
> migration.

## Schedule a new export for a group

Schedules a relations export for a specified group.

```plaintext
POST /groups/:id/export_relations
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|------------ |
| `id`      | Integer or string | Yes      | ID of the group. |
| `batched` | Boolean           | No       | Whether to export in batches. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## Retrieve the status of an export

Retrieve the status of a relations export.

```plaintext
GET /groups/:id/export_relations/status
```

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|------------ |
| `id`       | Integer or string | Yes      | ID of the group. |
| `relation` | String            | No       | Name of the group top-level relation to view. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export_relations/status"
```

The status can be one of the following:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

```json
[
  {
    "relation": "badges",
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

## Download an export

Download the finished relations export.

```plaintext
GET /groups/:id/export_relations/download
```

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|------------ |
| `id`           | Integer or string | Yes      | ID of the group. |
| `relation`     | String            | Yes      | Name of the group top-level relation to download. |
| `batched`      | Boolean           | No       | Whether the export is batched. |
| `batch_number` | Integer           | No       | Number of export batch to download. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name "https://gitlab.example.com/api/v4/groups/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## Related topics

- [Project relations export API](project_relations_export.md)
