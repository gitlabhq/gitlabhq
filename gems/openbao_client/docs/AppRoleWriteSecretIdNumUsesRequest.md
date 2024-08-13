# OpenbaoClient::AppRoleWriteSecretIdNumUsesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id_num_uses** | **Integer** | Number of times a SecretID can access the role, after which the SecretID will expire. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteSecretIdNumUsesRequest.new(
  secret_id_num_uses: null
)
```

