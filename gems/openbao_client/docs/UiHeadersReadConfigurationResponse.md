# OpenbaoClient::UiHeadersReadConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **value** | **String** | returns the first header value when &#x60;multivalue&#x60; request parameter is false | [optional] |
| **values** | **Array&lt;String&gt;** | returns all header values when &#x60;multivalue&#x60; request parameter is true | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::UiHeadersReadConfigurationResponse.new(
  value: null,
  values: null
)
```

