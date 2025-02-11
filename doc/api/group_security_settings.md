---
stage: Security Risk Management
group: Security Platform Management
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Group security settings API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502827) in GitLab 17.7.

Every API call to group security settings must be [authenticated](rest/authentication.md).

If a user isn't a member of a private group, requests to the private group return a `404 Not Found` status code.

## Update `secret_push_protection_enabled` setting

Update the `secret_push_protection_enabled` setting for the all projects in a group to the provided value.

Set to `true` to enable [secret push protection](../user/application_security/secret_detection/secret_push_protection/_index.md) for the all projects in the group.

Prerequisites:

- You must have at least the Maintainer role for the group.

| Attribute           | Type              | Required   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer or string | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) which the authenticated user is a member of  |
| `secret_push_protection_enabled`        | boolean | yes        | Whether secret push protection is enabled for the group. |
| `projects_to_exclude`        | array of integers | no        | The IDs of projects to exclude from the feature.  |

```shell
curl --header PUT "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/7/security_settings?secret_push_protection_enabled=true&projects_to_exclude=1,2,3"
```

Example response:

```json
{
  "secret_push_protection_enabled": true,
  "errors": []
}
```
