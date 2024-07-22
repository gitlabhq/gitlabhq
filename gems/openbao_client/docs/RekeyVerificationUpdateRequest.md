# OpenbaoClient::RekeyVerificationUpdateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** | Specifies a single unseal share key from the new set of shares. | [optional] |
| **nonce** | **String** | Specifies the nonce of the rekey verification operation. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RekeyVerificationUpdateRequest.new(
  key: null,
  nonce: null
)
```

