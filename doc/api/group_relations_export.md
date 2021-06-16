---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group Relations Export API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59978) in GitLab 13.12.

With the Group Relations Export API, you can partially export group structure. This API is similar
to [group export](group_import_export.md),
but it exports each top-level relation (for example, milestones/boards/labels) as a separate file
instead of one archive. The group relations export API is primarily used in [group migration](../user/group/index.md).

## Schedule new export

Start a new group relations export:

```plaintext
POST /groups/:id/export_relations
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user. |

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

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user. |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/1/export_relations/status"
```

The status can be one of the following:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

- `0` - `started`
- `1` - `finished`
- `-1` - `failed`

```json
[
  {
    "relation": "badges",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.423Z"
  },
  {
    "relation": "boards",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.085Z"
  }
]
```

## Export download

Download the finished relations export:

```plaintext
GET /groups/:id/export_relations/download
```

| Attribute       | Type           | Required | Description                              |
| --------------- | -------------- | -------- | ---------------------------------------- |
| `id`            | integer/string | yes      | ID of the group owned by the authenticated user. |
| `relation`      | string         | yes      | Name of the group top-level relation to download. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/groups/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```
