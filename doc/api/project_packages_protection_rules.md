---
stage: Package
group: Package Registry
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for Package Protection Rules in GitLab."
title: Protected packages API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151741) in GitLab 17.1 [with a flag](../administration/feature_flags.md) named `packages_protected_packages`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) in GitLab 17.5.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) in GitLab 17.6. Feature flag `packages_protected_packages` removed.

This API manages the protection rules for packages.

## List package protection rules

Gets a list of package protection rules from a project.

```plaintext
GET /api/v4/projects/:id/packages/protection/rules
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and a list of package protection rules.

Can return the following status codes:

- `200 OK`: A list of package protection rules.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to list package protection rules for this project.
- `404 Not Found`: The project was not found.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules"
```

Example response:

```json
[
 {
  "id": 1,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-0",
  "package_type": "npm",
  "minimum_access_level_for_push": "maintainer"
 },
 {
  "id": 2,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-1",
  "package_type": "npm",
  "minimum_access_level_for_push": "maintainer"
 }
]
```

## Create a package protection rule

Create a package protection rule for a project.

```plaintext
POST /api/v4/projects/:id/packages/protection/rules
```

Supported attributes:

| Attribute                             | Type            | Required | Description                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `package_name_pattern`                | string          | Yes      | Package name protected by the protection rule. For example `@my-scope/my-package-*`. Wildcard character `*` allowed. |
| `package_type`                        | string          | Yes      | Package type protected by the protection rule. For example `npm`. |
| `minimum_access_level_for_push`       | string          | Yes      | Minimum GitLab access level able to push a package. Must be at least `maintainer`. For example `maintainer`, `owner` or `admin`. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the created package protection rule.

Can return the following status codes:

- `201 Created`: The package protection rule was created successfully.
- `400 Bad Request`: The package protection rule is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to create a package protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The package protection rule could not be created, for example, because the `package_name_pattern` is already taken.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules" \
  --data '{
       "package_name_pattern": "package-name-pattern-*",
       "package_type": "npm",
       "minimum_access_level_for_push": "maintainer"
    }'
```

## Update a package protection rule

Update a package protection rule for a project.

```plaintext
PATCH /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

Supported attributes:

| Attribute                             | Type            | Required | Description                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `package_protection_rule_id`          | integer         | Yes      | ID of the package protection rule to be updated. |
| `package_name_pattern`                | string          | No       | Package name protected by the protection rule. For example `@my-scope/my-package-*`. Wildcard character `*` allowed. |
| `package_type`                        | string          | No       | Package type protected by the protection rule. For example `npm`. |
| `minimum_access_level_for_push`       | string          | No       | Minimum GitLab access level able to push a package. Must be at least `maintainer`. For example `maintainer`, `owner` or `admin`. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the updated package protection rule.

Can return the following status codes:

- `200 OK`: The package protection rule was patched successfully.
- `400 Bad Request`: The patch is invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to patch a package protection rule.
- `404 Not Found`: The project was not found.
- `422 Unprocessable Entity`: The package protection rule could not be patched, for example, because the `package_name_pattern` is already taken.

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32" \
  --data '{
       "package_name_pattern": "new-package-name-pattern-*"
    }'
```

## Delete a package protection rule

Deletes a package protection rule from a project.

```plaintext
DELETE /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `package_protection_rule_id`  | integer         | Yes      | ID of the package protection rule to be deleted. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Can return the following status codes:

- `204 No Content`: The package protection rule was deleted successfully.
- `400 Bad Request`: The `id` or the `package_protection_rule_id` are missing or are invalid.
- `401 Unauthorized`: The access token is invalid.
- `403 Forbidden`: The user does not have permission to delete the package protection rule.
- `404 Not Found`: The project or the package protection rule was not found.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32"
```
