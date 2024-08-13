# OpenbaoClient::MfaAdminDestroyTotpSecretRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_id** | **String** | Identifier of the entity from which the MFA method secret needs to be removed. |  |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaAdminDestroyTotpSecretRequest.new(
  entity_id: null,
  method_id: null
)
```

