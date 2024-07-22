# OpenbaoClient::TransitGenerateDataKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bits** | **Integer** | Number of bits for the key; currently 128, 256, and 512 bits are supported. Defaults to 256. | [optional][default to 256] |
| **context** | **String** | Context for key derivation. Required for derived keys. | [optional] |
| **key_version** | **Integer** | The version of the OpenBao key to use for encryption of the data key. Must be 0 (for latest) or a value greater than or equal to the min_encryption_version configured on the key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitGenerateDataKeyRequest.new(
  bits: null,
  context: null,
  key_version: null
)
```

