---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group badges API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Placeholder tokens

[Badges](../user/project/badges.md) support placeholders that are replaced in real time in both the link and image URL. The allowed placeholders are:

<!-- vale gitlab_base.Spelling = NO -->

- **%{project_path}**: replaced by the project path.
- **%{project_title}**: replaced by the project title.
- **%{project_name}**: replaced by the project name.
- **%{project_id}**: replaced by the project ID.
- **%{project_namespace}**: replaced by the project's namespace full path.
- **%{group_name}**: replaced by the project's top-level group name.
- **%{gitlab_server}**: replaced by the project's server name.
- **%{gitlab_pages_domain}**: replaced by the domain name hosting GitLab Pages.
- **%{default_branch}**: replaced by the project default branch.
- **%{commit_sha}**: replaced by the project's last commit SHA.
- **%{latest_tag}**: replaced by the project's last tag.

<!-- vale gitlab_base.Spelling = YES -->

Because these endpoints aren't inside a project's context, the information used to replace the placeholders comes
from the first group's project by creation date. If the group hasn't got any project the original URL with the placeholders is returned.

## List all badges of a group

Gets a list of a group's badges.

```plaintext
GET /groups/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `name`    | string         | no  | Name of the badges to return (case-sensitive). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/badges?name=Coverage"
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
    "kind": "group"
  }
]
```

## Get a badge of a group

Gets a badge of a group.

```plaintext
GET /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `badge_id` | integer | yes   | The badge ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
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
  "kind": "group"
}
```

## Add a badge to a group

Adds a badge to a group.

```plaintext
POST /groups/:id/badges
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `link_url` | string         | yes | URL of the badge link |
| `image_url` | string | yes | URL of the badge image |
| `name` | string | no | Name of the badge |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/master&image_url=https://shields.io/my/badge1&name=mybadge&position=0" \
     "https://gitlab.example.com/api/v4/groups/:id/badges"
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
  "kind": "group"
}
```

## Edit a badge of a group

Updates a badge of a group.

```plaintext
PUT /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `badge_id` | integer | yes   | The badge ID |
| `link_url` | string         | no | URL of the badge link |
| `image_url` | string | no | URL of the badge image |
| `name` | string | no | Name of the badge |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
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
  "kind": "group"
}
```

## Remove a badge from a group

Removes a badge from a group.

```plaintext
DELETE /groups/:id/badges/:badge_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `badge_id` | integer | yes   | The badge ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

## Preview a badge from a group

Returns how the `link_url` and `image_url` final URLs would be after resolving the placeholder interpolation.

```plaintext
GET /groups/:id/badges/render
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `link_url` | string         | yes | URL of the badge link|
| `image_url` | string | yes | URL of the badge image |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
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
