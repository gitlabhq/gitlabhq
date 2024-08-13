# OpenbaoClient::RateLimitQuotasReadConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enable_rate_limit_audit_logging** | **Boolean** |  | [optional] |
| **enable_rate_limit_response_headers** | **Boolean** |  | [optional] |
| **rate_limit_exempt_paths** | **Array&lt;String&gt;** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RateLimitQuotasReadConfigurationResponse.new(
  enable_rate_limit_audit_logging: null,
  enable_rate_limit_response_headers: null,
  rate_limit_exempt_paths: null
)
```

