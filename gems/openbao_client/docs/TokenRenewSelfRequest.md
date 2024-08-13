# OpenbaoClient::TokenRenewSelfRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **increment** | **Integer** | The desired increment in seconds to the token expiration | [optional][default to 0] |
| **token** | **String** | Token to renew (unused, does not need to be set) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TokenRenewSelfRequest.new(
  increment: null,
  token: null
)
```

