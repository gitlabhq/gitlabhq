# OpenbaoClient::AppRoleReadLocalSecretIdsResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **local_secret_ids** | **Boolean** | If true, the secret identifiers generated using this role will be cluster local. This can only be set during role creation and once set, it can&#39;t be reset later | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadLocalSecretIdsResponse.new(
  local_secret_ids: null
)
```

