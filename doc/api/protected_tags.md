---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected tags API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Valid access levels

These access levels are recognized:

- `0`: No access
- `30`: Developer role
- `40`: Maintainer role

## List protected tags

> - Deploy key information [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) in GitLab 16.0.

Gets a list of [protected tags](../user/project/protected_tags.md) from a project.
This function takes pagination parameters `page` and `per_page` to restrict the list of protected tags.

```plaintext
GET /projects/:id/protected_tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/5/protected_tags"
```

Example response:

```json
[
  {
    "name": "release-1-0",
    "create_access_levels": [
      {
        "id":1,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 2,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ]
  },
  ...
]
```

## Get a single protected tag or wildcard protected tag

Gets a single protected tag or wildcard protected tag.

```plaintext
GET /projects/:id/protected_tags/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the tag or wildcard. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
```

Example response:

```json
{
  "name": "release-1-0",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ]
}
```

## Protect repository tags

> - `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166866) in GitLab 17.5.

Protects a single repository tag, or several project repository
tags, using a wildcard protected tag.

```plaintext
POST /projects/:id/protected_tags
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
   "https://gitlab.example.com/api/v4/projects/5/protected_tags" -d '{
   "allowed_to_create" : [
      {
         "user_id" : 1
      },
      {
         "access_level" : 30
      }
   ],
   "create_access_level" : 30,
   "name" : "*-stable"
}'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the tag or wildcard. |
| `allowed_to_create`   | array  | no | Array of access levels allowed to create tags, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `create_access_level` | string | no | Access levels allowed to create. Default: `40`, for Maintainer role. |

Example response:

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ]
}
```

### Example with user and group access

Elements in the `allowed_to_create` array should take the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`.
Each user must have access to the project and each group must [have this project shared](../user/project/members/sharing_projects_groups.md).
These access levels allow more granular control over protected tag access.
For more information, see [Add a group to protected tags](../user/project/protected_tags.md#add-a-group-to-protected-tags).

This example request demonstrates how to create a protected tag that allows creation access
to a specific user and group:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_tags?name=*-stable&allowed_to_create%5B%5D%5Buser_id%5D=10&allowed_to_create%5B%5D%5Bgroup_id%5D=20"
```

The example response includes:

- A protected tag with name `"*-stable"`.
- `create_access_levels` with ID `1` for user with ID `10`.
- `create_access_levels` with ID `2` for group with ID `20`.

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": null,
      "user_id": 10,
      "group_id": null,
      "access_level_description": "Administrator"
    },
    {
      "id": 2,
      "access_level": null,
      "user_id": null,
      "group_id": 20,
      "access_level_description": "Example Create Group"
    }
  ]
}
```

## Unprotect repository tags

Unprotects the given protected tag or wildcard protected tag.

```plaintext
DELETE /projects/:id/protected_tags/:name
```

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the tag. |

## Related topics

- [Tags API](tags.md) for all tags
- [Tags](../user/project/repository/tags/_index.md) user documentation
- [Protected tags](../user/project/protected_tags.md) user documentation
