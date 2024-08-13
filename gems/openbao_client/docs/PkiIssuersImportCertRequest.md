# OpenbaoClient::PkiIssuersImportCertRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pem_bundle** | **String** | PEM-format, concatenated unencrypted secret-key (optional) and certificates. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuersImportCertRequest.new(
  pem_bundle: null
)
```

