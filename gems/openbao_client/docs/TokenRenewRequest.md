# OpenbaoClient::TokenRenewRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **increment** | **Integer** | The desired increment in seconds to the token expiration | [optional][default to 0] |
| **token** | **String** | Token to renew (request body) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TokenRenewRequest.new(
  increment: null,
  token: null
)
```

