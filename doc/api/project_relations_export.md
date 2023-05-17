---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project Relations Export API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70330) in GitLab 14.4 behind the `bulk_import` [feature flag](../administration/feature_flags.md), disabled by default.

FLAG:
On GitLab.com, this feature is available.
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to
[disable the `bulk_import` flag](../administration/feature_flags.md).
The feature is not ready for production use. It is still in experimental stage and might change in the future.

With the Project Relations Export API, you can partially export project structure. This API is
similar to [project export](project_import_export.md),
but it exports each top-level relation (for example, milestones/boards/labels) as a separate file
instead of one archive. The project relations export API is primarily used in
[group migration](../user/group/import/index.md)
to support group project import.

## Schedule new export

Start a new project relations export:

```plaintext
POST /projects/:id/export_relations
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the project owned by the authenticated user. |

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

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the project owned by the authenticated user. |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
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
    "relation": "project_badges",
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
GET /projects/:id/export_relations/download
```

| Attribute       | Type           | Required | Description                              |
| --------------- | -------------- | -------- | ---------------------------------------- |
| `id`            | integer/string | yes      | ID of the project owned by the authenticated user. |
| `relation`      | string         | yes      | Name of the project top-level relation to download. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```
