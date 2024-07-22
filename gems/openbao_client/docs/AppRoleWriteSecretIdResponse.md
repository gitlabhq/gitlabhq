# OpenbaoClient::AppRoleWriteSecretIdResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id** | **String** | Secret ID attached to the role. | [optional] |
| **secret_id_accessor** | **String** | Accessor of the secret ID | [optional] |
| **secret_id_num_uses** | **Integer** | Number of times a secret ID can access the role, after which the secret ID will expire. | [optional] |
| **secret_id_ttl** | **Integer** | Duration in seconds after which the issued secret ID expires. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteSecretIdResponse.new(
  secret_id: null,
  secret_id_accessor: null,
  secret_id_num_uses: null,
  secret_id_ttl: null
)
```

