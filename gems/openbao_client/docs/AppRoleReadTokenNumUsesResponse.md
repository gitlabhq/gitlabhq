# OpenbaoClient::AppRoleReadTokenNumUsesResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_num_uses** | **Integer** | The maximum number of times a token may be used, a value of zero means unlimited | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadTokenNumUsesResponse.new(
  token_num_uses: null
)
```

