# OpenbaoClient::OidcWriteProviderRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_client_ids** | **Array&lt;String&gt;** | The client IDs that are permitted to use the provider | [optional] |
| **issuer** | **String** | Specifies what will be used for the iss claim of ID tokens. | [optional] |
| **scopes_supported** | **Array&lt;String&gt;** | The scopes supported for requesting on the provider | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteProviderRequest.new(
  allowed_client_ids: null,
  issuer: null,
  scopes_supported: null
)
```

