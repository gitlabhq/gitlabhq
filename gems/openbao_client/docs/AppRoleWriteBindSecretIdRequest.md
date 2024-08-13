# OpenbaoClient::AppRoleWriteBindSecretIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bind_secret_id** | **Boolean** | Impose secret_id to be presented when logging in using this role. | [optional][default to true] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteBindSecretIdRequest.new(
  bind_secret_id: null
)
```

