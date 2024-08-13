# OpenbaoClient::AppRoleWriteTokenMaxTtlRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_max_ttl** | **Integer** | The maximum lifetime of the generated token | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteTokenMaxTtlRequest.new(
  token_max_ttl: null
)
```

