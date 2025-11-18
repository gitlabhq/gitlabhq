---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab as OpenID Connect identity provider
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can use GitLab as an [OpenID Connect](https://openid.net/developers/how-connect-works/) (OIDC)
identity provider to access other services.
OIDC is an identity layer that performs many of the same tasks as OpenID 2.0, but is API-friendly
and usable by native and mobile applications.

Clients can use OIDC to:

- Verify the identity of an end-user based on the authentication performed by GitLab.
- Obtain basic profile information about the end-user in an interoperable and REST-like manner.

You can use [OmniAuth::OpenIDConnect](https://github.com/omniauth/omniauth_openid_connect) for Rails
applications and there are many other available [client implementations](https://openid.net/developers/certified-openid-connect-implementations/).

GitLab uses the `doorkeeper-openid_connect` gem to provide OIDC service. For more information, see
the [doorkeeper-openid_connect repository](https://github.com/doorkeeper-gem/doorkeeper-openid_connect "Doorkeeper::OpenidConnect repository").

## Enable OIDC for OAuth applications

To enable OIDC for an OAuth application, you need to select the `openid` scope in the application
settings. For more information, see [Configure GitLab as an OAuth 2.0 authentication identity provider](oauth_provider.md).

## Settings discovery

If your client can import OIDC settings from a discovery URL, GitLab provides endpoints to access
this information:

- For GitLab.com, use `https://gitlab.com/.well-known/openid-configuration`.
- For GitLab Self-Managed, use `https://<your-gitlab-instance>/.well-known/openid-configuration`

## Shared information

The following user information is shared with clients:

| Claim                | Type      | Description | Included in ID Token | Included in `userinfo` endpoint |
|:---------------------|:----------|:------------|:---------------------|:------------------------------|
| `sub`                | `string`  | The ID of the user | {{< yes >}} | {{< yes >}} |
| `auth_time`          | `integer` | The timestamp for the user's last authentication | {{< yes >}} | {{< no >}} |
| `name`               | `string`  | The user's full name | {{< yes >}} | {{< yes >}} |
| `nickname`           | `string`  | The user's GitLab username | {{< yes >}}| {{< yes >}} |
| `preferred_username` | `string`  | The user's GitLab username | {{< yes >}} | {{< yes >}} |
| `email`              | `string`  | The user's primary email address | {{< yes >}} | {{< yes >}} |
| `email_verified`     | `boolean` | Whether the user's email address is verified | {{< yes >}} | {{< yes >}} |
| `website`            | `string`  | URL for the user's website | {{< yes >}} | {{< yes >}} |
| `profile`            | `string`  | URL for the user's GitLab profile | {{< yes >}} | {{< yes >}}|
| `picture`            | `string`  | URL for the user's GitLab avatar | {{< yes >}}| {{< yes >}} |
| `groups`             | `array`   | Paths for the groups the user is a member of, either directly or through an ancestor group. | {{< no >}} | {{< yes >}} |
| `groups_direct`      | `array`   | Paths for the groups the user is a direct member of. | {{< yes >}} | {{< no >}} |
| `https://gitlab.org/claims/groups/owner`      | `array`   | Names of the groups the user is a direct member of with the Owner role | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/maintainer` | `array`   | Names of the groups the user is a direct member of with the Maintainer role | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/developer`  | `array`   | Names of the groups the user is a direct member of with the Developer role | {{< no >}} | {{< yes >}} |

The claims `email` and `email_verified` are included only if the application has access to the
`email` scope and the user's public email address. All other claims are available from the
`/oauth/userinfo` endpoint used by OIDC clients.
