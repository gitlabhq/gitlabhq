# OpenbaoClient::EncryptionKeyConfigureRotationRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether automatic rotation is enabled. | [optional] |
| **interval** | **Integer** | How long after installation of an active key term that the key will be automatically rotated. | [optional] |
| **max_operations** | **Integer** | The number of encryption operations performed before the barrier key is automatically rotated. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::EncryptionKeyConfigureRotationRequest.new(
  enabled: null,
  interval: null,
  max_operations: null
)
```

