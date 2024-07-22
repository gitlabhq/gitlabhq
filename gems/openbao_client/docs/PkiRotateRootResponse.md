# OpenbaoClient::PkiRotateRootResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | The generated self-signed CA certificate. | [optional] |
| **expiration** | **Integer** | The expiration of the given issuer. | [optional] |
| **issuer_id** | **String** | The ID of the issuer | [optional] |
| **issuer_name** | **String** | The name of the issuer. | [optional] |
| **issuing_ca** | **String** | The issuing certificate authority. | [optional] |
| **key_id** | **String** | The ID of the key. | [optional] |
| **key_name** | **String** | The key name if given. | [optional] |
| **private_key** | **String** | The private key if exported was specified. | [optional] |
| **serial_number** | **String** | The requested Subject&#39;s named serial number. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRotateRootResponse.new(
  certificate: null,
  expiration: null,
  issuer_id: null,
  issuer_name: null,
  issuing_ca: null,
  key_id: null,
  key_name: null,
  private_key: null,
  serial_number: null
)
```

