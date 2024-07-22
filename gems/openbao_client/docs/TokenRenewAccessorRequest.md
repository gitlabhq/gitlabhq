# OpenbaoClient::TokenRenewAccessorRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **accessor** | **String** | Accessor of the token to renew (request body) | [optional] |
| **increment** | **Integer** | The desired increment in seconds to the token expiration | [optional][default to 0] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TokenRenewAccessorRequest.new(
  accessor: null,
  increment: null
)
```

