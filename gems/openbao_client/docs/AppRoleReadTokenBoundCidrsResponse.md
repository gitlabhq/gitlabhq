# OpenbaoClient::AppRoleReadTokenBoundCidrsResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks. If set, specifies the blocks of IP addresses which can use the returned token. Should be a subset of the token CIDR blocks listed on the role, if any. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadTokenBoundCidrsResponse.new(
  token_bound_cidrs: null
)
```

