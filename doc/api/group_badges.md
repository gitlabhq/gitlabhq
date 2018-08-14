# Group badges API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17082)
in GitLab 10.6.

## Placeholder tokens

Badges support placeholders that will be replaced in real time in both the link and image URL. The allowed placeholders are:

- **%{project_path}**: will be replaced by the project path.
- **%{project_id}**: will be replaced by the project id.
- **%{default_branch}**: will be replaced by the project default branch.
- **%{commit_sha}**: will be replaced by the last project's commit sha.

Because these endpoints aren't inside a project's context, the information used to replace the placeholders will be
from the first group's project by creation date. If the group hasn't got any project the original URL with the placeholders will be returned.

## List all badges of a group

Gets a list of a group's badges.

```
GET /groups/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/:id/badges
```

Example response:

```json
[
  {
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  },
  {
    "id": 2,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  },
]
```

## Get a badge of a group

Gets a badge of a group.

```
GET /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id
```

Example response:

```json
{
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## Add a badge to a group

Adds a badge to a group.

```
POST /groups/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `link_url` | string         | yes | URL of the badge link |
| `image_url` | string | yes | URL of the badge image |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "link_url=https://gitlab.com/gitlab-org/gitlab-ce/commits/master&image_url=https://shields.io/my/badge1&position=0" https://gitlab.example.com/api/v4/groups/:id/badges
```

Example response:

```json
{
  "id": 1,
  "link_url": "https://gitlab.com/gitlab-org/gitlab-ce/commits/master",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-ce/commits/master",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "group"
}
```

## Edit a badge of a group

Updates a badge of a group.

```
PUT /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |
| `link_url` | string         | no | URL of the badge link |
| `image_url` | string | no | URL of the badge image |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id
```

Example response:

```json
{
  "id": 1,
  "link_url": "https://gitlab.com/gitlab-org/gitlab-ce/commits/master",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-ce/commits/master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## Remove a badge from a group

Removes a badge from a group.

```
DELETE /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id
```

## Preview a badge from a group

Returns how the `link_url` and `image_url` final URLs would be after resolving the placeholder interpolation.

```
GET /groups/:id/badges/render
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `link_url` | string         | yes | URL of the badge link|
| `image_url` | string | yes | URL of the badge image |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge
```

Example response:

```json
{
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
  "rendered_image_url": "https://shields.io/my/badge",
}
```
