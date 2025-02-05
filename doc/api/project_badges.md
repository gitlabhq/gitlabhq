---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project badges API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Placeholder tokens

[Badges](../user/project/badges.md) support placeholders that are replaced in real-time in both the link and image URL. The allowed placeholders are:

<!-- vale gitlab_base.Spelling = NO -->

- **%{project_path}**: Replaced by the project path.
- **%{project_title}**: Replaced by the project title.
- **%{project_name}**: Replaced by the project name.
- **%{project_id}**: Replaced by the project ID.
- **%{project_namespace}**: Replaced by the project's namespace full path.
- **%{group_name}**: Replaced by the project's top-level group name.
- **%{gitlab_server}**: Replaced by the project's server name.
- **%{gitlab_pages_domain}**: Replaced by the domain name hosting GitLab Pages.
- **%{default_branch}**: Replaced by the project default branch.
- **%{commit_sha}**: Replaced by the project's last commit SHA.
- **%{latest_tag}**: Replaced by the project's last tag.

<!-- vale gitlab_base.Spelling = YES -->

## List all badges of a project

Gets a list of a project's badges and its group badges.

```plaintext
GET /projects/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`    | string         | no  | Name of the badges to return (case-sensitive). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges?name=Coverage"
```

Example response:

```json
[
  {
    "name": "Coverage",
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "project"
  },
  {
    "name": "Pipeline",
    "id": 2,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `badge_id` | integer | yes   | The badge ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

Example response:

```json
{
  "name": "Coverage",
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `link_url` | string         | yes | URL of the badge link |
| `image_url` | string | yes | URL of the badge image |
| `name` | string | no | Name of the badge |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/main&image_url=https://shields.io/my/badge1&name=mybadge" \
     "https://gitlab.example.com/api/v4/projects/:id/badges"
```

Example response:

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge"
}
```
