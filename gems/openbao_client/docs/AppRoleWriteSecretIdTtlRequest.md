# OpenbaoClient::AppRoleWriteSecretIdTtlRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id_ttl** | **Integer** | Duration in seconds after which the issued SecretID should expire. Defaults to 0, meaning no expiration. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteSecretIdTtlRequest.new(
  secret_id_ttl: null
)
```

