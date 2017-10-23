# Protected tags API

>**Note:** This feature was introduced in GitLab 11.2

**Valid access levels**

The access levels are defined in the `ProtectedTagAccess::ALLOWED_ACCESS_LEVELS` constant. Currently, these levels are recognized:
```
0  => No access
30 => Developer access
40 => Master access
```

## List protected tags

Gets a list of protected tags from a project.

```
GET /projects/:id/protected_tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags'
```

Example response:

```json
[
  {
    "name": "release-1-0",
    "create_access_levels": [
      {
        "access_level": 40,
        "access_level_description": "Masters"
      }
    ]
  },
  ...
]
```

## Get a single protected tag or wildcard protected tag

Gets a single protected tag or wildcard protected tag.

```
GET /projects/:id/protected_tags/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch or wildcard |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0'
```

Example response:

```json
{
  "name": "master",
  "create_access_levels": [
    {
      "access_level": 40,
      "access_level_description": "Masters"
    }
  ]
}
```

## Protect repository tags

Protects a single repository tag or several project repository
tags using a wildcard protected branch.

```
POST /projects/:id/protected_tags
```

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags?name=*-stable&create_access_level=30'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch or wildcard |
| `create_access_level` | string | no | Access levels allowed to create (defaults: `40`, master access level) |

Example response:

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "access_level": 30,
      "access_level_description": "Developers + Masters"
    }
  ]
}
```

## Unprotect repository tags

Unprotects the given protected tag or wildcard protected tag.

```
DELETE /projects/:id/protected_tags/:name
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the branch |
