---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected branches API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Valid access levels

The access levels are defined in the `ProtectedRefAccess.allowed_access_levels` method. The following levels are recognized:

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## List protected branches

> - Deploy key information [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) in GitLab 16.0.

Gets a list of [protected branches](../user/project/repository/branches/protected.md) from a project
as they are defined in the UI. If a wildcard is set, it is returned instead of the exact name
of the branches that match that wildcard.

```plaintext
GET /projects/:id/protected_branches
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `search` | string | no | Name or part of the name of protected branches to be searched for |

In the following example, the project ID is `5`.

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
  },
  ...
]
```

Users on GitLab Premium or Ultimate also see
the `user_id`, `group_id` and `inherited` parameters. If the `inherited` parameter
exists, means the setting was inherited from the project's group.

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
  },
  ...
]
```

## Get a single protected branch or wildcard protected branch

Gets a single protected branch or wildcard protected branch.

```plaintext
GET /projects/:id/protected_branches/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name` | string | yes | The name of the branch or wildcard |

In the following example, the project ID is `5` and branch name is `main`:

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
the `user_id` and `group_id` parameters:

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

> - `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

Protects a single repository branch or several project repository
branches using a wildcard protected branch.

```plaintext
POST /projects/:id/protected_branches
```

| Attribute                                    | Type | Required | Description |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                                       | string         | yes | The name of the branch or wildcard. |
| `allow_force_push`                           | boolean        | no  | When enabled, members who can push to this branch can also force push. (default: `false`) |
| `allowed_to_merge`                           | array          | no  | Array of merge access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_push`                            | array          | no  | Array of push access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_unprotect`                       | array          | no  | Array of unprotect access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. The access level `No access` is not available for this field. Premium and Ultimate only. |
| `code_owner_approval_required`               | boolean        | no  | Prevent pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). (defaults: false) Premium and Ultimate only. |
| `merge_access_level`                         | integer        | no  | Access levels allowed to merge. (defaults: `40`, Maintainer role). |
| `push_access_level`                          | integer        | no  | Access levels allowed to push. (defaults: `40`, Maintainer role) |
| `unprotect_access_level`                     | integer        | no  | Access levels allowed to unprotect. (defaults: `40`, Maintainer role) |

In the following example, the project ID is `5` and branch name is `*-stable`.

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

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Elements in the `allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect` array should take the
form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`.
Each user must have access to the project and each group must [have this project shared](../user/project/members/sharing_projects_groups.md).
These access levels allow more granular control over protected branch access.
For more information, see [Add a group to protected branches](../user/project/repository/branches/protected.md#add-a-group-to-protected-branches).

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
      "access_level": null
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

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

Elements in the `allowed_to_push` array should take the form `{user_id: integer}`, `{group_id: integer}`,
`{deploy_key_id: integer}`, or `{access_level: integer}`.
The deploy key must be enabled for your project and it must have write access to your project repository.
For other requirements, see [Allow deploy keys to push to a protected branch](../user/project/repository/branches/protected.md#allow-deploy-keys-to-push-to-a-protected-branch).

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

The following example response includes:

- An protected branch with ID `101`.
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

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

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
  }'
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

## Unprotect repository branches

Unprotects the given protected branch or wildcard protected branch.

```plaintext
DELETE /projects/:id/protected_branches/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name` | string | yes | The name of the branch |

In the following example, the project ID is `5` and branch name is `*-stable`.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## Update a protected branch

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101903) in GitLab 15.6.
> - `deploy_key_id` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) in GitLab 17.5.

Updates a protected branch.

```plaintext
PATCH /projects/:id/protected_branches/:name
```

| Attribute                                    | Type           | Required | Description |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                                       | string         | yes | The name of the branch or wildcard. |
| `allow_force_push`                           | boolean        | no  | When enabled, members who can push to this branch can also force push. |
| `allowed_to_merge`                           | array          | no  | Array of merge access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_push`                            | array          | no  | Array of push access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}`, or `{access_level: integer}`. Premium and Ultimate only. |
| `allowed_to_unprotect`                       | array          | no  | Array of unprotect access levels, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, `{access_level: integer}`, or `{id: integer, _destroy: true}` to destroy an existing access level. The access level `No access` is not available for this field. Premium and Ultimate only. |
| `code_owner_approval_required`               | boolean        | no       | Prevent pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). Premium and Ultimate only. |

In the following example, the project ID is `5` and branch name is `feature-branch`.

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

Elements in the `allowed_to_push`, `allowed_to_merge` and `allowed_to_unprotect` arrays should be one of `user_id`, `group_id` or
`access_level`, and take the form `{user_id: integer}`, `{group_id: integer}` or
`{access_level: integer}`.

`allowed_to_push` includes an extra element, `deploy_key_id`, that takes the form `{deploy_key_id: integer}`.

To update:

- `user_id`: Ensure the updated user has access to the project. You must also pass the
  `id` of the `access_level` in the respective hash.
- `group_id`: Ensure the updated group [has this project shared](../user/project/members/sharing_projects_groups.md).
  You must also pass the `id` of the `access_level` in the respective hash.
- `deploy_key_id`: Ensure the deploy key is enabled for your project and it must have write access to your project repository.

To delete:

- You must pass `_destroy` set to `true`. See the following examples.

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

## Related topics

- [Protected branches](../user/project/repository/branches/protected.md)
- [Branches](../user/project/repository/branches/_index.md)
- [Branches API](branches.md)
