# OpenbaoClient::MfaAdminGenerateTotpSecretRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_id** | **String** | Entity ID on which the generated secret needs to get stored. |  |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaAdminGenerateTotpSecretRequest.new(
  entity_id: null,
  method_id: null
)
```

