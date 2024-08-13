# OpenbaoClient::KerberosLoginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **authorization** | **String** | SPNEGO Authorization header. Required. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KerberosLoginRequest.new(
  authorization: null
)
```

