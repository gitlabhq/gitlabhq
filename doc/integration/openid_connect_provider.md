# GitLab as OpenID Connect identity provider

This document is about using GitLab as an OpenID Connect identity provider
to sign in to other services.

## Introduction to OpenID Connect

[OpenID Connect] \(OIC) is a simple identity layer on top of the
OAuth 2.0 protocol. It allows clients to verify the identity of the end-user
based on the authentication performed by GitLab, as well as to obtain
basic profile information about the end-user in an interoperable and
REST-like manner. OIC performs many of the same tasks as OpenID 2.0,
but does so in a way that is API-friendly, and usable by native and
mobile applications.

On the client side, you can use [omniauth-openid-connect] for Rails
applications, or any of the other available [client implementations].

GitLab's implementation uses the [doorkeeper-openid_connect] gem, refer
to its README for more details about which parts of the specifications
are supported.

## Enabling OpenID Connect for OAuth applications

Refer to the [OAuth guide] for basic information on how to set up OAuth
applications in GitLab. To enable OIC for an application, all you have to do
is select the `openid` scope in the application settings.

Currently the following user information is shared with clients:

| Claim            | Type      | Description |
|:-----------------|:----------|:------------|
| `sub`            | `string`  | An opaque token that uniquely identifies the user
| `auth_time`      | `integer` | The timestamp for the user's last authentication
| `name`           | `string`  | The user's full name
| `nickname`       | `string`  | The user's GitLab username
| `email`          | `string`  | The user's public email address
| `email_verified` | `boolean` | Whether the user's public email address was verified
| `website`        | `string`  | URL for the user's website
| `profile`        | `string`  | URL for the user's GitLab profile
| `picture`        | `string`  | URL for the user's GitLab avatar
| `groups`         | `array`   | Names of the groups the user is a member of

[OpenID Connect]: http://openid.net/connect/ "OpenID Connect website"
[doorkeeper-openid_connect]: https://github.com/doorkeeper-gem/doorkeeper-openid_connect "Doorkeeper::OpenidConnect website"
[OAuth guide]: oauth_provider.md "GitLab as OAuth2 authentication service provider"
[omniauth-openid-connect]: https://github.com/jjbohn/omniauth-openid-connect/ "OmniAuth::OpenIDConnect website"
[client implementations]: http://openid.net/developers/libraries#connect "List of available client implementations"
