# OpenbaoClient::RootTokenGenerationInitialize2Request

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pgp_key** | **String** | Specifies a base64-encoded PGP public key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RootTokenGenerationInitialize2Request.new(
  pgp_key: null
)
```

