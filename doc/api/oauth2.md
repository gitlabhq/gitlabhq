# GitLab as an OAuth2 provider

This document covers using the [OAuth2](https://oauth.net/2/) protocol to allow other services access Gitlab resources on user's behalf. 

If you want GitLab to be an OAuth authentication service provider to sign into other services please see the [OAuth2 provider](../integration/oauth_provider.md)
documentation.

This functionality is based on [doorkeeper gem](https://github.com/doorkeeper-gem/doorkeeper). 

## Supported OAuth2 Flows

Gitlab currently supports following authorization flows: 

* *Web Application Flow* - Most secure and common type of flow, designed for the applications with secure server-side.
* *Implicit Flow* - This flow is designed for user-agent only apps (e.g. single page web application running on GitLab Pages).
* *Resource Owner Password Credentials Flow* - To be used **only** for securely hosted, first-party services.

Please refer to [OAuth RFC](https://tools.ietf.org/html/rfc6749) to find out in details how all those flows work and pick the right one for your use case.

Both *web application* and *implicit* flows require `application` to be registered first via `/profile/applications` page 
in your user's account. During registration, by enabling proper scopes you can limit the range of resources which the `application` can access. Upon creation 
you'll obtain `application` credentials: _Application ID_ and _Client Secret_ - **keep them secure**.

>**Important:** OAuth specification advises sending `state` parameter with each request to `/oauth/authorize`. We highly recommended to send a unique 
value with each request and validate it against the one in redirect request. This is important to prevent [CSRF attacks]. The `state` param really should 
have been a requirement in the standard!

In the following sections you will find detailed instructions on how to obtain authorization with each flow. 

### Web Application Flow 

Check [RFC spec](http://tools.ietf.org/html/rfc6749#section-4.1) for a detailed flow description

#### 1. Requesting authorization code

To request the authorization code, you should redirect the user to the `/oauth/authorize` endpoint with following GET parameters:

```
https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=YOUR_UNIQUE_STATE_HASH
```

This will ask the user to approve the applications access to their account and then redirect back to the `REDIRECT_URI` you provided. The redirect will
include the GET `code` parameter, for example:

`http://myapp.com/oauth/redirect?code=1234567890&state=YOUR_UNIQUE_STATE_HASH`

You should then use the `code` to request an access token.

#### 2. Requesting access token

Once you have the authorization code you can request an `access_token` using the code, to do that you can use any HTTP client. In the following example, 
we are using Ruby's `rest-client`:

```
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
RestClient.post 'http://gitlab.example.com/oauth/token', parameters

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


### Implicit Grant

Check [RFC spec](http://tools.ietf.org/html/rfc6749#section-4.2) for a detailed flow description.

Unlike the web flow, the client receives an `access token` immediately as a result of the authorization request. The flow does not use client secret 
or authorization code because all of the application code and storage is easily accessible, therefore __secrets__ can leak easily. 

>**Important:** Avoid using this flow for applications that store data outside of the Gitlab instance. If you do, make sure to verify `application id` 
associated with access token before granting access to the data 
(see [/oauth/token/info](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo)). 
 

#### 1. Requesting access token

To request the access token, you should redirect the user to the `/oauth/authorize` endpoint using `token` response type:

```
https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=token&state=YOUR_UNIQUE_STATE_HASH
```

This will ask the user to approve the applications access to their account and then redirect back to the `REDIRECT_URI` you provided. The redirect 
will include a fragment with `access_token` as well as token details in GET parameters, for example:

```
http://myapp.com/oauth/redirect#access_token=ABCDExyz123&state=YOUR_UNIQUE_STATE_HASH&token_type=bearer&expires_in=3600
```

### Resource Owner Password Credentials

Check [RFC spec](http://tools.ietf.org/html/rfc6749#section-4.3) for a detailed flow description.

> **Deprecation notice:** Starting in GitLab 8.11, the Resource Owner Password Credentials has been *disabled* for users with two-factor authentication 
turned on. These users can access the API using [personal access tokens] instead.

In this flow, a token is requested in exchange for the resource owner credentials (username and password).
The credentials should only be used when there is a high degree of trust between the resource owner and the client (e.g. the
client is part of the device operating system or a highly privileged application), and when other authorization grant types are not
available (such as an authorization code).

>**Important:**
Never store the users credentials and only use this grant type when your client is deployed to a trusted environment, in 99% of cases [personal access tokens] 
are a better choice.

Even though this grant type requires direct client access to the resource owner credentials, the resource owner credentials are used
for a single request and are exchanged for an access token.  This grant type can eliminate the need for the client to store the
resource owner credentials for future use, by exchanging the credentials with a long-lived access token or refresh token.

#### 1. Requesting access token

POST request to `/oauth/token` with parameters:

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

##  Access Gitlab API with `access token`

The `access token` allows you to make requests to the API on a behalf of a user. You can pass the token either as GET parameter 
```
GET https://gitlab.example.com/api/v4/user?access_token=OAUTH-TOKEN
```

or you can put the token to the Authorization header:

```
curl --header "Authorization: Bearer OAUTH-TOKEN" https://gitlab.example.com/api/v4/user
```

[personal access tokens]: ../user/profile/personal_access_tokens.md
[CSRF attacks]: http://www.oauthsecurity.com/#user-content-authorization-code-flow