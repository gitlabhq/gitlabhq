# OpenbaoClient::AppRoleWriteTokenBoundCidrsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or JSON list of CIDR blocks. If set, specifies the blocks of IP addresses which are allowed to use the generated token. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteTokenBoundCidrsRequest.new(
  token_bound_cidrs: null
)
```

