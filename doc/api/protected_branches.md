---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected branches API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [protected branches](../user/project/repository/branches/protected.md).

GitLab Premium and GitLab Ultimate support more granular protections for pushing to branches.
Administrators can grant permission to modify and push to protected branches only to deploy keys,
instead of specific users.

## Valid access levels

The `ProtectedRefAccess.allowed_access_levels` method defines the following access levels:

- `0`: No access
- `30`: Developer role
- `40`: Maintainer role
- `60`: Administrator

## List protected branches

{{< history >}}

- Deploy key information [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) in GitLab 16.0.

{{< /history >}}

Get a list of [protected branches](../user/project/repository/branches/protected.md) from a project
as they are defined in the UI. If a wildcard is set, it is returned instead of the exact name
of the branches that match that wildcard.

```plaintext
GET /projects/:id/protected_branches
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`  | string            | No       | Name or part of the name of protected branches to search for. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                        | Type    | Description |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | boolean | If `true`, force push is allowed on this branch. |
| `code_owner_approval_required`                   | boolean | If `true`, code owner approval is required for pushes to this branch. |
| `id`                                             | integer | ID of the protected branch. |
| `inherited`                                      | boolean | If `true`, protection settings are inherited from parent group. Premium and Ultimate only. |
| `merge_access_levels`                            | array   | Array of merge access level configurations. |
| `merge_access_levels[].access_level`             | integer | Access level for merging. |
| `merge_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `merge_access_levels[].group_id`                 | integer | ID of the group with merge access. Premium and Ultimate only. |
| `merge_access_levels[].id`                       | integer | ID of the merge access level configuration. |
| `merge_access_levels[].user_id`                  | integer | ID of the user with merge access. Premium and Ultimate only. |
| `name`                                           | string  | Name of the protected branch. |
| `push_access_levels`                             | array   | Array of push access level configurations. |
| `push_access_levels[].access_level`              | integer | Access level for pushing. |
| `push_access_levels[].access_level_description`  | string  | Human-readable description of the access level. |
| `push_access_levels[].deploy_key_id`             | integer | ID of the deploy key with push access. |
| `push_access_levels[].group_id`                  | integer | ID of the group with push access. Premium and Ultimate only. |
| `push_access_levels[].id`                        | integer | ID of the push access level configuration. |
| `push_access_levels[].user_id`                   | integer | ID of the user with push access. Premium and Ultimate only. |

In the following example request, the project ID is `5`.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

The following example response includes:

- Two protected branches with IDs `100` and `101`.
- `push_access_levels` with IDs `1001`, `1002`, and `1003`.
- `merge_access_levels` with IDs `2001` and `2002`.

```json
[
  {
    "id": 100,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 101,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1003,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  2002,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  }
]
```

Users on GitLab Premium or Ultimate also see
the `user_id`, `group_id`, and `inherited` parameters. If the `inherited` parameter
exists, the setting was inherited from the project's group.

The following example response includes:

- One protected branch with ID `100`.
- `push_access_levels` with IDs `1001` and `1002`.
- `merge_access_levels` with ID `2001`.

```json
[
  {
    "id": 101,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1,
        "user_id": null,
        "group_id": null
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": null,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Example Merge Group"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false,
    "inherited": true
  }
]
```

## Get a single protected branch or wildcard protected branch

Get a single protected branch or wildcard protected branch.

```plaintext
GET /projects/:id/protected_branches/:name
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`    | string            | Yes      | Name of the branch or wildcard. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                        | Type    | Description |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | boolean | If `true`, force push is allowed on this branch. |
| `code_owner_approval_required`                   | boolean | If `true`, code owner approval is required for pushes to this branch. |
| `id`                                             | integer | ID of the protected branch. |
| `merge_access_levels`                            | array   | Array of merge access level configurations. |
| `merge_access_levels[].access_level`             | integer | Access level for merging. |
| `merge_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `merge_access_levels[].group_id`                 | integer | ID of the group with merge access. Premium and Ultimate only. |
| `merge_access_levels[].id`                       | integer | ID of the merge access level configuration. |
| `merge_access_levels[].user_id`                  | integer | ID of the user with merge access. Premium and Ultimate only. |
| `name`                                           | string  | Name of the protected branch. |
| `push_access_levels`                             | array   | Array of push access level configurations. |
| `push_access_levels[].access_level`              | integer | Access level for pushing. |
| `push_access_levels[].access_level_description`  | string  | Human-readable description of the access level. |
| `push_access_levels[].group_id`                  | integer | ID of the group with push access. Premium and Ultimate only. |
| `push_access_levels[].id`                        | integer | ID of the push access level configuration. |
| `push_access_levels[].user_id`                   | integer | ID of the user with push access. Premium and Ultimate only. |

In the following example request, the project ID is `5` and branch name is `main`:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

Example response:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

Users on GitLab Premium or Ultimate also see
the `user_id` and `group_id` parameters.

Example response:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 1234,
      "access_level_description": "Example Merge Group"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## Protect repository branches

{{< history >}}

- `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

{{< /history >}}

Protect a single repository branch or several project repository
branches using a wildcard protected branch.

```plaintext
POST /projects/:id/protected_branches
```

Supported attributes:

| Attribute                      | Type              | Required | Description |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                         | string            | Yes      | Name of the branch or wildcard. |
| `allow_force_push`             | boolean           | No       | If `true`, members who can push to this branch can also force push. Default is `false`. |
| `allowed_to_merge`             | array             | No       | Array of merge access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_push`              | array             | No       | Array of push access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_unprotect`         | array             | No       | Array of unprotect access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Access level `No access` is not available for this field. Premium and Ultimate only. |
| `code_owner_approval_required` | boolean           | No       | If `true`, prevents pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). Default is `false`. Premium and Ultimate only. |
| `merge_access_level`           | integer           | No       | Access levels allowed to merge. Default is `40` (Maintainer role). |
| `push_access_level`            | integer           | No       | Access levels allowed to push. Default is `40` (Maintainer role). |
| `unprotect_access_level`       | integer           | No       | Access levels allowed to unprotect. Default is `40` (Maintainer role). |

When you configure access levels:

- You can set multiple access levels simultaneously for `allowed_to_push` and `allowed_to_merge`.
- The most permissive access level determines who can perform the action.

This behavior differs from the UI, which automatically clears other role selections
when you select **No one** (`access_level: 0`).

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                            | Type    | Description |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | boolean | If `true`, force push is allowed on this branch. |
| `code_owner_approval_required`                       | boolean | If `true`, code owner approval is required for pushes to this branch. |
| `id`                                                 | integer | ID of the protected branch. |
| `merge_access_levels`                                | array   | Array of merge access level configurations. |
| `merge_access_levels[].access_level`                 | integer | Access level for merging. |
| `merge_access_levels[].access_level_description`     | string  | Human-readable description of the access level. |
| `merge_access_levels[].group_id`                     | integer | ID of the group with merge access. Premium and Ultimate only. |
| `merge_access_levels[].id`                           | integer | ID of the merge access level configuration. |
| `merge_access_levels[].user_id`                      | integer | ID of the user with merge access. Premium and Ultimate only. |
| `name`                                               | string  | Name of the protected branch. |
| `push_access_levels`                                 | array   | Array of push access level configurations. |
| `push_access_levels[].access_level`                  | integer | Access level for pushing. |
| `push_access_levels[].access_level_description`      | string  | Human-readable description of the access level. |
| `push_access_levels[].deploy_key_id`                 | integer | ID of the deploy key with push access. |
| `push_access_levels[].group_id`                      | integer | ID of the group with push access. Premium and Ultimate only. |
| `push_access_levels[].id`                            | integer | ID of the push access level configuration. |
| `push_access_levels[].user_id`                       | integer | ID of the user with push access. Premium and Ultimate only. |
| `unprotect_access_levels`                            | array   | Array of unprotect access level configurations. |
| `unprotect_access_levels[].access_level`             | integer | Access level for unprotecting. |
| `unprotect_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `unprotect_access_levels[].group_id`                 | integer | ID of the group with unprotect access. Premium and Ultimate only. |
| `unprotect_access_levels[].id`                       | integer | ID of the unprotect access level configuration. |
| `unprotect_access_levels[].user_id`                  | integer | ID of the user with unprotect access. Premium and Ultimate only. |

In the following example request, the project ID is `5` and branch name is `*-stable`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

The example response includes:

- A protected branch with ID `101`.
- `push_access_levels` with ID `1001`.
- `merge_access_levels` with ID `2001`.
- `unprotect_access_levels` with ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

Users on GitLab Premium or Ultimate also see
the `user_id` and `group_id` parameters:

The following example response includes:

- A protected branch with ID `101`.
- `push_access_levels` with ID `1001`.
- `merge_access_levels` with ID `2001`.
- `unprotect_access_levels` with ID `3001`.

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### Example with user push access and group merge access

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Elements in the `allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect` array should take the
form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`.
Each user must have access to the project and each group must [have this project shared](../user/project/members/sharing_projects_groups.md).
These access levels allow more granular control over protected branch access.
For more information, see [configure group permissions](../user/project/repository/branches/protected.md#with-group-permissions).

The following example request creates a protected branch with user push access and group merge access.
The `user_id` is `2` and the `group_id` is `3`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=2&allowed_to_merge%5B%5D%5Bgroup_id%5D=3"
```

The following example response includes:

- A protected branch with ID `101`.
- `push_access_levels` with ID `1001`.
- `merge_access_levels` with ID `2001`.
- `unprotect_access_levels` with ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": 2,
      "group_id": null,
      "access_level_description": "Administrator"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 3,
      "access_level_description": "Example Merge Group"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### Example with deploy key access

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

{{< /history >}}

Elements in the `allowed_to_push` array should take the form `{user_id: integer}`, `{group_id: integer}`,
`{deploy_key_id: integer}`, or `{access_level: integer}`.
The deploy key must be enabled for your project and it must have write access to your project repository.
For other requirements, see [Allow deploy keys to push to a protected branch](../user/project/repository/branches/protected.md#enable-deploy-key-access).

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

The following example response includes:

- A protected branch with ID `101`.
- `push_access_levels` with ID `1001`.
- `merge_access_levels` with ID `2001`.
- `unprotect_access_levels` with ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": null,
      "group_id": null,
      "deploy_key_id": 1,
      "access_level_description": "Deploy"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### Example with allow to push and allow to merge access

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Moved to GitLab Premium in 13.9.

{{< /history >}}

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [
      {"access_level": 30}
    ],
    "allowed_to_merge": [
      {"access_level": 30},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

The following example response includes:

- A protected branch with ID `105`.
- `push_access_levels` with ID `1001`.
- `merge_access_levels` with IDs `2001` and `2002`.
- `unprotect_access_levels` with ID `3001`.

```json
{
    "id": 105,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 2001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2002,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 3001,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

### Examples with unprotect access levels

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To create a protected branch where only a specific group can unprotect the branch:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "production",
    "allowed_to_unprotect": [
      {"group_id": 789}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

To allow multiple types of users to unprotect a branch:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_unprotect": [
      {"user_id": 123},
      {"group_id": 456},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

This configuration allows these users to unprotect the branch:

- The user with ID `123`.
- Members of the group with ID `456`.
- Users with at least the Maintainer role (access level 40).

## Unprotect repository branches

Unprotect the given protected branch or wildcard protected branch.

```plaintext
DELETE /projects/:id/protected_branches/:name
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`    | string            | Yes      | Name of the branch. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

In the following example request, the project ID is `5` and branch name is `*-stable`:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## Update a protected branch

{{< history >}}

- `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

{{< /history >}}

Update a protected branch.

```plaintext
PATCH /projects/:id/protected_branches/:name
```

Supported attributes:

| Attribute                      | Type              | Required | Description |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                         | string            | Yes      | Name of the branch or wildcard. |
| `allow_force_push`             | boolean           | No       | If `true`, members who can push to this branch can also force push. |
| `allowed_to_merge`             | array             | No       | Array of merge access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_push`              | array             | No       | Array of push access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_unprotect`         | array             | No       | Array of unprotect access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{access_level: integer}`, or `{id: integer, _destroy: true}` to destroy an existing access level. Access level `No access` is not available for this field. Premium and Ultimate only. |
| `code_owner_approval_required` | boolean           | No       | If `true`, prevents pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). Premium and Ultimate only. |

For information about how access levels interact when you set multiple values,
see [Protect repository branches](#protect-repository-branches).

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                            | Type    | Description |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | boolean | If `true`, force push is allowed on this branch. |
| `code_owner_approval_required`                       | boolean | If `true`, code owner approval is required for pushes to this branch. |
| `id`                                                 | integer | ID of the protected branch. |
| `merge_access_levels`                                | array   | Array of merge access level configurations. |
| `merge_access_levels[].access_level`                 | integer | Access level for merging. |
| `merge_access_levels[].access_level_description`     | string  | Human-readable description of the access level. |
| `merge_access_levels[].group_id`                     | integer | ID of the group with merge access. Premium and Ultimate only. |
| `merge_access_levels[].id`                           | integer | ID of the merge access level configuration. |
| `merge_access_levels[].user_id`                      | integer | ID of the user with merge access. Premium and Ultimate only. |
| `name`                                               | string  | Name of the protected branch. |
| `push_access_levels`                                 | array   | Array of push access level configurations. |
| `push_access_levels[].access_level`                  | integer | Access level for pushing. |
| `push_access_levels[].access_level_description`      | string  | Human-readable description of the access level. |
| `push_access_levels[].deploy_key_id`                 | integer | ID of the deploy key with push access. |
| `push_access_levels[].group_id`                      | integer | ID of the group with push access. Premium and Ultimate only. |
| `push_access_levels[].id`                            | integer | ID of the push access level configuration. |
| `push_access_levels[].user_id`                       | integer | ID of the user with push access. Premium and Ultimate only. |
| `unprotect_access_levels`                            | array   | Array of unprotect access level configurations. |
| `unprotect_access_levels[].access_level`             | integer | Access level for unprotecting. |
| `unprotect_access_levels[].access_level_description` | string  | Human-readable description of the access level. |
| `unprotect_access_levels[].group_id`                 | integer | ID of the group with unprotect access. Premium and Ultimate only. |
| `unprotect_access_levels[].id`                       | integer | ID of the unprotect access level configuration. |
| `unprotect_access_levels[].user_id`                  | integer | ID of the user with unprotect access. Premium and Ultimate only. |

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

Elements in the `allowed_to_push`, `allowed_to_merge`, and `allowed_to_unprotect` arrays should
be one of `user_id`, `group_id`, or `access_level`, and take the form `{user_id: integer}`, `{group_id: integer}` or
`{access_level: integer}`.

`allowed_to_push` includes an extra element, `deploy_key_id`, that takes the form `{deploy_key_id: integer}`.

To update:

- `user_id`: Ensure the updated user has access to the project. You must also pass the
  `id` of the `access_level` in the respective hash.
- `group_id`: Ensure the updated group [has this project shared](../user/project/members/sharing_projects_groups.md).
  You must also pass the `id` of the `access_level` in the respective hash.
- `deploy_key_id`: Ensure the deploy key is enabled for your project and it must have write access to your project repository.

To delete, you must pass `_destroy` set to `true`. See the following examples.

### Example: create a `push_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"access_level": 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

Example response:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### Example: update a `push_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

Example response:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### Example: delete a `push_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

Example response:

```json
{
   "name": "main",
   "push_access_levels": []
}
```

### Example: update an `unprotect_access_level` record

Prerequisites:

- Users calling this API must be included in the `allowed_to_unprotect` configuration.
- The user specified by `user_id` must be a project member.
- Groups specified by `group_id` must have access to the project.

To modify who can unprotect an existing protected branch, include the `id` of the existing access
level record. For example:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "allowed_to_unprotect": [
      {"id": 17486, "user_id": 3791}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

To remove specific access levels, use `_destroy: true`.

## Related topics

- [Protected branches](../user/project/repository/branches/protected.md)
- [Branches](../user/project/repository/branches/_index.md)
- [Branches API](branches.md)
