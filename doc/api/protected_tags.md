# Protected tags API

>**Note:** This feature was introduced in GitLab 11.3

**Valid access levels**

Currently, these levels are recognized:
```
0  => No access
30 => Developer access
40 => Maintainer access
```

## List protected tags

Gets a list of protected tags from a project.
This function takes pagination parameters `page` and `per_page` to restrict the list of protected tags.

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
        "access_level_description": "Maintainers"
      }
    ]
  },
  ...
]
```

## Get a single protected tag or wildcard protected tag

Gets a single protected tag or wildcard protected tag.
The pagination parameters `page` and `per_page` can be used to restrict the list of protected tags.

```
GET /projects/:id/protected_tags/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag or wildcard |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0'
```

Example response:

```json
{
  "name": "release-1-0",
  "create_access_levels": [
    {
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ]
}
```

## Protect repository tags

Protects a single repository tag or several project repository
tags using a wildcard protected tag.

```
POST /projects/:id/protected_tags
```

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags?name=*-stable&create_access_level=30'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag or wildcard |
| `create_access_level` | string | no | Access levels allowed to create (defaults: `40`, maintainer access level) |

Example response:

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
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
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable'
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag |
