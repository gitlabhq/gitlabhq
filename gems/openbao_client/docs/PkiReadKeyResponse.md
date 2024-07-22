# OpenbaoClient::PkiReadKeyResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_id** | **String** | Key Id | [optional] |
| **key_name** | **String** | Key Name | [optional] |
| **key_type** | **String** | Key Type | [optional] |
| **subject_key_id** | **String** | RFC 5280 Subject Key Identifier of the public counterpart | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiReadKeyResponse.new(
  key_id: null,
  key_name: null,
  key_type: null,
  subject_key_id: null
)
```

