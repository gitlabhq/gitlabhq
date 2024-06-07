---
stage: Package
group: Package Registry
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for Package Protection Rules in GitLab."
---

# Package protection rules API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151741) in GitLab 17.1 [with a flag](../administration/feature_flags.md) named `packages_protected_packages`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

This API manages the protection rules for packages. This feature is an experiment.

## List package protection rules

Gets a list of package protection rules from a project.

```plaintext
GET /api/v4/projects/:id/packages/protection/rules
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |

If successful, returns [`200`](rest/index.md#status-codes) and a list of package protection rules.

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
  "push_protected_up_to_access_level": "maintainer"
 },
 {
  "id": 2,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-1",
  "package_type": "npm",
  "push_protected_up_to_access_level": "maintainer"
 }
]
```

## Delete a package protection rule

Deletes a package protection rule from a project.

```plaintext
DELETE /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

Supported attributes:

| Attribute                     | Type            | Required | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | integer/string  | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `package_protection_rule_id`  | integer         | Yes      | ID of the package protection rule to be deleted. |

If successful, returns [`204 No Content`](rest/index.md#status-codes).

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
