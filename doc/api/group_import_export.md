---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group import and export API **(FREE)**

Use the group import and export API to export a group structure and import it to a new location.
When you use the group import and export API with the [project import and export API](project_import_export.md), you can preserve connections with
group-level relationships, such as connections between project issues and group epics.

Group exports include the following:

- Group milestones
- Group boards
- Group labels
- Group badges
- Group members
- Subgroups. Each subgroup includes all data above
- Group wikis **(PREMIUM SELF)**

To preserve group-level relationships from imported projects, you should run group import and export first. This way, you can import project exports into the desired group structure.

Imported groups have a `private` visibility level unless you import them into a parent group.
If you import groups into a parent group, the subgroups inherit by default a similar level of visibility.

To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make sure these users exist before importing the desired groups.

## Prerequisites

For information on prerequisites for group import and export API, see prerequisites for
[migrating groups by uploading an export file](../user/group/import/index.md#preparation).

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
group=1
token=secret
curl --request GET\
     --header "PRIVATE-TOKEN: ${token}" \
     --output download_group_${group}.tar.gz \
     "https://gitlab.example.com/api/v4/groups/${group}/export/download"
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
| `parent_id` | integer | no | ID of a parent group to import the group into. Defaults to the current user's namespace if not provided. |

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
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](settings.md#change-application-settings) or the [Admin Area](../user/admin_area/settings/account_and_limit_settings.md). Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to 0 in GitLab 13.8.
