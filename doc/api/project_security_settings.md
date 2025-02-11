---
stage: Application Security Testing
group: Secret Detection
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project security settings API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/7/security_settings"
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
    "pre_receive_secret_detection_enabled": true
}
```

## Update `pre_receive_secret_detection_enabled` setting

Update the `pre_receive_secret_detection_enabled` setting for the project to the provided value.

Set to `true` to enable [secret push protection](../user/application_security/secret_detection/secret_push_protection/_index.md) for the project.

Prerequisites:

- You must have at least the Maintainer role for the project.

| Attribute           | Type              | Required   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer or string | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) which the authenticated user is a member of  |
| `pre_receive_secret_detection_enabled`        | boolean | yes        | The value to update `pre_receive_secret_detection_enabled` to  |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/7/security_settings?pre_receive_secret_detection_enabled=false"
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
    "pre_receive_secret_detection_enabled": false
}
```
