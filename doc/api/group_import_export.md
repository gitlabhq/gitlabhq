# Group Import/Export API

> Introduced in GitLab 12.8 as an experimental feature. May change in future releases.

Group Import/Export functionality allows to export group structure and import it at a new location.
Used in combination with [Project Import/Export](project_import_export.md) it allows you to preserve connections with group level relations
(e.g. a connection between a project issue and group epic).

Group Export includes:

1. Group Milestones
1. Group Boards
1. Group Labels
1. Group Badges
1. Group Members
1. Sub-groups (each sub-group includes all data above)

## Schedule new export

Start a new group export.

```text
POST /groups/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the groupd owned by the authenticated user |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/export
```

```json
{
  "message": "202 Accepted"
}
```

## Export download

Download the finished export.

```text
GET /groups/:id/export/download
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name --remote-name https://gitlab.example.com/api/v4/groups/1/export/download
```

```shell
ls *export.tar.gz
2020-12-05_22-11-148_namespace_export.tar.gz
```

Time spent on exporting a group may vary depending on a size of the group. Export download endpoint will return exported archive once it is available. 404 is returned otherwise.

## Import a file

```text
POST /groups/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `name` | string | yes | The name of the group to be imported |
| `path` | string | yes | Name and path for new group |
| `file` | string | yes | The file to be uploaded |
| `parent_id` | integer | no | ID of a parent group that the group will be imported into. Defaults to the current user's namespace if not provided. |

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "name=imported-group" --form "path=imported-group" --form "file=@/path/to/file" https://gitlab.example.com/api/v4/groups/import
```
