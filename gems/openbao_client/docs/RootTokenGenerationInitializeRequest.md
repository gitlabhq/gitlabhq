# OpenbaoClient::RootTokenGenerationInitializeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pgp_key** | **String** | Specifies a base64-encoded PGP public key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RootTokenGenerationInitializeRequest.new(
  pgp_key: null
)
```

