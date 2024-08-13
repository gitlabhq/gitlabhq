# OpenbaoClient::RateLimitQuotasConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enable_rate_limit_audit_logging** | **Boolean** | If set, starts audit logging of requests that get rejected due to rate limit quota rule violations. | [optional] |
| **enable_rate_limit_response_headers** | **Boolean** | If set, additional rate limit quota HTTP headers will be added to responses. | [optional] |
| **rate_limit_exempt_paths** | **Array&lt;String&gt;** | Specifies the list of exempt paths from all rate limit quotas. If empty no paths will be exempt. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RateLimitQuotasConfigureRequest.new(
  enable_rate_limit_audit_logging: null,
  enable_rate_limit_response_headers: null,
  rate_limit_exempt_paths: null
)
```

