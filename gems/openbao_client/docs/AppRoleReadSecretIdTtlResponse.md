# OpenbaoClient::AppRoleReadSecretIdTtlResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id_ttl** | **Integer** | Duration in seconds after which the issued secret ID should expire. Defaults to 0, meaning no expiration. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadSecretIdTtlResponse.new(
  secret_id_ttl: null
)
```

