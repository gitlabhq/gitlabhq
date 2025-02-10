---
stage: Software Supply Chain Security
group: Authentication
description: Third-party authorization to GitLab.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OAuth 2.0 identity provider API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to allow third-party services to access GitLab resources for a user
with the [OAuth 2.0](https://oauth.net/2/) protocol.
For more information, see [Configure GitLab as an OAuth 2.0 authentication identity provider](../integration/oauth_provider.md).

This functionality is based on the [doorkeeper Ruby gem](https://github.com/doorkeeper-gem/doorkeeper).

## Cross-origin resource sharing

> - CORS preflight request support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364680) in GitLab 15.1.

Many `/oauth` endpoints support cross-origin resource sharing (CORS). From GitLab 15.1, the following endpoints also
support [CORS preflight requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS):

- `/oauth/revoke`
- `/oauth/token`
- `/oauth/userinfo`

Only certain headers can be used for preflight requests:

- The headers listed for [simple requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests).
- The `Authorization` header.

For example, the `X-Requested-With` header can't be used for preflight requests.

## Supported OAuth 2.0 flows

GitLab supports the following authorization flows:

- **Authorization code with [Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636):**
  Most secure. Without PKCE, you'd have to include client secrets on mobile clients,
  and is recommended for both client and server apps.
- **Authorization code:** Secure and common flow. Recommended option for secure
  server-side apps.
- **Resource owner password credentials:** To be used **only** for securely
  hosted, first-party services. GitLab recommends against use of this flow.
- **Device Authorization Grant** (GitLab 17.1 and later) Secure flow oriented toward devices without browser access. Requires a secondary device to complete the authorization flow.

The draft specification for [OAuth 2.1](https://oauth.net/2.1/) specifically omits both the
Implicit grant and Resource Owner Password Credentials flows.

Refer to the [OAuth RFC](https://www.rfc-editor.org/rfc/rfc6749) to find out
how all those flows work and pick the right one for your use case.

Authorization code (with or without PKCE) flow requires `application` to be
registered first via the `/user_settings/applications` page in your user's account.
During registration, by enabling proper scopes, you can limit the range of
resources which the `application` can access. Upon creation, you obtain the
`application` credentials: _Application ID_ and _Client Secret_. The _Client Secret_
**must be kept secure**. It is also advantageous to keep the _Application ID_
secret when your application architecture allows.

For a list of scopes in GitLab, see [the provider documentation](../integration/oauth_provider.md#view-all-authorized-applications).

### Prevent CSRF attacks

To [protect redirect-based flows](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.1),
the OAuth specification recommends the use of "One-time use CSRF tokens carried in the state
parameter, which are securely bound to the user agent", with each request to the
`/oauth/authorize` endpoint. This can prevent
[CSRF attacks](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)).

### Use HTTPS in production

For production, use HTTPS for your `redirect_uri`.
For development, GitLab allows insecure HTTP redirect URIs.

As OAuth 2.0 bases its security entirely on the transport layer, you should not use unprotected
URIs. For more information, see the [OAuth 2.0 RFC](https://www.rfc-editor.org/rfc/rfc6749#section-3.1.2.1)
and the [OAuth 2.0 Threat Model RFC](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.2.1).

In the following sections you can find detailed instructions on how to obtain
authorization with each flow.

### Authorization code with Proof Key for Code Exchange (PKCE)

The [PKCE RFC](https://www.rfc-editor.org/rfc/rfc7636#section-1.1) includes a
detailed flow description, from authorization request through access token.
The following steps describe our implementation of the flow.

The Authorization code with PKCE flow, PKCE for short, makes it possible to securely perform
the OAuth exchange of client credentials for access tokens on public clients without
requiring access to the _Client Secret_ at all. This makes the PKCE flow advantageous
for single page JavaScript applications or other client side apps where keeping secrets
from the user is a technical impossibility.

Before starting the flow, generate the `STATE`, the `CODE_VERIFIER` and the `CODE_CHALLENGE`.

- The `STATE` a value that can't be predicted used by the client to maintain
  state between the request and callback. It should also be used as a CSRF token.
- The `CODE_VERIFIER` is a random string, between 43 and 128 characters in length,
  which use the characters `A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, and `~`.
- The `CODE_CHALLENGE` is an URL-safe base64-encoded string of the SHA256 hash of the
  `CODE_VERIFIER`:
  - The SHA256 hash must be in binary format before encoding.
  - In Ruby, you can set that up with `Base64.urlsafe_encode64(Digest::SHA256.digest(CODE_VERIFIER), padding: false)`.
  - For reference, a `CODE_VERIFIER` string of `ks02i3jdikdo2k0dkfodf3m39rjfjsdk0wk349rj3jrhf` when hashed
    and encoded using the Ruby snippet above produces a `CODE_CHALLENGE` string
    of `2i0WFA-0AerkjQm4X4oDEhqA17QIAKNjXpagHBXmO_U`.

1. Request authorization code. To do that, you should redirect the user to the
   `/oauth/authorize` page with the following query parameters:

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&code_challenge=CODE_CHALLENGE&code_challenge_method=S256
   ```

   This page asks the user to approve the request from the app to access their
   account based on the scopes specified in `REQUESTED_SCOPES`. The user is then
   redirected back to the specified `REDIRECT_URI`. The [scope parameter](../integration/oauth_provider.md#view-all-authorized-applications)
   is a space-separated list of scopes associated with the user.
   For example,`scope=read_user+profile` requests the `read_user` and `profile` scopes.
   The redirect includes the authorization `code`, for example:

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. With the authorization `code` returned from the previous request (denoted as
   `RETURNED_CODE` in the following example), you can request an `access_token`, with
   any HTTP client. The following example uses Ruby's `rest-client`:

   ```ruby
   parameters = 'client_id=APP_ID&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Example response:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. To retrieve a new `access_token`, use the `refresh_token` parameter. Refresh tokens may
   be used even after the `access_token` itself expires. This request:
   - Invalidates the existing `access_token` and `refresh_token`.
   - Sends new tokens in the response.

   ```ruby
     parameters = 'client_id=APP_ID&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Example response:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

NOTE:
The `redirect_uri` must match the `redirect_uri` used in the original
authorization request.

You can now make requests to the API with the access token.

### Authorization code flow

NOTE:
Check the [RFC spec](https://www.rfc-editor.org/rfc/rfc6749#section-4.1) for a
detailed flow description.

The authorization code flow is essentially the same as
[authorization code flow with PKCE](#authorization-code-with-proof-key-for-code-exchange-pkce),

Before starting the flow, generate the `STATE`. It is a value that can't be predicted
used by the client to maintain state between the request and callback. It should also
be used as a CSRF token.

1. Request authorization code. To do that, you should redirect the user to the
   `/oauth/authorize` page with the following query parameters:

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES
   ```

   This page asks the user to approve the request from the app to access their
   account based on the scopes specified in `REQUESTED_SCOPES`. The user is then
   redirected back to the specified `REDIRECT_URI`. The [scope parameter](../integration/oauth_provider.md#view-all-authorized-applications)
   is a space-separated list of scopes associated with the user.
   For example,`scope=read_user+profile` requests the `read_user` and `profile` scopes.
   The redirect includes the authorization `code`, for example:

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. With the authorization `code` returned from the previous request (shown as
   `RETURNED_CODE` in the following example), you can request an `access_token`, with
   any HTTP client. The following example uses Ruby's `rest-client`:

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Example response:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. To retrieve a new `access_token`, use the `refresh_token` parameter. Refresh tokens may
   be used even after the `access_token` itself expires. This request:
   - Invalidates the existing `access_token` and `refresh_token`.
   - Sends new tokens in the response.

   ```ruby
     parameters = 'client_id=APP_ID&client_secret=APP_SECRET&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Example response:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

NOTE:
The `redirect_uri` must match the `redirect_uri` used in the original
authorization request.

You can now make requests to the API with the access token returned.

### Device authorization grant flow

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332682) in GitLab 17.2 [with a flag](../administration/feature_flags.md) named `oauth2_device_grant_flow`.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/468479) by default in 17.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/505557) in GitLab 17.9. Feature flag `oauth2_device_grant_flow` removed.

NOTE:
Check the [RFC spec](https://datatracker.ietf.org/doc/html/rfc8628#section-3.1) for a detailed
description of the device authorization grant flow, from device authorization request to token response from the browser login.

The device authorization grant flow makes it possible to securely authenticate your GitLab identity from input constrained devices where browser interactions are not an option.

This makes the device authorization grant flow ideal for users attempting to use GitLab services from headless servers or other devices with no, or limited, UI.

1. To request device authorization, a request is sent from the input-limited
   device client to `https://gitlab.example.com/oauth/authorize_device`. For example:

   ```ruby
     parameters = 'client_id=UID&scope=read'
     RestClient.post 'https://gitlab.example.com/oauth/authorize_device', parameters
   ```

   After a successful request, a response containing a `verification_uri` is returned to the user. For example:

   ```json
   {
       "device_code": "GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS",
       "user_code": "0A44L90H",
       "verification_uri": "https://gitlab.example.com/oauth/device",
       "verification_uri_complete": "https://gitlab.example.com/oauth/device?user_code=0A44L90H",
       "expires_in": 300,
       "interval": 5
   }
   ```

1. The device client displays the `user_code` and `verification_uri` from the response to the
   requesting user. That user then, on a secondary device with browser access:
   1. Goes to the provided URI.
   1. Enters the user code.
   1. Completes an authentication as prompted.

1. Immediately after displaying the `verification_uri` and `user_code`, the device client
   begins polling the token endpoint with the associated `device_code` returned in the initial response:

   ```ruby
   parameters = 'grant_type=urn:ietf:params:oauth:grant-type:device_code
   &device_code=GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS
   &client_id=1406020730'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

1. The device client receives a response from the token endpoint. If the authorization was successful,
   a success response is returned, otherwise, an error response is returned.
   Potential error responses are categorized by either of the following:
   - Those defined by the OAuth Authorization Framework access token error responses.
   - Those specific to the device authorization grant flow described here.
   Those error responses specific to the device flow are described in the following content.
   For more information on each potential response, see the relevant [RFC spec for device authorization grant](https://datatracker.ietf.org/doc/html/rfc8628#section-3.5) and the
   [RFC spec for authorization tokens](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).

   Example response:

   ```json
   {
     "error": "authorization_pending",
     "error_description": "..."
   }
   ```

   On receipt of this response, the device client continues polling.

   If the polling interval is too short, a slow down error response is returned. For example:

    ```json
    {
      "error": "slow_down",
      "error_description": "..."
    }
    ```

   On receipt of this response, the device client reduces its polling rate and continues polling at the new rate.

   If the device code expires before authentication is complete, an expired token error
   response is returned. For example:

   ```json
   {
     "error": "expired_token",
     "error_description": "..."
   }
   ```

   At that point, the device-client should stop and initiate a new device authorization request.

   If the authorization request was denied, an access denied error response is returned. For example:

   ```json
   {
     "error": "access_denied",
     "error_description": "..."
   }
   ```

   The authentication request has been rejected. The user should verify their credentials or contact their system administrator

1. After the user successfully authenticates, a success response is returned:

   ```json
   {
       "access_token": "TOKEN",
       "token_type": "Bearer",
       "expires_in": 7200,
       "scope": "read",
       "created_at": 1593096829
   }
   ```

At this point, the device authentication flow is complete. The returned `access_token` can be provided to GitLab to authenticate the user identity when accessing GitLab resources, such as when cloning over HTTPS or accessing the API.

A sample application that implements the client side device flow can be found at: <https://gitlab.com/johnwparent/git-auth-over-https>.

### Resource owner password credentials flow

NOTE:
Check the [RFC spec](https://www.rfc-editor.org/rfc/rfc6749#section-4.3) for a
detailed flow description.

NOTE:
The Resource Owner Password Credentials is disabled for users with
[two-factor authentication](../user/profile/account/two_factor_authentication.md) turned on.
These users can access the API using [personal access tokens](../user/profile/personal_access_tokens.md)
instead.

NOTE:
Ensure the [**Allow password authentication for Git over HTTP(S)**](../administration/settings/sign_in_restrictions.md#password-authentication-enabled)
checkbox is selected for the GitLab instance to support the password credentials flow.

In this flow, a token is requested in exchange for the resource owner credentials
(username and password).

The credentials should only be used when:

- There is a high degree of trust between the resource owner and the client. For
  example, the client is part of the device operating system or a highly
  privileged application.
- Other authorization grant types are not available (such as an authorization code).

WARNING:
Never store the user's credentials and only use this grant type when your client
is deployed to a trusted environment, in 99% of cases
[personal access tokens](../user/profile/personal_access_tokens.md) are a better
choice.

Even though this grant type requires direct client access to the resource owner
credentials, the resource owner credentials are used for a single request and
are exchanged for an access token. This grant type can eliminate the need for
the client to store the resource owner credentials for future use, by exchanging
the credentials with a long-lived access token or refresh token.

To request an access token, you must make a POST request to `/oauth/token` with
the following parameters:

```json
{
  "grant_type"    : "password",
  "username"      : "user@example.com",
  "password"      : "secret"
}
```

Example cURL request:

```shell
echo 'grant_type=password&username=<your_username>&password=<your_password>' > auth.txt
curl --data "@auth.txt" --request POST "https://gitlab.example.com/oauth/token"
```

You can also use this grant flow with registered OAuth applications, by using
HTTP Basic Authentication with the application's `client_id` and `client_secret`:

```shell
echo 'grant_type=password&username=<your_username>&password=<your_password>' > auth.txt
curl --data "@auth.txt" --user client_id:client_secret \
     --request POST "https://gitlab.example.com/oauth/token"
```

Then, you receive a response containing the access token:

```json
{
  "access_token": "1f0af717251950dbd4d73154fdf0a474a5c5119adad999683f5b450c460726aa",
  "token_type": "bearer",
  "expires_in": 7200
}
```

By default, the scope of the access token is `api`, which provides complete read/write access.

For testing, you can use the `oauth2` Ruby gem:

```ruby
client = OAuth2::Client.new('the_client_id', 'the_client_secret', :site => "https://example.com")
access_token = client.password.get_token('user@example.com', 'secret')
puts access_token.token
```

## Access GitLab API with `access token`

The `access token` allows you to make requests to the API on behalf of a user.
You can pass the token either as GET parameter:

```plaintext
GET https://gitlab.example.com/api/v4/user?access_token=OAUTH-TOKEN
```

or you can put the token to the Authorization header:

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" "https://gitlab.example.com/api/v4/user"
```

## Access Git over HTTPS with `access token`

A token with [scope](../integration/oauth_provider.md#view-all-authorized-applications)
`read_repository` or `write_repository` can access Git over HTTPS. Use the token as the password.
You can set the username to any string value. You should use `oauth2`:

```plaintext
https://oauth2:<your_access_token>@gitlab.example.com/project_path/project_name.git
```

Alternatively, you can use a [Git credential helper](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)
to authenticate to GitLab with OAuth. This handles OAuth token refresh
automatically.

## Retrieve the token information

To verify the details of a token, use the `token/info` endpoint provided by the
Doorkeeper gem. For more information, see
[`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo).

You must supply the access token, either:

- As a parameter:

  ```plaintext
  GET https://gitlab.example.com/oauth/token/info?access_token=<OAUTH-TOKEN>
  ```

- In the Authorization header:

  ```shell
  curl --header "Authorization: Bearer <OAUTH-TOKEN>" "https://gitlab.example.com/oauth/token/info"
  ```

The following is an example response:

```json
{
    "resource_owner_id": 1,
    "scope": ["api"],
    "expires_in": null,
    "application": {"uid": "1cb242f495280beb4291e64bee2a17f330902e499882fe8e1e2aa875519cab33"},
    "created_at": 1575890427
}
```

### Deprecated fields

The fields `scopes` and `expires_in_seconds` are included in the response but are now deprecated. The `scopes` field is an alias for `scope`, and the `expires_in_seconds` field is an alias for `expires_in`. For more information, see [Doorkeeper API changes](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#api-changes-5).

## Revoke a token

To revoke a token, use the `revoke` endpoint. The API returns a 200 response code and an empty
JSON hash to indicate success.

```ruby
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&token=TOKEN'
RestClient.post 'https://gitlab.example.com/oauth/revoke', parameters
```

## OAuth 2.0 tokens and GitLab registries

Standard OAuth 2.0 tokens support different degrees of access to GitLab
registries, as they:

- Do not allow users to authenticate to:
  - The GitLab [container registry](../user/packages/container_registry/authenticate_with_container_registry.md).
  - Packages listed in the GitLab [Package registry](../user/packages/package_registry/_index.md).
- Allow users to get, list, and delete registries through
  the [container registry API](container_registry.md).
