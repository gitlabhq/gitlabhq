# OpenbaoClient::RekeyAttemptUpdateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** | Specifies a single unseal key share. | [optional] |
| **nonce** | **String** | Specifies the nonce of the rekey attempt. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RekeyAttemptUpdateRequest.new(
  key: null,
  nonce: null
)
```

