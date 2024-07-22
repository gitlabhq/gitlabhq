# OpenbaoClient::OidcProviderAuthorizeWithParametersRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **client_id** | **String** | The ID of the requesting client. |  |
| **code_challenge** | **String** | The code challenge derived from the code verifier. | [optional] |
| **code_challenge_method** | **String** | The method that was used to derive the code challenge. The following methods are supported: &#39;S256&#39;, &#39;plain&#39;. Defaults to &#39;plain&#39;. | [optional][default to &#39;plain&#39;] |
| **max_age** | **Integer** | The allowable elapsed time in seconds since the last time the end-user was actively authenticated. | [optional] |
| **nonce** | **String** | The value that will be returned in the ID token nonce claim after a token exchange. | [optional] |
| **redirect_uri** | **String** | The redirection URI to which the response will be sent. |  |
| **response_type** | **String** | The OIDC authentication flow to be used. The following response types are supported: &#39;code&#39; |  |
| **scope** | **String** | A space-delimited, case-sensitive list of scopes to be requested. The &#39;openid&#39; scope is required. |  |
| **state** | **String** | The value used to maintain state between the authentication request and client. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcProviderAuthorizeWithParametersRequest.new(
  client_id: null,
  code_challenge: null,
  code_challenge_method: null,
  max_age: null,
  nonce: null,
  redirect_uri: null,
  response_type: null,
  scope: null,
  state: null
)
```

