# OpenbaoClient::EntityCreateAliasRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **canonical_id** | **String** | Entity ID to which this alias belongs | [optional] |
| **custom_metadata** | **Object** | User provided key-value pairs | [optional] |
| **entity_id** | **String** | Entity ID to which this alias belongs. This field is deprecated, use canonical_id. | [optional] |
| **id** | **String** | ID of the entity alias. If set, updates the corresponding entity alias. | [optional] |
| **mount_accessor** | **String** | Mount accessor to which this alias belongs to; unused for a modify | [optional] |
| **name** | **String** | Name of the alias; unused for a modify | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::EntityCreateAliasRequest.new(
  canonical_id: null,
  custom_metadata: null,
  entity_id: null,
  id: null,
  mount_accessor: null,
  name: null
)
```

