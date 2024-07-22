# OpenbaoClient::PkiCrossSignIntermediateResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **csr** | **String** | Certificate signing request. | [optional] |
| **key_id** | **String** | Id of the key. | [optional] |
| **private_key** | **String** | Generated private key. | [optional] |
| **private_key_type** | **String** | Specifies the format used for marshaling the private key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiCrossSignIntermediateResponse.new(
  csr: null,
  key_id: null,
  private_key: null,
  private_key_type: null
)
```

