# OpenbaoClient::AppRoleReadBindSecretIdResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bind_secret_id** | **Boolean** | Impose secret_id to be presented when logging in using this role. Defaults to &#39;true&#39;. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadBindSecretIdResponse.new(
  bind_secret_id: null
)
```

