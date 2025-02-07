---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group import and export API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the group import and export API to export a group structure and import it to a new location.
When you use the group import and export API with the [project import and export API](project_import_export.md), you can preserve connections with
group-level relationships, such as connections between project issues and group epics.

Group exports include the following:

- Group milestones
- Group boards
- Group labels
- Group badges
- Group members
- Group wikis (Premium and Ultimate only)
- Subgroups. Each subgroup includes all data above

To preserve group-level relationships from imported projects, you should run group export and import first. This way,
you can import project exports into the desired group structure.

Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/405168), imported groups have a `private`
visibility level unless you import them into a parent group. By default, if you import groups into a parent group,
the subgroups inherit the same level of visibility as the parent.

To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make sure these users exist before importing the desired groups.

## Prerequisites

- For information on prerequisites for group import and export API, see prerequisites for
  [migrating groups by uploading an export file](../user/project/settings/import_export.md#preparation).

## Schedule new export

Start a new group export.

```plaintext
POST /groups/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | ID of the group |

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
| `id`      | integer/string | yes      | ID of the group |

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

The maximum import file size can be set by the Administrator on GitLab Self-Managed (default is `0` (unlimited)).
As an administrator, you can modify the maximum import file size either:

- In the [**Admin** area](../administration/settings/import_and_export_settings.md).
- By using the `max_import_size` option in the [Application settings API](settings.md#update-application-settings).

For information on the maximum import file size on GitLab.com, see
[Account and limit settings](../user/gitlab_com/_index.md#account-and-limit-settings).

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

## Related topics

- [Project import and export API](project_import_export.md)
