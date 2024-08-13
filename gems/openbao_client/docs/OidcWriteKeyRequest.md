# OpenbaoClient::OidcWriteKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm** | **String** | Signing algorithm to use. This will default to RS256. | [optional][default to &#39;RS256&#39;] |
| **allowed_client_ids** | **Array&lt;String&gt;** | Comma separated string or array of role client ids allowed to use this key for signing. If empty no roles are allowed. If \&quot;*\&quot; all roles are allowed. | [optional] |
| **rotation_period** | **Integer** | How often to generate a new keypair. | [optional] |
| **verification_ttl** | **Integer** | Controls how long the public portion of a key will be available for verification after being rotated. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteKeyRequest.new(
  algorithm: null,
  allowed_client_ids: null,
  rotation_period: null,
  verification_ttl: null
)
```

