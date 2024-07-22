# OpenbaoClient::AppRoleWriteRoleIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_id** | **String** | Identifier of the role. Defaults to a UUID. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteRoleIdRequest.new(
  role_id: null
)
```

