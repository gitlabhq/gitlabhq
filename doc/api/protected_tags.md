---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected tags API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [protected tags](../user/project/protected_tags.md).

## Valid access levels

These access levels are recognized:

- `0`: No access
- `30`: Developer role
- `40`: Maintainer role

## List protected tags

{{< history >}}

- Deploy key information [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) in GitLab 16.0.

{{< /history >}}

Get a list of [protected tags](../user/project/protected_tags.md) from a project.
This function takes pagination parameters `page` and `per_page` to restrict the list of protected tags.

```plaintext
GET /projects/:id/protected_tags
```

Supported attributes:

| Attribute | Type              | Required | Description                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | array   | Array of create access level configurations. |
| `create_access_levels[].access_level`             | integer | Access level for creating tags. |
| `create_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `create_access_levels[].deploy_key_id`            | integer | ID of the deploy key with create access. |
| `create_access_levels[].group_id`                 | integer | ID of the group with create access. Premium and Ultimate only. |
| `create_access_levels[].id`                       | integer | ID of the create access level configuration. |
| `create_access_levels[].user_id`                  | integer | ID of the user with create access. Premium and Ultimate only. |
| `name`                                            | string  | Name of the protected tag. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags"
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
  }
]
```

## Get a protected tag or wildcard protected tag

Get a single protected tag or wildcard protected tag.

```plaintext
GET /projects/:id/protected_tags/:name
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`    | string            | Yes      | Name of the tag or wildcard. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | array   | Array of create access level configurations. |
| `create_access_levels[].access_level`             | integer | Access level for creating tags. |
| `create_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `create_access_levels[].deploy_key_id`            | integer | ID of the deploy key with create access. |
| `create_access_levels[].group_id`                 | integer | ID of the group with create access. Premium and Ultimate only. |
| `create_access_levels[].id`                       | integer | ID of the create access level configuration. |
| `create_access_levels[].user_id`                  | integer | ID of the user with create access. Premium and Ultimate only. |
| `name`                                            | string  | Name of the protected tag. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
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

## Protect a repository tag

{{< history >}}

- `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166866) in GitLab 17.5.

{{< /history >}}

Protect a single repository tag, or several project repository
tags, using a wildcard protected tag.

```plaintext
POST /projects/:id/protected_tags
```

Supported attributes:

| Attribute             | Type              | Required | Description |
|-----------------------|-------------------|----------|-------------|
| `id`                  | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                | string            | Yes      | Name of the tag or wildcard. |
| `allowed_to_create`   | array             | No       | Array of access levels allowed to create tags, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `create_access_level` | integer           | No       | Access levels allowed to create. Default is `40` (Maintainer role). |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | array   | Array of create access level configurations. |
| `create_access_levels[].access_level`             | integer | Access level for creating tags. |
| `create_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `create_access_levels[].deploy_key_id`            | integer | ID of the deploy key with create access. |
| `create_access_levels[].group_id`                 | integer | ID of the group with create access. Premium and Ultimate only. |
| `create_access_levels[].id`                       | integer | ID of the create access level configuration. |
| `create_access_levels[].user_id`                  | integer | ID of the user with create access. Premium and Ultimate only. |
| `name`                                            | string  | Name of the protected tag. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data '{
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
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags?name=*-stable&allowed_to_create%5B%5D%5Buser_id%5D=10&allowed_to_create%5B%5D%5Bgroup_id%5D=20"
```

This example response includes:

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

Unprotect the given protected tag or wildcard protected tag.

```plaintext
DELETE /projects/:id/protected_tags/:name
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`    | string            | Yes      | Name of the tag. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

## Related topics

- [Tags API](tags.md) for all tags
- [Tags](../user/project/repository/tags/_index.md) user documentation
- [Protected tags](../user/project/protected_tags.md) user documentation
