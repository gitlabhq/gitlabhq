---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab as OpenID Connect identity provider **(FREE)**

This document is about using GitLab as an OpenID Connect identity provider
to sign in to other services.

## Introduction to OpenID Connect

[OpenID Connect](https://openid.net/connect/) \(OIDC) is a simple identity layer on top of the
OAuth 2.0 protocol. It allows clients to:

- Verify the identity of the end-user based on the authentication performed by GitLab.
- Obtain basic profile information about the end-user in an interoperable and REST-like manner.

OIDC performs many of the same tasks as OpenID 2.0, but is API-friendly and usable by native and
mobile applications.

On the client side, you can use [OmniAuth::OpenIDConnect](https://github.com/omniauth/omniauth_openid_connect) for Rails
applications, or any of the other available [client implementations](https://openid.net/developers/libraries/#connect).

The GitLab implementation uses the [doorkeeper-openid_connect](https://github.com/doorkeeper-gem/doorkeeper-openid_connect "Doorkeeper::OpenidConnect website") gem, refer
to its README for more details about which parts of the specifications
are supported.

## Enabling OpenID Connect for OAuth applications

Refer to the [OAuth guide](oauth_provider.md) for basic information on how to set up OAuth
applications in GitLab. To enable OIDC for an application, all you have to do
is select the `openid` scope in the application settings.

## Settings discovery

If your client allows importing OIDC settings from a discovery URL, you can use
the following URL to automatically find the correct settings for GitLab.com:

```plaintext
https://gitlab.com/.well-known/openid-configuration
```

Similar URLs can be used for other GitLab instances.

## Shared information

The following user information is shared with clients:

| Claim                | Type      | Description |
|:---------------------|:----------|:------------|
| `sub`                | `string`  | The ID of the user |
| `auth_time`          | `integer` | The timestamp for the user's last authentication |
| `name`               | `string`  | The user's full name |
| `nickname`           | `string`  | The user's GitLab username |
| `preferred_username` | `string`  | The user's GitLab username |
| `email`              | `string`  | The user's email address<br>This is the user's *primary* email address if the application has access to the `email` claim and the user's *public* email address otherwise |
| `email_verified`     | `boolean` | Whether the user's email address was verified |
| `website`            | `string`  | URL for the user's website |
| `profile`            | `string`  | URL for the user's GitLab profile |
| `picture`            | `string`  | URL for the user's GitLab avatar |
| `groups`             | `array`   | Paths for the groups the user is a member of, either directly or through an ancestor group. |
| `groups_direct`      | `array`   | Paths for the groups the user is a direct member of. |
| `https://gitlab.org/claims/groups/owner`      | `array`   | Names of the groups the user is a direct member of with Owner role |
| `https://gitlab.org/claims/groups/maintainer` | `array`   | Names of the groups the user is a direct member of with Maintainer role |
| `https://gitlab.org/claims/groups/developer`  | `array`   | Names of the groups the user is a direct member of with Developer role |

The claims `sub`, `sub_legacy`, `email`, `email_verified` and `groups_direct` are included in the ID token. All other claims are available from the `/oauth/userinfo` endpoint used by OIDC clients.
