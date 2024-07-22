# OpenbaoClient::OidcConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer** | **String** | Issuer URL to be used in the iss claim of the token. If not set, OpenBao&#39;s app_addr will be used. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcConfigureRequest.new(
  issuer: null
)
```

