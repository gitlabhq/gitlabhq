# OpenbaoClient::PkiIssuerSignIntermediateResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **Array&lt;String&gt;** | CA Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **expiration** | **Integer** | Expiration Time | [optional] |
| **issuing_ca** | **String** | Issuing CA | [optional] |
| **serial_number** | **String** | Serial Number | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuerSignIntermediateResponse.new(
  ca_chain: null,
  certificate: null,
  expiration: null,
  issuing_ca: null,
  serial_number: null
)
```

