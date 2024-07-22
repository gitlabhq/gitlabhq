# OpenbaoClient::AliasCreateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **canonical_id** | **String** | Entity ID to which this alias belongs to | [optional] |
| **entity_id** | **String** | Entity ID to which this alias belongs to. This field is deprecated in favor of &#39;canonical_id&#39;. | [optional] |
| **id** | **String** | ID of the alias | [optional] |
| **mount_accessor** | **String** | Mount accessor to which this alias belongs to | [optional] |
| **name** | **String** | Name of the alias | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AliasCreateRequest.new(
  canonical_id: null,
  entity_id: null,
  id: null,
  mount_accessor: null,
  name: null
)
```

