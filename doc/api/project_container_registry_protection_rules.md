---
stage: Package
group: Container Registry
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for container registry protection rules in GitLab."
---

# Container registry protection rules API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155798) in GitLab 17.2 [with a flag](../administration/feature_flags.md) named `container_registry_protected_containers`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

This API endpoint manages the protection rules for container registries in a project. This feature is an experiment.

## List container registry protection rules

Gets a list of container registry protection rules from a project.

```plaintext
GET /api/v4/projects/:id/registry/protection/rules
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |

If successful, returns [`200`](rest/index.md#status-codes) and a list of container registry protection rules.

Can return the following status codes:

- `200 OK`: A list of container registry protection rules.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to list container registry protection rules for this project.
- `404 Not Found`: The project was not found.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/rules"
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

## Create a container registry protection rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) in GitLab 17.2.

Create a container registry protection rule for a project.

```plaintext
POST /api/v4/projects/:id/registry/protection/rules
```

Supported attributes:

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_path_pattern`         | string         | Yes      | Container repository path pattern protected by the protection rule. For example `flight/flight-*`. Wildcard character `*` allowed. |
| `minimum_access_level_for_push`   | string         | No       | Minimum GitLab access level to allow to push container images to the container registry. For example `maintainer`, `owner` or `admin`. Must be provided when `minimum_access_level_for_delete` is not set. |
| `minimum_access_level_for_delete` | string         | No       | Minimum GitLab access level to allow to delete container images in the container registry. For example `maintainer`, `owner`, `admin`. Must be provided when  `minimum_access_level_for_push` is not set. |

If successful, returns [`201`](rest/index.md#status-codes) and the created container registry protection rule.

Can return the following status codes:

- `201 Created`: The container registry protection rule was created successfully.
- `400 Bad Request`: The container registry protection rule is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to create a container registry protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The container registry protection rule could not be created, for example, because the `repository_path_pattern` is already taken.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/rules" \
  --data '{
        "repository_path_pattern": "flightjs/flight-needs-to-be-a-unique-path",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

## Update a container registry protection rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) in GitLab 17.2.

Update a container registry protection rule for a project.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/rules/:protection_rule_id
```

Supported attributes:

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `protection_rule_id`              | integer        | Yes      | ID of the protection rule to be updated. |
| `repository_path_pattern`         | string         | No       | Container repository path pattern protected by the protection rule. For example `flight/flight-*`. Wildcard character `*` allowed. |
| `minimum_access_level_for_push`   | string         | No       | Minimum GitLab access level to allow to push container images to the container registry. For example `maintainer`, `owner` or `admin`. Must be provided when `minimum_access_level_for_delete` is not set. To unset the value, use an empty string `""`. |
| `minimum_access_level_for_delete` | string         | No       | Minimum GitLab access level to allow to delete container images in the container registry. For example `maintainer`, `owner`, `admin`. Must be provided when `minimum_access_level_for_push` is not set. To unset the value, use an empty string `""`. |

If successful, returns [`200`](rest/index.md#status-codes) and the updated protection rule.

Can return the following status codes:

- `200 OK`: The protection rule was patched successfully.
- `400 Bad Request`: The patch is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to patch the protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The protection rule could not be patched, for example, because the `repository_path_pattern` is already taken.

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/rules/32" \
  --data '{
       "repository_path_pattern": "flight/flight-*"
    }'
```
