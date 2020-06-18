# GitLab as an OAuth2 provider

This document covers using the [OAuth2](https://oauth.net/2/) protocol to allow
other services to access GitLab resources on user's behalf.

If you want GitLab to be an OAuth authentication service provider to sign into
other services, see the [OAuth2 authentication service provider](../integration/oauth_provider.md)
documentation. This functionality is based on the
[doorkeeper Ruby gem](https://github.com/doorkeeper-gem/doorkeeper).

## Supported OAuth2 flows

GitLab currently supports the following authorization flows:

- **Web application flow:** Most secure and common type of flow, designed for
  applications with secure server-side.
- **Implicit grant flow:** This flow is designed for user-agent only apps (e.g., single
  page web application running on GitLab Pages).
- **Resource owner password credentials flow:** To be used **only** for securely
  hosted, first-party services.

Refer to the [OAuth RFC](https://tools.ietf.org/html/rfc6749) to find out
how all those flows work and pick the right one for your use case.

Both **web application** and **implicit grant** flows require `application` to be
registered first via the `/profile/applications` page in your user's account.
During registration, by enabling proper scopes, you can limit the range of
resources which the `application` can access. Upon creation, you'll obtain the
`application` credentials: _Application ID_ and _Client Secret_ - **keep them secure**.

CAUTION: **Important:**
OAuth specification advises sending the `state` parameter with each request to
`/oauth/authorize`. We highly recommended sending a unique value with each request
and validate it against the one in the redirect request. This is important in
order to prevent [CSRF attacks](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)).
The `state` parameter really should have been a requirement in the standard!

In the following sections you will find detailed instructions on how to obtain
authorization with each flow.

### Web application flow

NOTE: **Note:**
Check the [RFC spec](https://tools.ietf.org/html/rfc6749#section-4.1) for a
detailed flow description.

The web application flow is:

1. Request authorization code. To do that, you should redirect the user to the
   `/oauth/authorize` endpoint with the following GET parameters:

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=YOUR_UNIQUE_STATE_HASH&scope=REQUESTED_SCOPES
   ```

   This will ask the user to approve the applications access to their account
   based on the scopes specified in `REQUESTED_SCOPES` and then redirect back to
   the `REDIRECT_URI` you provided. The [scope parameter](https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes#requesting-particular-scopes)
   is a space separated list of scopes you want to have access to (e.g. `scope=read_user+profile`
   would request `read_user` and `profile` scopes). The redirect will
   include the GET `code` parameter, for example:

   ```plaintext
   http://myapp.com/oauth/redirect?code=1234567890&state=YOUR_UNIQUE_STATE_HASH
   ```

   You should then use `code` to request an access token.

1. Once you have the authorization code you can request an `access_token` using the
   code. You can do that by using any HTTP client. In the following example,
   we are using Ruby's `rest-client`:

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'http://gitlab.example.com/oauth/token', parameters
   ```

   Example response:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1"
   }
   ```

NOTE: **Note:**
The `redirect_uri` must match the `redirect_uri` used in the original
authorization request.

You can now make requests to the API with the access token returned.

### Implicit grant flow

NOTE: **Note:**
Check the [RFC spec](https://tools.ietf.org/html/rfc6749#section-4.2) for a
detailed flow description.

CAUTION: **Important:**
Avoid using this flow for applications that store data outside of the GitLab
instance. If you do, make sure to verify `application id` associated with the
access token before granting access to the data
(see [`/oauth/token/info`](#retrieving-the-token-information)).

Unlike the web flow, the client receives an `access token` immediately as a
result of the authorization request. The flow does not use the client secret
or the authorization code because all of the application code and storage is
easily accessible, therefore secrets can leak easily.

To request the access token, you should redirect the user to the
`/oauth/authorize` endpoint using `token` response type:

```plaintext
https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=token&state=YOUR_UNIQUE_STATE_HASH&scope=REQUESTED_SCOPES
```

This will ask the user to approve the applications access to their account
based on the scopes specified in `REQUESTED_SCOPES` and then redirect back to
the `REDIRECT_URI` you provided. The [scope parameter](https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes#requesting-particular-scopes)
   is a space separated list of scopes you want to have access to (e.g. `scope=read_user+profile`
would request `read_user` and `profile` scopes). The redirect
will include a fragment with `access_token` as well as token details in GET
parameters, for example:

```plaintext
http://myapp.com/oauth/redirect#access_token=ABCDExyz123&state=YOUR_UNIQUE_STATE_HASH&token_type=bearer&expires_in=3600
```

### Resource owner password credentials flow

NOTE: **Note:**
Check the [RFC spec](https://tools.ietf.org/html/rfc6749#section-4.3) for a
detailed flow description.

NOTE: **Note:**
The Resource Owner Password Credentials is disabled for users with [two-factor
authentication](../user/profile/account/two_factor_authentication.md) turned on.
These users can access the API using [personal access tokens](../user/profile/personal_access_tokens.md)
instead.

In this flow, a token is requested in exchange for the resource owner credentials
(username and password).

The credentials should only be used when:

- There is a high degree of trust between the resource owner and the client. For
  example, the client is part of the device operating system or a highly
  privileged application.
- Other authorization grant types are not available (such as an authorization code).

CAUTION: **Important:**
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

Also you must use HTTP Basic authentication using the `client_id` and`client_secret`
values to authenticate the client that performs a request.

Example cURL request:

```shell
echo 'grant_type=password&username=<your_username>&password=<your_password>' > auth.txt
curl --data "@auth.txt" --user client_id:client_secret --request POST "https://gitlab.example.com/oauth/token"
```

Then, you'll receive the access token back in the response:

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
client = OAuth2::Client.new('the_client_id', 'the_client_secret', :site => "http://example.com")
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

## Retrieving the token information

To verify the details of a token, use the `token/info` endpoint provided by the Doorkeeper gem.
For more information, see [`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo).

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

The fields `scopes` and `expires_in_seconds` are included in the response.

These are aliases for `scope` and `expires_in` respectively, and have been included to
prevent breaking changes introduced in [doorkeeper 5.0.2](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#from-4x-to-5x).

Don't rely on these fields as they will be removed in a later release.
