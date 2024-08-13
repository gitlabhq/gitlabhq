# OpenbaoClient::OidcProviderTokenRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **client_id** | **String** | The ID of the requesting client. | [optional] |
| **client_secret** | **String** | The secret of the requesting client. | [optional] |
| **code** | **String** | The authorization code received from the provider&#39;s authorization endpoint. |  |
| **code_verifier** | **String** | The code verifier associated with the authorization code. | [optional] |
| **grant_type** | **String** | The authorization grant type. The following grant types are supported: &#39;authorization_code&#39;. |  |
| **redirect_uri** | **String** | The callback location where the authentication response was sent. |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcProviderTokenRequest.new(
  client_id: null,
  client_secret: null,
  code: null,
  code_verifier: null,
  grant_type: null,
  redirect_uri: null
)
```

