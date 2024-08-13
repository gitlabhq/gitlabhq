# OpenbaoClient::CorsConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_headers** | **Array&lt;String&gt;** | A comma-separated string or array of strings indicating headers that are allowed on cross-origin requests. | [optional] |
| **allowed_origins** | **Array&lt;String&gt;** | A comma-separated string or array of strings indicating origins that may make cross-origin requests. | [optional] |
| **enable** | **Boolean** | Enables or disables CORS headers on requests. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CorsConfigureRequest.new(
  allowed_headers: null,
  allowed_origins: null,
  enable: null
)
```

