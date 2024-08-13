# OpenbaoClient::CorsReadConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_headers** | **Array&lt;String&gt;** |  | [optional] |
| **allowed_origins** | **Array&lt;String&gt;** |  | [optional] |
| **enabled** | **Boolean** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CorsReadConfigurationResponse.new(
  allowed_headers: null,
  allowed_origins: null,
  enabled: null
)
```

