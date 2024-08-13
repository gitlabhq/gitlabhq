# OpenbaoClient::AppRoleReadSecretIdNumUsesResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id_num_uses** | **Integer** | Number of times a secret ID can access the role, after which the SecretID will expire. Defaults to 0 meaning that the secret ID is of unlimited use. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadSecretIdNumUsesResponse.new(
  secret_id_num_uses: null
)
```

