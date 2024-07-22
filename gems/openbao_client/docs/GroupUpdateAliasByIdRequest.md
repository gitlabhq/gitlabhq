# OpenbaoClient::GroupUpdateAliasByIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **canonical_id** | **String** | ID of the group to which this is an alias. | [optional] |
| **mount_accessor** | **String** | Mount accessor to which this alias belongs to. | [optional] |
| **name** | **String** | Alias of the group. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::GroupUpdateAliasByIdRequest.new(
  canonical_id: null,
  mount_accessor: null,
  name: null
)
```

