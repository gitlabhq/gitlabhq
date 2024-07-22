# OpenbaoClient::OidcRotateKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **verification_ttl** | **Integer** | Controls how long the public portion of a key will be available for verification after being rotated. Setting verification_ttl here will override the verification_ttl set on the key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcRotateKeyRequest.new(
  verification_ttl: null
)
```

