---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group-level protected branches API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110603) in GitLab 15.9 [with a flag](../administration/feature_flags.md) named `group_protected_branches`. Disabled by default.
> - Flag `group_protected_branches` [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116779) [flag](../administration/feature_flags.md) to `allow_protected_branches_for_group` GitLab 15.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/500250) in GitLab 17.6. Feature flag `group_protected_branches` removed.

Use the protected branches API for groups to manage protected branch rules.
It provides endpoints to list, create, update, and delete protected branch rules that apply to projects belonging to a group.

WARNING:
Protected branch settings for groups are restricted to top-level groups only.

## Valid access levels

The access levels are defined in the `ProtectedRefAccess.allowed_access_levels` method.
These levels are recognized:

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## List protected branches

Gets a list of protected branches from a group. If a wildcard is set, it is returned instead
of the exact name of the branches that match that wildcard.

```plaintext
GET /groups/:id/protected_branches
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `search` | string | no | Name or part of the name of protected branches to be searched for. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 1,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  ...
]
```

## Get a single protected branch or wildcard protected branch

Gets a single protected branch or wildcard protected branch.

```plaintext
GET /groups/:id/protected_branches/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the branch or wildcard. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/main"
```

Example response:

```json
{
  "id": 1,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
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

Protects a single repository branch using a wildcard protected branch.

```plaintext
POST /groups/:id/protected_branches
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

| Attribute                                    | Type | Required | Description |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | integer or string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `name`                                       | string         | yes | The name of the branch or wildcard. |
| `allow_force_push`                           | boolean        | no  | Allow all users with push access to force push. Default: `false`. |
| `allowed_to_merge`                           | array          | no  | Array of access levels allowed to merge, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. |
| `allowed_to_push`                            | array          | no  | Array of access levels allowed to push, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. |
| `allowed_to_unprotect`                       | array          | no  | Array of access levels allowed to unprotect, with each described by a hash of the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. |
| `code_owner_approval_required`               | boolean        | no  | Prevent pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). Default: `false`. |
| `merge_access_level`                         | integer        | no  | Access levels allowed to merge. Defaults: `40`, Maintainer role. |
| `push_access_level`                          | integer        | no  | Access levels allowed to push. Defaults: `40`, Maintainer role. |
| `unprotect_access_level`                     | integer        | no  | Access levels allowed to unprotect. Defaults: `40`, Maintainer role. |

Example response:

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  1,
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

### Example with user and group access

Elements in the `allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect` array should take the
form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`. Each user must have
access to the project and each group must
[have this project shared](../user/project/members/sharing_projects_groups.md). These access levels
allow [more granular control over protected branch access](../user/project/repository/branches/protected.md).

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=1"
```

Example response:

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": null,
      "user_id": 1,
      "group_id": null,
      "access_level_description": "Administrator"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  1,
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

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [{"access_level": 30}],
    "allowed_to_merge": [{
        "access_level": 30
      },{
        "access_level": 40
      }
    ]}'
    --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

Example response:

```json
{
    "id": 5,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 1,
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
DELETE /groups/:id/protected_branches/:name
```

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/*-stable"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the branch. |

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

## Update a protected branch

Updates a protected branch.

```plaintext
PATCH /groups/:id/protected_branches/:name
```

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

| Attribute                                    | Type           | Required | Description                                                                                                                          |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).                       |
| `name`                                       | string         | yes      | The name of the branch.                                                                                                               |
| `allow_force_push`                           | boolean        | no       | When enabled, members who can push to this branch can also force push.                                                               |
| `allowed_to_push`                            | array          | no       | Array of push access levels, with each described by a hash.                                                                          |
| `allowed_to_merge`                           | array          | no       | Array of merge access levels, with each described by a hash.                                                                         |
| `allowed_to_unprotect`                       | array          | no       | Array of unprotect access levels, with each described by a hash.                                                                     |
| `code_owner_approval_required`               | boolean        | no       | Prevent pushes to this branch if it matches an item in the [`CODEOWNERS` file](../user/project/codeowners/_index.md). Default: `false`. |

Elements in the `allowed_to_push`, `allowed_to_merge` and `allowed_to_unprotect` arrays should:

- Be one of `user_id`, `group_id`, or `access_level`.
- Take the form `{user_id: integer}`, `{group_id: integer}`, or `{access_level: integer}`.

To update:

- `user_id`: Ensure the updated user has access to the project. You must also pass the
  `id` of the `access_level` in the respective hash.
- `group_id`: Ensure the updated group [has this project shared](../user/project/members/sharing_projects_groups.md).
  You must also pass the `id` of the `access_level` in the respective hash.

To delete:

- You must pass `_destroy` set to `true`. See the following examples.

### Example: create a `push_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{access_level: 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
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
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
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
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

Example response:

```json
{
   "name": "main",
   "push_access_levels": []
}
```
