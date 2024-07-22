# OpenbaoClient::PkiIssuerIssueWithRoleResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **Array&lt;String&gt;** | Certificate Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **expiration** | **Integer** | Time of expiration | [optional] |
| **issuing_ca** | **String** | Issuing Certificate Authority | [optional] |
| **private_key** | **String** | Private key | [optional] |
| **private_key_type** | **String** | Private key type | [optional] |
| **serial_number** | **String** | Serial Number | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuerIssueWithRoleResponse.new(
  ca_chain: null,
  certificate: null,
  expiration: null,
  issuing_ca: null,
  private_key: null,
  private_key_type: null,
  serial_number: null
)
```

