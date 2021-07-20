---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project badges API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17082) in GitLab 10.6.

## Placeholder tokens

Badges support placeholders that are replaced in real time in both the link and image URL. The allowed placeholders are:

<!-- vale gitlab.Spelling = NO -->

- **%{project_path}**: Replaced by the project path.
- **%{project_id}**: Replaced by the project ID.
- **%{default_branch}**: Replaced by the project default branch.
- **%{commit_sha}**: Replaced by the last project's commit SHA.

<!-- vale gitlab.Spelling = YES -->
## List all badges of a project

Gets a list of a project's badges and its group badges.

```plaintext
GET /projects/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name`    | string         | no  | Name of the badges to return (case-sensitive). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges"
```

Example response:

```json
[
  {
    "name": "Coverage",
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "project"
  },
  {
    "name": "Pipeline",
    "id": 2,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## Get a badge of a project

Gets a badge of a project.

```plaintext
GET /projects/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

Example response:

```json
{
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "project"
}
```

## Add a badge to a project

Adds a badge to a project.

```plaintext
POST /projects/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `link_url` | string         | yes | URL of the badge link |
| `image_url` | string | yes | URL of the badge image |
| `name` | string | no | Name of the badge |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/master&image_url=https://shields.io/my/badge1&name=mybadge" \
     "https://gitlab.example.com/api/v4/projects/:id/badges"
```

Example response:

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "project"
}
```

## Edit a badge of a project

Updates a badge of a project.

```plaintext
PUT /projects/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |
| `link_url` | string         | no | URL of the badge link |
| `image_url` | string | no | URL of the badge image |
| `name` | string | no | Name of the badge |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

Example response:

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "project"
}
```

## Remove a badge from a project

Removes a badge from a project. Only project badges are removed by using this endpoint.

```plaintext
DELETE /projects/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `badge_id` | integer | yes   | The badge ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

## Preview a badge from a project

Returns how the `link_url` and `image_url` final URLs would be after resolving the placeholder interpolation.

```plaintext
GET /projects/:id/badges/render
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `link_url` | string         | yes | URL of the badge link|
| `image_url` | string | yes | URL of the badge image |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
```

Example response:

```json
{
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=master",
  "rendered_image_url": "https://shields.io/my/badge"
}
```
