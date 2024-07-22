# OpenbaoClient::JwtOidcRequestAuthorizationUrlRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **client_nonce** | **String** | Optional client-provided nonce that must match during callback, if present. | [optional] |
| **redirect_uri** | **String** | The OAuth redirect_uri to use in the authorization URL. | [optional] |
| **role** | **String** | The role to issue an OIDC authorization URL against. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::JwtOidcRequestAuthorizationUrlRequest.new(
  client_nonce: null,
  redirect_uri: null,
  role: null
)
```

