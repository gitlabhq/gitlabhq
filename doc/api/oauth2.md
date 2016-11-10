# GitLab as an OAuth2 provider

This document covers using the OAuth2 protocol to access GitLab.

If you want GitLab to be an OAuth authentication service provider to sign into other services please see the [Oauth2 provider documentation](../integration/oauth_provider.md).

OAuth2 is a protocol that enables us to authenticate a user without requiring them to give their password to a third-party.

This functionality is based on [doorkeeper gem](https://github.com/doorkeeper-gem/doorkeeper)

## Web Application Flow

This is the most common type of flow and is used by server-side clients that wish to access GitLab on a user's behalf.

>**Note:**
This flow **should not** be used for client-side clients as you would leak your `client_secret`. Client-side clients should use the Implicit Grant (which is currently unsupported).

For more detailed information, check out the [RFC spec](http://tools.ietf.org/html/rfc6749#section-4.1)

In the following sections you will be introduced to the three steps needed for this flow.

### 1. Registering the client

First, you should create an application (`/profile/applications`) in your user's account.
Each application gets a unique App ID and App Secret parameters.

>**Note:**
**You should not share/leak your App ID or App Secret.**

### 2. Requesting authorization

To request the authorization code, you should redirect the user to the `/oauth/authorize` endpoint:

```
https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=your_unique_state_hash
```

This will ask the user to approve the applications access to their account and then redirect back to the `REDIRECT_URI` you provided.

The redirect will include the GET `code` parameter, for example:

```
http://myapp.com/oauth/redirect?code=1234567890&state=your_unique_state_hash
```

You should then use the `code` to request an access token.

>**Important:**
It is highly recommended that you send a `state` value with the request to `/oauth/authorize` and
validate that value is returned and matches in the redirect request.
This is important to prevent [CSRF attacks](http://www.oauthsecurity.com/#user-content-authorization-code-flow),
`state` really should have been a requirement in the standard!

### 3. Requesting the access token

Once you have the authorization code you can request an `access_token` using the code, to do that you can use any HTTP client. In the following example, we are using Ruby's `rest-client`:

```
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
RestClient.post 'http://localhost:3000/oauth/token', parameters

# The response will be
{
 "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
 "token_type": "bearer",
 "expires_in": 7200,
 "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1"
}
```
>**Note:**
The `redirect_uri` must match the `redirect_uri` used in the original authorization request.

You can now make requests to the API with the access token returned.

###  Use the access token to access the API

The access token allows you to make requests to the API on a behalf of a user.

```
GET https://localhost:3000/api/v3/user?access_token=OAUTH-TOKEN
```

Or you can put the token to the Authorization header:

```
curl --header "Authorization: Bearer OAUTH-TOKEN" https://localhost:3000/api/v3/user
```

## Resource Owner Password Credentials

## Deprecation Notice

1. Starting in GitLab 8.11, the Resource Owner Password Credentials has been *disabled* for users with two-factor authentication turned on.
2. These users can access the API using [personal access tokens] instead.

---

In this flow, a token is requested in exchange for the resource owner credentials (username and password).
The credentials should only be used when there is a high degree of trust between the resource owner and the client (e.g. the
client is part of the device operating system or a highly privileged application), and when other authorization grant types are not
available (such as an authorization code).

>**Important:**
Never store the users credentials and only use this grant type when your client is deployed to a trusted environment, in 99% of cases [personal access tokens] are a better choice.

Even though this grant type requires direct client access to the resource owner credentials, the resource owner credentials are used
for a single request and are exchanged for an access token.  This grant type can eliminate the need for the client to store the
resource owner credentials for future use, by exchanging the credentials with a long-lived access token or refresh token.
You can do POST request to `/oauth/token` with parameters:

```
{
  "grant_type"    : "password",
  "username"      : "user@example.com",
  "password"      : "secret"
}
```

Then, you'll receive the access token back in the response:

```
{
  "access_token": "1f0af717251950dbd4d73154fdf0a474a5c5119adad999683f5b450c460726aa",
  "token_type": "bearer",
  "expires_in": 7200
}
```

For testing you can use the oauth2 ruby gem:

```
client = OAuth2::Client.new('the_client_id', 'the_client_secret', :site => "http://example.com")
access_token = client.password.get_token('user@example.com', 'secret')
puts access_token.token
```

[personal access tokens]: ./README.md#personal-access-tokens