# OpenbaoClient::GroupLookUpRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alias_id** | **String** | ID of the alias. | [optional] |
| **alias_mount_accessor** | **String** | Accessor of the mount to which the alias belongs to. This should be supplied in conjunction with &#39;alias_name&#39;. | [optional] |
| **alias_name** | **String** | Name of the alias. This should be supplied in conjunction with &#39;alias_mount_accessor&#39;. | [optional] |
| **id** | **String** | ID of the group. | [optional] |
| **name** | **String** | Name of the group. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::GroupLookUpRequest.new(
  alias_id: null,
  alias_mount_accessor: null,
  alias_name: null,
  id: null,
  name: null
)
```

