# OpenbaoClient::PkiConfigureCaRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pem_bundle** | **String** | PEM-format, concatenated unencrypted secret key and certificate. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureCaRequest.new(
  pem_bundle: null
)
```

