# OpenbaoClient::MfaGenerateTotpSecretRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaGenerateTotpSecretRequest.new(
  method_id: null
)
```

