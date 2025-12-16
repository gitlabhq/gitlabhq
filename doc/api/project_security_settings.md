---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project security settings API
description: API endpoints to list and update project security options like secret push protection.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Every API call to project security settings must be [authenticated](rest/authentication.md).

If a project is private, and a user isn't a member of the project to which the security setting
belongs, requests to that project returns a `404 Not Found` status code.

## List project security settings

List all of a project's security settings.

Prerequisites:

- You must have at least the Developer role for the project.

```plaintext
GET /projects/:id/security_settings
```

| Attribute     | Type           | Required | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                                            |

```shell
curl --request GET \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

Example response:

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": true
}
```

## Update the `secret_push_protection_enabled` setting

{{< history >}}

- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185310) from `pre_receive_secret_detection_enabled` in GitLab 17.11.

{{< /history >}}

Updates the `secret_push_protection_enabled` setting for the specified project.

Prerequisites:

- You must have at least the Maintainer role for the project.

```plaintext
PUT /projects/:id/security_settings
```

| Attribute                        | Type              | Required | Description |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a project. |
| `secret_push_protection_enabled` | boolean           | Yes      | Enables secret push protection for the project. |

```shell
curl --request PUT \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/projects/7/security_settings?secret_push_protection_enabled=false"
```

Example response:

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": false
}
```
