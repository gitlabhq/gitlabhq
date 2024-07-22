# OpenbaoClient::PkiGenerateInternalKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_bits** | **Integer** | The number of bits to use. Allowed values are 0 (universal default); with rsa key_type: 2048 (default), 3072, or 4096; with ec key_type: 224, 256 (default), 384, or 521; ignored with ed25519. | [optional][default to 0] |
| **key_name** | **String** | Optional name to be used for this key | [optional] |
| **key_type** | **String** | The type of key to use; defaults to RSA. \&quot;rsa\&quot; \&quot;ec\&quot; and \&quot;ed25519\&quot; are the only valid values. | [optional][default to &#39;rsa&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiGenerateInternalKeyRequest.new(
  key_bits: null,
  key_name: null,
  key_type: null
)
```

