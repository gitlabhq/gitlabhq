# OpenbaoClient::AppRoleWriteSecretIdBoundCidrsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **secret_id_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks. If set, specifies the blocks of IP addresses which can perform the login operation. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteSecretIdBoundCidrsRequest.new(
  secret_id_bound_cidrs: null
)
```

