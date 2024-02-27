---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group relations export API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59978) in GitLab 13.12.

The group relations export API partially exports a group's structure as separate files for each
top-level
relation (for example, milestones, boards, and labels).

The group relations export API is primarily used in [group migration by direct transfer](../user/group/import/index.md)
and your GitLab instance must meet [certain prerequisites](../user/group/import/index.md#prerequisites).

This API can't be used with the [group import and export API](group_import_export.md).

## Schedule new export

Start a new group relations export:

```plaintext
POST /groups/:id/export_relations
```

| Attribute | Type           | Required | Description                                      |
|-----------|----------------|----------|--------------------------------------------------|
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user. |
| `batched` | boolean        | no       | Whether to export in batches.                    |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## Export status

View the status of the relations export:

```plaintext
GET /groups/:id/export_relations/status
```

| Attribute  | Type           | Required | Description                                      |
|------------|----------------|----------|--------------------------------------------------|
| `id`       | integer/string | yes      | ID of the group owned by the authenticated user. |
| `relation` | string         | no       | Name of the project top-level relation to view.  |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/1/export_relations/status"
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

## Export download

Download the finished relations export:

```plaintext
GET /groups/:id/export_relations/download
```

| Attribute      | Type           | Required | Description                                       |
|----------------|----------------|----------|---------------------------------------------------|
| `id`           | integer/string | yes      | ID of the group owned by the authenticated user.  |
| `relation`     | string         | yes      | Name of the group top-level relation to download. |
| `batched`      | boolean        | no       | Whether the export is batched.                    |
| `batch_number` | integer        | no       | Number of export batch to download.               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/groups/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## Related topics

- [Project relations export API](project_relations_export.md)
