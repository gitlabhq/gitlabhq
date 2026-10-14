---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to retrieve the status and maintenance windows of a GitLab Dedicated instance and update its configuration.
title: Switchboard customer API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Use this API to retrieve the status and maintenance windows of your
[GitLab Dedicated](_index.md) instance, and to update the configuration that you can
edit in the Switchboard console.

The API returns data only for the instance that you have tenant administrator access to.
You do not put the instance in the path. The API gets it from your access.

All endpoints use this base URL:

```plaintext
https://console.gitlab-dedicated.com/api/customer/v1
```

If your Switchboard console has a different URL, use the URL of the console that you sign in to.
The client ID and the endpoint paths are the same for all consoles.

Prerequisites:

- You must have tenant administrator access to your instance in Switchboard.

## Authentication

Each request must have a Switchboard OAuth 2.0 access token in the `Authorization` header.

Switchboard gives tokens through the OAuth 2.0 authorization code flow with
Proof Key for Code Exchange (PKCE). Use the public client `switchboard_customer_api_auth`.
This client has no client secret. Request the `read_write` scope.

An access token expires after 24 hours. The token response also has a refresh token.
Use the refresh token to get a new access token without a sign-in in the browser.

### Get an access token

You can use any OAuth 2.0 client that follows the standard. This example uses
[oauth2c](https://github.com/cloudentity/oauth2c).

To get an access token:

1. Run this command:

   ```shell
   oauth2c https://console.gitlab-dedicated.com \
     --client-id switchboard_customer_api_auth \
     --grant-type authorization_code \
     --response-types code \
     --response-mode query \
     --auth-method none \
     --scopes read_write \
     --pkce \
     --redirect-url http://localhost:3290/callback \
     --authorization-endpoint https://console.gitlab-dedicated.com/oauth/authorize \
     --token-endpoint https://console.gitlab-dedicated.com/oauth/token
   ```

   The command opens a browser.
1. Sign in to Switchboard.
1. Approve the request.

The command gets the callback on `http://localhost:3290/callback` and shows the access token.
Send the token with each request:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/sla_status"
```

### Refresh an access token

To get a new token pair without a sign-in in the browser, send the refresh token to the token endpoint:

```shell
curl --request POST \
  --url "https://console.gitlab-dedicated.com/oauth/token" \
  --data "grant_type=refresh_token" \
  --data "client_id=switchboard_customer_api_auth" \
  --data "refresh_token=<your_refresh_token>"
```

Each refresh returns a new refresh token. Keep the newest refresh token.

You can refresh tokens for a maximum of 30 days after the first sign-in in the browser.
After 30 days, or if Switchboard revokes the token, the token endpoint returns `invalid_grant`.
To continue, get a new access token with a sign-in in the browser.

## Rate limits

Switchboard counts requests for each access token and for each source IP address, in windows of one minute.

| Limit | Requests for each minute |
|-------|--------------------------|
| Each access token | 60 |
| Each source IP address | 120 |
| Token endpoint (`/oauth/token`), each source IP address | 20 |

When a limit applies, the response has these headers for the limit that is nearest to its maximum:

| Header | Description |
|--------|-------------|
| `RateLimit-Limit` | The number of requests that the limit allows in the current window. |
| `RateLimit-Remaining` | The number of requests that the limit still allows in the current window. |
| `RateLimit-Reset` | The Unix time, in seconds, when the current window resets. This value is a time, not a countdown. |

If a response does not have these headers, no limit applied to the request.
Use the values in the headers. Do not use the numbers in the table as fixed values.

When a request is over a limit, the API returns `429 Too Many Requests`.
The `Retry-After` header gives the number of seconds to wait.
A request that you make while you are over a limit also counts against the limit.
If your client continues to send requests, it stays blocked until the window resets.

## Errors

All endpoints can return these status codes:

| Status code | Description |
|-------------|-------------|
| `401 Unauthorized` | The access token is not valid, or the request has no access token. |
| `403 Forbidden` | You do not have the necessary access. |
| `404 Not Found` | The customer API is not available for your instance, or the item does not exist. |
| `422 Unprocessable Entity` | Switchboard did not accept the change. The response body shows the problem. |
| `429 Too Many Requests` | The request is over a rate limit. |

An error response has a `message` attribute. Some errors also have an `errors` attribute with more detail.

## Pagination

List endpoints return one page of items. Use these attributes to select a page:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | The page number. The first page is `1`. |
| `per_page` | integer | No | The number of items on each page. The maximum is `100`. |

The response has an `items` array and a `meta` object:

| Attribute | Type | Description |
|-----------|------|-------------|
| `meta.current_page` | integer | The page number of this response. |
| `meta.total` | integer | The number of items on all pages. |
| `meta.total_pages` | integer | The number of pages. |

## Retrieve instance details

Retrieves details about your instance.

```plaintext
GET /tenant
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `ever_deployed` | boolean | `true` after the first deployment of your instance. The value stays `true` after deprovisioning. |
| `external_url` | string | The URL of your GitLab instance. |
| `gitlab_version` | string | The GitLab version on your instance now. |
| `identifier` | string | The stable identifier of your instance. Use this value when you contact Support about the instance. |
| `name` | string | The display name of your instance. |
| `prerelease_version` | string | The prerelease version on your instance, if your instance runs a prerelease version. Otherwise, `null`. |
| `reference_architecture_label` | string | The size of your instance, for example `Up to 10,000 users (XL)`. |
| `regions` | object | The cloud regions of your instance: `primary`, `backup`, and `sites`. `null` before the cloud account of your instance is configured. |

Example request:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant"
```

Example response:

```json
{
  "identifier": "example1a2b3c",
  "name": "Example Corp",
  "external_url": "https://example.gitlab-dedicated.com",
  "gitlab_version": "19.3.3",
  "prerelease_version": null,
  "reference_architecture_label": "Up to 10,000 users (XL)",
  "ever_deployed": true,
  "regions": {
    "primary": "eu-west-1",
    "backup": "eu-central-1",
    "sites": ["eu-west-1"]
  }
}
```

## Retrieve SLA status

Retrieves the most recent availability status of your instance.
The status shows the same data as the **Health** page in Switchboard.

> [!note]
> The status is not your contractual service level agreement (SLA).
> GitLab calculates the monthly SLA separately, with its own aggregation and exclusions.
> One `down` status does not show a breach of the SLA.
> The API does not return historical data.
> Do not use it as a monitoring or alerting feed.

```plaintext
GET /tenant/sla_status
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `covered_experiences` | array | The status of each covered experience, for example `web`, `git_operations`, `api`, and `package_registry`. Each item has `covered_experience`, `status`, and `data_as_of`. Empty if `data_available` is `false`. |
| `data_as_of` | string | The UTC time of the most recent minute that Switchboard observed. `null` if `data_available` is `false`. |
| `data_available` | boolean | `true` if the response has a status. `false` if the response has a `reason`. |
| `reason` | string | The reason that no status is available. Set only if `data_available` is `false`. |
| `status` | string | The status of your instance in the most recent minute that Switchboard observed. `null` if `data_available` is `false`. |

The `status` attribute has one of these values:

| Value | Description |
|-------|-------------|
| `up` | Your instance has no known problems. |
| `down` | Your instance has a service disruption. |
| `maintenance_window` | Your instance is in scheduled maintenance. |
| `insufficient_traffic` | Your instance has too little traffic to calculate availability. This status is usual when the instance is quiet. It does not show an outage. |

The `reason` attribute has one of these values:

| Value | Description |
|-------|-------------|
| `not_configured` | SLA reporting is not on for your instance. If you expect SLA reporting, contact Support. |
| `no_data` | SLA reporting is on, but Switchboard has no data from the last 6 hours. This value is usual for a new instance or when reporting stops for a short time. |
| `upstream_error` | Switchboard had a temporary error when it got the data. Try again after a short time. |

Example request:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/sla_status"
```

Example response:

```json
{
  "data_available": true,
  "status": "up",
  "data_as_of": "2026-10-08T09:41:00.000Z",
  "reason": null,
  "covered_experiences": [
    { "covered_experience": "web", "status": "up", "data_as_of": "2026-10-08T09:41:00.000Z" },
    { "covered_experience": "git_operations", "status": "up", "data_as_of": "2026-10-08T09:41:00.000Z" }
  ]
}
```

## List all maintenance windows

Lists all planned maintenance windows of your instance.
The list has windows in the future and windows that are complete.

```plaintext
GET /tenant/maintenances
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | The page number. |
| `per_page` | integer | No | The number of items on each page. The maximum is `100`. |
| `scope` | string | No | The windows to return: `all` (default), `upcoming`, or `past`. `upcoming` shows the nearest window first. `all` and `past` show the most recent window first. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and an `items` array. Each item has these attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `approval_status` | string | One of `pending`, `approved`, or `rejected`. |
| `completed_at` | string | The time that the maintenance completed. `null` until the maintenance completes. |
| `emergency` | boolean | `true` for emergency maintenance outside the usual window. |
| `end_at` | string | The scheduled end time of the window. |
| `gitlab_version` | string | The GitLab version that the maintenance deploys. |
| `gitlab_version_pinned` | boolean | `true` if GitLab version upgrades are on hold for your instance. |
| `id` | integer | The ID of the maintenance window. |
| `previous_gitlab_version` | string | The GitLab version before the maintenance. For a window in the future, the version on your instance now. |
| `start_at` | string | The scheduled start time of the window. |
| `started_at` | string | The time that the maintenance started. `null` until the maintenance starts. |
| `status` | string | One of `planned`, `running`, `completed`, `failed`, `interrupted`, or `not_run`. |

If the `scope` value is not known, the API returns `422 Unprocessable Entity`.

Example request:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/maintenances?scope=upcoming"
```

Example response:

```json
{
  "items": [
    {
      "id": 4821,
      "start_at": "2026-10-11T21:00:00.000Z",
      "end_at": "2026-10-12T01:00:00.000Z",
      "started_at": null,
      "completed_at": null,
      "status": "planned",
      "approval_status": "approved",
      "emergency": false,
      "gitlab_version": "19.3.4",
      "previous_gitlab_version": "19.3.3",
      "gitlab_version_pinned": false
    }
  ],
  "meta": { "current_page": 1, "total": 1, "total_pages": 1 }
}
```

## List all configuration changes

Lists all configuration changes of your instance, the most recent change first.
Each change shows what changed, when, and if the change is on your instance.

```plaintext
GET /tenant/config_changes
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | The page number. |
| `per_page` | integer | No | The number of items on each page. The maximum is `100`. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and an `items` array. Each item has these attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `completed_at` | string | The time that the change got to your instance. `null` until then. |
| `config_type` | string | The name of the configuration that changed. |
| `id` | integer | The ID of the change. |
| `requested_at` | string | The time of the change request. |
| `status` | string | One of `pending`, `queued`, `deployed`, or `failed`. |

Example request:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/config_changes?per_page=20"
```

Example response:

```json
{
  "items": [
    {
      "id": 912,
      "config_type": "IP allowlist",
      "status": "deployed",
      "requested_at": "2026-10-06T14:02:11.000Z",
      "completed_at": "2026-10-06T14:20:47.000Z"
    }
  ],
  "meta": { "current_page": 1, "total": 1, "total_pages": 1 }
}
```

## Configuration

These endpoints retrieve and update the settings that you can edit in the Switchboard console.
Each endpoint matches one section of the console.

The `PUT` endpoints replace the full section. Send the full configuration that you want.
Switchboard removes the items that you do not send.
To change one item, get the section, change the item, and send the full section back.
The `PUT` endpoints accept the response of the related `GET` endpoint without changes.
They ignore the attributes that Switchboard sets.

Switchboard records each change in the configuration changes of your instance.
Changes to the contact information are not in this record.

### Retrieve IP allowlist

Retrieves the IP allowlist of your instance.

```plaintext
GET /tenant/ip_allowlist
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `addresses` | array | The allowed addresses. Each item has `address`, `description`, `status`, and `created_at`. |
| `addresses[].address` | string | An IPv4 or IPv6 CIDR block. |
| `addresses[].created_at` | string | The time that you added the address. Switchboard sets this value. |
| `addresses[].description` | string | A description of the address. |
| `addresses[].status` | string | Shows if the address is on your instance. Switchboard sets this value. |
| `enabled` | boolean | `true` if the instance uses the allowlist. `false` if the instance accepts all source addresses. |

### Replace IP allowlist

Replaces the IP allowlist of your instance.

```plaintext
PUT /tenant/ip_allowlist
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `addresses` | array | Yes | The full list of allowed addresses. Each item has `address` (required) and `description`. |
| `enabled` | boolean | Yes | `true` to use the allowlist. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the updated allowlist.

Example request:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"enabled": true, "addresses": [{"address": "203.0.113.0/24", "description": "Office"}]}' \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/ip_allowlist"
```

### Retrieve contact information

Retrieves the operational email addresses that GitLab uses to contact you about your instance.

```plaintext
GET /tenant/contact_information
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `operational_email_addresses` | array of strings | The email addresses for operational notices about your instance. |

### Replace contact information

Replaces the operational email addresses of your instance.

```plaintext
PUT /tenant/contact_information
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `operational_email_addresses` | array of strings | Yes | The full list of email addresses. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the updated contact information.

GitLab sets the internal contacts and the assigned support engineers. You cannot read or change them with this API.

### Retrieve resource access settings

Retrieves the AWS principals that can read the application log bucket of your instance.

```plaintext
GET /tenant/resource_access
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `bucket_read_arns` | array of strings | The AWS principal ARNs that can read your application log bucket. |

### Replace resource access settings

Replaces the AWS principals that can read the application log bucket of your instance.

```plaintext
PUT /tenant/resource_access
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `bucket_read_arns` | array of strings | Yes | The full list of AWS principal ARNs. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the updated settings.

### List all custom certificate authorities

Lists all custom certificate authorities that your instance trusts.

```plaintext
GET /tenant/custom_certificate_authorities
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and an array. Each item has these attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `authority` | string | The issuer. Switchboard gets this value from the certificate. |
| `certificate` | string | The PEM-encoded certificate. |
| `id` | integer | The ID of the certificate authority. |
| `not_after` | string | The end of the validity period of the certificate. |
| `not_before` | string | The start of the validity period of the certificate. |

### Replace custom certificate authorities

Replaces the custom certificate authorities that your instance trusts.

```plaintext
PUT /tenant/custom_certificate_authorities
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `certificates` | array of strings | Yes | The full set of PEM-encoded certificates to trust. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the updated list.

If one certificate is not valid or is expired, Switchboard does not accept the request.
The error shows the index of the certificate.

### List all SAML SSO providers

Lists all SAML single sign-on (SSO) providers of your instance, the oldest first.

```plaintext
GET /tenant/saml_providers
```

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and an array of providers. Each provider has the
[provider attributes](#saml-sso-provider-attributes) and an `id`.

### Retrieve a SAML SSO provider

Retrieves one SAML SSO provider of your instance.

```plaintext
GET /tenant/saml_providers/:id
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | The ID of the provider. |

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the provider.
If the provider does not exist, returns `404 Not Found`.

### Create a SAML SSO provider

Creates a SAML SSO provider on your instance.

```plaintext
POST /tenant/saml_providers
```

Send the [provider attributes](#saml-sso-provider-attributes).

If successful, returns [`201 Created`](../../api/rest/troubleshooting.md#status-codes) and the new provider.

### Replace a SAML SSO provider

Replaces one SAML SSO provider of your instance.

```plaintext
PUT /tenant/saml_providers/:id
```

Send the full provider. If you do not send an optional attribute, Switchboard clears it.
For example, if you do not send `admin_groups`, Switchboard removes the mapping of groups to administrators.

If successful, returns [`200 OK`](../../api/rest/troubleshooting.md#status-codes) and the updated provider.

### Delete a SAML SSO provider

Deletes one SAML SSO provider from your instance.

```plaintext
DELETE /tenant/saml_providers/:id
```

If successful, returns [`204 No Content`](../../api/rest/troubleshooting.md#status-codes).

### SAML SSO provider attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `enabled` | boolean | Yes | `true` to turn on the provider. |
| `idp_cert_fingerprint` | string | Yes | The fingerprint of the identity provider certificate. |
| `idp_sso_target_url` | string | Yes | The SSO URL of the identity provider. |
| `label` | string | Yes | The name on the sign-in button. |
| `name_identifier_format` | string | Yes | The name identifier format. |
| `admin_groups` | array of strings | No | The groups whose members are administrators. |
| `attribute_statements` | object | No | Mappings of SAML attributes to user attributes. |
| `auditor_groups` | array of strings | No | The groups whose members are auditors. |
| `external_groups` | array of strings | No | The groups whose members are external users. |
| `force_authn` | boolean | No | `true` to make the identity provider ask for authentication again. |
| `groups_attribute` | string | No | The SAML attribute that has the groups of the user. |
| `issuer` | string | No | The issuer. |
| `required_groups` | array of strings | No | The groups that a user must be in to sign in. |
| `security` | object | No | SAML security settings. |
| `upstream_two_factor_authn_contexts` | array of strings | No | The authentication contexts that count as two-factor authentication. |

For more information about these settings, see [SAML SSO for GitLab Dedicated](configure_instance/authentication/saml.md).

## Related topics

- [GitLab Dedicated instance details](tenant_overview.md)
- [GitLab Dedicated maintenance operations](maintenance.md)
