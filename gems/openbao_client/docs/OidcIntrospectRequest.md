# OpenbaoClient::OidcIntrospectRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **client_id** | **String** | Optional client_id to verify | [optional] |
| **token** | **String** | Token to verify | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcIntrospectRequest.new(
  client_id: null,
  token: null
)
```

