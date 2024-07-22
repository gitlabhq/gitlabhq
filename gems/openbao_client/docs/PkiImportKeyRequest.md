# OpenbaoClient::PkiImportKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_name** | **String** | Optional name to be used for this key | [optional] |
| **pem_bundle** | **String** | PEM-format, unencrypted secret key | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiImportKeyRequest.new(
  key_name: null,
  pem_bundle: null
)
```

