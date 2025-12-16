---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group security settings API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502827) in GitLab 17.7.

{{< /history >}}

Every API call to group security settings must be [authenticated](rest/authentication.md).

If a user isn't a member of a private group, requests to the private group return a `404 Not Found` status code.

## Update the `secret_push_protection_enabled` setting

Updates the `secret_push_protection_enabled` setting for all projects in a specified group.

Prerequisites:

- You must have at least the Maintainer role for the group.

```plaintext
PUT /groups/:id/security_settings
```

| Attribute                        | Type              | Required | Description |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `secret_push_protection_enabled` | boolean           | Yes      | Enables secret push protection for projects in the group. |
| `projects_to_exclude`            | array of integers | No       | IDs of projects to exclude from secret push protection. |

```shell
curl --request PUT \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/groups/7/security_settings?secret_push_protection_enabled=true&projects_to_exclude[]=1&projects_to_exclude[]=2"
```

Example response:

```json
{
  "secret_push_protection_enabled": true,
  "errors": []
}
```
