# OpenbaoClient::OidcWriteAssignmentRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_ids** | **Array&lt;String&gt;** | Comma separated string or array of identity entity IDs | [optional] |
| **group_ids** | **Array&lt;String&gt;** | Comma separated string or array of identity group IDs | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteAssignmentRequest.new(
  entity_ids: null,
  group_ids: null
)
```

