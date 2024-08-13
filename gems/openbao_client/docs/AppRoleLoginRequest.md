# OpenbaoClient::AppRoleLoginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_id** | **String** | Unique identifier of the Role. Required to be supplied when the &#39;bind_secret_id&#39; constraint is set. | [optional] |
| **secret_id** | **String** | SecretID belong to the App role | [optional][default to &#39;&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleLoginRequest.new(
  role_id: null,
  secret_id: null
)
```

