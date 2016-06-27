# GitLab as an OAuth2 client

This document is about using other OAuth authentication service providers to sign into GitLab.
If you want GitLab to be an OAuth authentication service provider to sign into other services please see the [Oauth2 provider documentation](../integration/oauth_provider.md).

OAuth2 is a protocol that enables us to authenticate a user without requiring them to give their password. 

Before using the OAuth2 you should create an application in user's account. Each application gets a unique App ID and App Secret parameters. You should not share these.

This functionality is based on [doorkeeper gem](https://github.com/doorkeeper-gem/doorkeeper)

## Web Application Flow

This flow is using for authentication from third-party web sites and is probably used the most. 
It basically consists of an exchange of an authorization token for an access token. For more detailed info, check out the [RFC spec here](http://tools.ietf.org/html/rfc6749#section-4.1)

This flow consists from 3 steps.

### 1. Registering the client

Create an application in user's account profile.

### 2. Requesting authorization

To request the authorization token, you should visit the `/oauth/authorize` endpoint. You can do that by visiting manually the URL:

```
http://localhost:3000/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code
```

Where REDIRECT_URI is the URL in your app where users will be sent after authorization. 	

### 3. Requesting the access token

To request the access token, you should use the returned code and exchange it for an access token. To do that you can use any HTTP client. In this case, I used rest-client:

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

You can now make requests to the API with the access token returned.

###  Use the access token to access the API

The access token allows you to make requests to the API on a behalf of a user.

```
GET https://localhost:3000/api/v3/user?access_token=OAUTH-TOKEN
```

Or you can put the token to the Authorization header:

```
curl -H "Authorization: Bearer OAUTH-TOKEN" https://localhost:3000/api/v3/user
```

## Resource Owner Password Credentials

## Deprecation Notice

1. Starting in GitLab 9.0, the Resource Owner Password Credentials will be *disabled* for users with two-factor authentication turned on.
2. These users can access the API using [personal access tokens] instead.

---

In this flow, a token is requested in exchange for the resource owner credentials (username and password). 
The credentials should only be used when there is a high degree of trust between the resource owner and the client (e.g. the
client is part of the device operating system or a highly privileged application), and when other authorization grant types are not
available (such as an authorization code).

Even though this grant type requires direct client access to the resource owner credentials, the resource owner credentials are used
for a single request and are exchanged for an access token.  This grant type can eliminate the need for the client to store the
resource owner credentials for future use, by exchanging the credentials with a long-lived access token or refresh token.
You can do POST request to `/oauth/token` with parameters:

```
{
  "grant_type"    : "password",
  "username"      : "user@example.com",
  "password"      : "sekret"
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
access_token = client.password.get_token('user@example.com', 'sekret')
```

[personal access tokens]: ./README.md#personal-access-tokens
