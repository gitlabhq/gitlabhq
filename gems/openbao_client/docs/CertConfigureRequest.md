# OpenbaoClient::CertConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disable_binding** | **Boolean** | If set, during renewal, skips the matching of presented client identity with the client identity used during login. Defaults to false. | [optional][default to false] |
| **enable_identity_alias_metadata** | **Boolean** | If set, metadata of the certificate including the metadata corresponding to allowed_metadata_extensions will be stored in the alias. Defaults to false. | [optional][default to false] |
| **ocsp_cache_size** | **Integer** | The size of the in memory OCSP response cache, shared by all configured certs | [optional][default to 100] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CertConfigureRequest.new(
  disable_binding: null,
  enable_identity_alias_metadata: null,
  ocsp_cache_size: null
)
```

