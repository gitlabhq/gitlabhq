# OpenbaoClient::PkiRevokeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | Certificate to revoke in PEM format; must be signed by an issuer in this mount. | [optional] |
| **serial_number** | **String** | Certificate serial number, in colon- or hyphen-separated octal | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRevokeRequest.new(
  certificate: null,
  serial_number: null
)
```

