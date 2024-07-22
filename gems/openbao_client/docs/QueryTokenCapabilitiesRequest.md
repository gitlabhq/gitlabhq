# OpenbaoClient::QueryTokenCapabilitiesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **Array&lt;String&gt;** | Use &#39;paths&#39; instead. | [optional] |
| **paths** | **Array&lt;String&gt;** | Paths on which capabilities are being queried. | [optional] |
| **token** | **String** | Token for which capabilities are being queried. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::QueryTokenCapabilitiesRequest.new(
  path: null,
  paths: null,
  token: null
)
```

