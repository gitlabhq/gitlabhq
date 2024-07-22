# OpenbaoClient::MfaValidateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mfa_payload** | **Object** | A map from MFA method ID to a slice of passcodes or an empty slice if the method does not use passcodes |  |
| **mfa_request_id** | **String** | ID for this MFA request |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaValidateRequest.new(
  mfa_payload: null,
  mfa_request_id: null
)
```

