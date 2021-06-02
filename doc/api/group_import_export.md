---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group Import/Export API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20353) in GitLab 12.8.

Group Import/Export allows you to export group structure and import it to a new location.
When used with [Project Import/Export](project_import_export.md), you can preserve connections with
group-level relationships, such as connections between project issues and group epics.

Group exports include the following:

- Group milestones
- Group boards
- Group labels
- Group badges
- Group members
- Subgroups. Each subgroup includes all data above
- Group wikis **(PREMIUM SELF)**

## Schedule new export

Start a new group export.

```plaintext
POST /groups/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/export"
```

```json
{
  "message": "202 Accepted"
}
```

## Export download

Download the finished export.

```plaintext
GET /groups/:id/export/download
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name \
     --remote-name "https://gitlab.example.com/api/v4/groups/1/export/download"
```

```shell
ls *export.tar.gz
2020-12-05_22-11-148_namespace_export.tar.gz
```

Time spent on exporting a group may vary depending on a size of the group. This endpoint
returns either:

- The exported archive (when available)
- A 404 message

## Import a file

```plaintext
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
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "name=imported-group" --form "path=imported-group" \
     --form "file=@/path/to/file" "https://gitlab.example.com/api/v4/groups/import"
```

NOTE:
The maximum import file size can be set by the Administrator, default is `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](settings.md#change-application-settings) or the [Admin Area](../user/admin_area/settings/account_and_limit_settings.md). Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50MB to 0 in GitLab 13.8.

## Important notes

Note the following:

- To preserve group-level relationships from imported projects, run Group Import/Export first,
  to allow project imports into the desired group structure.
- Imported groups are given a `private` visibility level, unless imported into a parent group.
- If imported into a parent group, subgroups will inherit a similar level of visibility, unless otherwise restricted.
- To preserve the member list and their respective permissions on imported groups,
  review the users in these groups. Make sure these users exist before importing the desired groups.
