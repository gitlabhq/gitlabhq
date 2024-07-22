# OpenbaoClient::UiHeadersConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **multivalue** | **Boolean** | Returns multiple values if true | [optional] |
| **values** | **Array&lt;String&gt;** | The values to set the header. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::UiHeadersConfigureRequest.new(
  multivalue: null,
  values: null
)
```

