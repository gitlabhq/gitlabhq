---
stage: Package
group: Container Registry
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for container repository protection rules in GitLab."
title: Container repository protection rules API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155798) in GitLab 17.2 [with a flag](../administration/feature_flags.md) named `container_registry_protected_containers`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/429074) in GitLab 17.8.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/480385) in GitLab 17.8. Feature flag `container_registry_protected_containers` removed.

## List container repository protection rules

Gets a list of container repository protection rules from a project's container registry.

```plaintext
GET /api/v4/projects/:id/registry/protection/repository/rules
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and a list of container repository protection rules.

Can return the following status codes:

- `200 OK`: A list of protection rules.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to list protection rules for this project.
- `404 Not Found`: The project was not found.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules"
```

Example response:

```json
[
  {
    "id": 1,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight0",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight1",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
]
```

## Create a container repository protection rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) in GitLab 17.2.

Create a container repository protection rule for a project's container registry.

```plaintext
POST /api/v4/projects/:id/registry/protection/repository/rules
```

Supported attributes:

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `repository_path_pattern`         | string         | Yes      | Container repository path pattern protected by the protection rule. For example `flight/flight-*`. Wildcard character `*` allowed. |
| `minimum_access_level_for_push`   | string         | No       | Minimum GitLab access level required to push container images to the container registry. For example `maintainer`, `owner` or `admin`. Must be provided when `minimum_access_level_for_delete` is not set. |
| `minimum_access_level_for_delete` | string         | No       | Minimum GitLab access level required to delete container images in the container registry. For example `maintainer`, `owner`, `admin`. Must be provided when `minimum_access_level_for_push` is not set. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the created container repository protection rule.

Can return the following status codes:

- `201 Created`: The protection rule was created successfully.
- `400 Bad Request`: The protection rule is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to create a protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The protection rule could not be created. For example, because the `repository_path_pattern` is already taken.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules" \
  --data '{
        "repository_path_pattern": "flightjs/flight-needs-to-be-a-unique-path",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

## Update a container repository protection rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) in GitLab 17.2.

Update a container repository protection rule for a project's container registry.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

Supported attributes:

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `protection_rule_id`              | integer        | Yes      | ID of the protection rule to be updated. |
| `repository_path_pattern`         | string         | No       | Container repository path pattern protected by the protection rule. For example `flight/flight-*`. Wildcard character `*` allowed. |
| `minimum_access_level_for_push`   | string         | No       | Minimum GitLab access level required to push container images to the container registry. For example `maintainer`, `owner` or `admin`. Must be provided when `minimum_access_level_for_delete` is not set. To unset the value, use an empty string `""`. |
| `minimum_access_level_for_delete` | string         | No       | Minimum GitLab access level required to delete container images in the container registry. For example `maintainer`, `owner`, `admin`. Must be provided when `minimum_access_level_for_push` is not set. To unset the value, use an empty string `""`. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the updated protection rule.

Can return the following status codes:

- `200 OK`: The protection rule was updated successfully.
- `400 Bad Request`: The protection rule is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to update the protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The protection rule could not be updated. For example, because the `repository_path_pattern` is already taken.

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/32" \
  --data '{
       "repository_path_pattern": "flight/flight-*"
    }'
```

## Delete a container repository protection rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) in GitLab 17.4.

Deletes a container repository protection rule from a project's container registry.

```plaintext
DELETE /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

Supported attributes:

| Attribute            | Type           | Required | Description |
|----------------------|----------------|----------|-------------|
| `id`                 | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `protection_rule_id` | integer        | Yes      | ID of the container repository protection rule to be deleted. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Can return the following status codes:

- `204 No Content`: The protection rule was deleted successfully.
- `400 Bad Request`: The `id` or the `protection_rule_id` are missing or are invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to delete the protection rule.
- `404 Not Found`: The project or the protection rule was not found.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/1"
```
