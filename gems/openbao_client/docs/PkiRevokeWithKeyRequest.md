# OpenbaoClient::PkiRevokeWithKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | Certificate to revoke in PEM format; must be signed by an issuer in this mount. | [optional] |
| **private_key** | **String** | Key to use to verify revocation permission; must be in PEM format. | [optional] |
| **serial_number** | **String** | Certificate serial number, in colon- or hyphen-separated octal | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRevokeWithKeyRequest.new(
  certificate: null,
  private_key: null,
  serial_number: null
)
```

