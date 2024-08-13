# OpenbaoClient::EntityUpdateAliasByIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **canonical_id** | **String** | Entity ID to which this alias should be tied to | [optional] |
| **custom_metadata** | **Object** | User provided key-value pairs | [optional] |
| **entity_id** | **String** | Entity ID to which this alias belongs to. This field is deprecated, use canonical_id. | [optional] |
| **mount_accessor** | **String** | (Unused) | [optional] |
| **name** | **String** | (Unused) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::EntityUpdateAliasByIdRequest.new(
  canonical_id: null,
  custom_metadata: null,
  entity_id: null,
  mount_accessor: null,
  name: null
)
```

