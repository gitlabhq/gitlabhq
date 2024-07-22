# OpenbaoClient::PkiReadCrlDeltaResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **String** | Issuing CA Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **issuer_id** | **String** | ID of the issuer | [optional] |
| **revocation_time** | **Integer** | Revocation time | [optional] |
| **revocation_time_rfc3339** | **String** | Revocation time RFC 3339 formatted | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiReadCrlDeltaResponse.new(
  ca_chain: null,
  certificate: null,
  issuer_id: null,
  revocation_time: null,
  revocation_time_rfc3339: null
)
```

