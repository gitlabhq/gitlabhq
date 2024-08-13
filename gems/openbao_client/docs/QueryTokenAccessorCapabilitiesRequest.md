# OpenbaoClient::QueryTokenAccessorCapabilitiesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **accessor** | **String** | Accessor of the token for which capabilities are being queried. | [optional] |
| **path** | **Array&lt;String&gt;** | Use &#39;paths&#39; instead. | [optional] |
| **paths** | **Array&lt;String&gt;** | Paths on which capabilities are being queried. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::QueryTokenAccessorCapabilitiesRequest.new(
  accessor: null,
  path: null,
  paths: null
)
```

