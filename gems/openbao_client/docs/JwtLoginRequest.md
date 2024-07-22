# OpenbaoClient::JwtLoginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt** | **String** | The signed JWT to validate. | [optional] |
| **role** | **String** | The role to log in against. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::JwtLoginRequest.new(
  jwt: null,
  role: null
)
```

