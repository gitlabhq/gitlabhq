# Protected branches API

>**Note:** This feature was introduced in GitLab 9.5

**Valid access levels**

The access levels are defined in the `ProtectedRefAccess::ALLOWED_ACCESS_LEVELS` constant. Currently, these levels are recognized:
```
0  => No access
30 => Developer access
40 => Master access
```

## List protected branches

Gets a list of protected branches from a project.

```
GET /projects/:id/protected_branches
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_branches'
```

Example response:

```json
[
  {
    "name": "master",
    "push_access_levels": [
      {
        "access_level": 40,
        "access_level_description": "Masters"
      }
    ],
    "merge_access_levels": [
      {
        "access_level": 40,
        "access_level_description": "Masters"
      }
    ]
  },
  ...
]
```

## Get a single protected branch or wildcard protected branch

Gets a single protected branch or wildcard protected branch.

```
GET /projects/:id/protected_branches/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch or wildcard |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_branches/master'
```

Example response:

```json
{
  "name": "master",
  "push_access_levels": [
    {
      "access_level": 40,
      "access_level_description": "Masters"
    }
  ],
  "merge_access_levels": [
    {
      "access_level": 40,
      "access_level_description": "Masters"
    }
  ]
}
```

## Protect repository branches

Protects a single repository branch or several project repository
branches using a wildcard protected branch.

```
POST /projects/:id/protected_branches
```

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch or wildcard |
| `push_access_level` | string | no | Access levels allowed to push (defaults: `40`, master access level) |
| `merge_access_level` | string | no | Access levels allowed to merge (defaults: `40`, master access level) |

Example response:

```json
{
  "name": "*-stable",
  "push_access_levels": [
    {
      "access_level": 30,
      "access_level_description": "Developers + Masters"
    }
  ],
  "merge_access_levels": [
    {
      "access_level": 30,
      "access_level_description": "Developers + Masters"
    }
  ]
}
```

## Unprotect repository branches

Unprotects the given protected branch or wildcard protected branch.

```
DELETE /projects/:id/protected_branches/:name
```

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch |
