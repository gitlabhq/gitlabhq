---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Protected tags API **(FREE)**

> Introduced in GitLab 11.3.

**Valid access levels**

Currently, these levels are recognized:

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
```

## List protected tags

Gets a list of protected tags from a project.
This function takes pagination parameters `page` and `per_page` to restrict the list of protected tags.

```plaintext
GET /projects/:id/protected_tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_tags"
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

```plaintext
GET /projects/:id/protected_tags/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag or wildcard |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
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

```plaintext
POST /projects/:id/protected_tags
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_tags?name=*-stable&create_access_level=30"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag or wildcard |
| `create_access_level` | string | no | Access levels allowed to create (defaults: `40`, Maintainer role) |

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

```plaintext
DELETE /projects/:id/protected_tags/:name
```

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the tag |
