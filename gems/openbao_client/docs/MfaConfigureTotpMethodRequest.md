# OpenbaoClient::MfaConfigureTotpMethodRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm** | **String** | The hashing algorithm used to generate the TOTP token. Options include SHA1, SHA256 and SHA512. | [optional][default to &#39;SHA1&#39;] |
| **digits** | **Integer** | The number of digits in the generated TOTP token. This value can either be 6 or 8. | [optional][default to 6] |
| **issuer** | **String** | The name of the key&#39;s issuing organization. | [optional] |
| **key_size** | **Integer** | Determines the size in bytes of the generated key. | [optional][default to 20] |
| **max_validation_attempts** | **Integer** | Max number of allowed validation attempts. | [optional] |
| **method_name** | **String** | The unique name identifier for this MFA method. | [optional] |
| **period** | **Integer** | The length of time used to generate a counter for the TOTP token calculation. | [optional][default to 30] |
| **qr_size** | **Integer** | The pixel size of the generated square QR code. | [optional][default to 200] |
| **skew** | **Integer** | The number of delay periods that are allowed when validating a TOTP token. This value can either be 0 or 1. | [optional][default to 1] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaConfigureTotpMethodRequest.new(
  algorithm: null,
  digits: null,
  issuer: null,
  key_size: null,
  max_validation_attempts: null,
  method_name: null,
  period: null,
  qr_size: null,
  skew: null
)
```

