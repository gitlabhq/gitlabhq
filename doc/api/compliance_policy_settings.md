---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance and policy settings API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://issue-link) in GitLab 18.2 [with a flag](../administration/feature_flags/_index.md) named `security_policies_csp`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

Use this API to interact with the security policy settings for your GitLab instance.

Prerequisites:

- You must have administrator access to the instance.
- Your instance must have the Ultimate tier to use security policies.

## Get security policy settings

Gets the current security policy settings for this GitLab instance.

```plaintext
GET /admin/security/compliance_policy_settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

Example response:

```json
{
  "csp_namespace_id": 42
}
```

When no CSP namespace is configured:

```json
{
  "csp_namespace_id": null
}
```

## Update security policy settings

Updates the security policy settings for this GitLab instance.

```plaintext
PUT /admin/security/compliance_policy_settings
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `csp_namespace_id` | integer | yes     | ID of the group designated to centrally manage security policies. Must be a top-level group. Set to `null` to clear the setting. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 42}' \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

Example response:

```json
{
  "csp_namespace_id": 42
}
```
