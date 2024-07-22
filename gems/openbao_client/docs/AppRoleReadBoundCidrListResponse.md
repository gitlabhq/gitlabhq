# OpenbaoClient::AppRoleReadBoundCidrListResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bound_cidr_list** | **Array&lt;String&gt;** | Deprecated: Please use \&quot;secret_id_bound_cidrs\&quot; instead. Comma separated string or list of CIDR blocks. If set, specifies the blocks of IP addresses which can perform the login operation. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadBoundCidrListResponse.new(
  bound_cidr_list: null
)
```

