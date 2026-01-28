---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for container registry protection tag rules in GitLab.
title: Container registry protection tag rules API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) in GitLab 18.7.

{{< /history >}}

Use this API to manage [protected container tags](../user/packages/container_registry/protected_container_tags.md).

## List container registry protection tag rules

Gets a list of container registry protection tag rules for a project.

```plaintext
GET /api/v4/projects/:id/registry/protection/tag/rules
```

Supported attributes:

| Attribute | Type              | Required | Description                                                                     |
|-----------|-------------------|----------|---------------------------------------------------------------------------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project.      |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | integer | The ID of the protected container tag rule. |
| `minimum_access_level_for_delete` | string | The minimum access level required to delete the tag (for example, `maintainer` or `owner`). |
| `minimum_access_level_for_push` | string | The minimum access level required to push to the tag (for example, `maintainer` or `owner`). |
| `project_id` | integer | The ID of the project. |
| `tag_name_pattern` | string | The tag name pattern (for example, `v*-release` or `latest`). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules"
```

Example response:

```json
[
  {
    "id": 1,
    "project_id": 7,
    "tag_name_pattern": "v*-release",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "tag_name_pattern": "latest",
    "minimum_access_level_for_push": "owner",
    "minimum_access_level_for_delete": "owner"
  }
]
```

## Update a container registry protection tag rule

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) in GitLab 18.9.

{{< /history >}}

Updates a container registry protection tag rule for a project.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer or string | Yes | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `protection_rule_id` | integer | Yes | ID of the protection tag rule to be updated. |
| `minimum_access_level_for_delete` | string | No | Minimum access level required to delete container tags. For example, `maintainer`, `owner`, or `admin`. To unset the value, use an empty string (`""`). |
| `minimum_access_level_for_push` | string | No | Minimum access level required to push container tags. For example `maintainer`, `owner`, or `admin`. To unset the value, use an empty string (`""`). |
| `tag_name_pattern` | string | No | Container tag name pattern protected by the protection rule. For example, `v*-release`. Wildcard character `*` allowed. |

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code. Returns `422 Unprocessable Entity` if a protection tag rule could not be updated. For example, because the `tag_name_pattern` is already taken.

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1" \
  --data '{
       "tag_name_pattern": "v*-stable"
    }'
```
