# OpenbaoClient::AppRoleReadPeriodResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **period** | **Integer** | Use \&quot;token_period\&quot; instead. If this and \&quot;token_period\&quot; are both specified, only \&quot;token_period\&quot; will be used. | [optional] |
| **token_period** | **Integer** | If set, tokens created via this role will have no max lifetime; instead, their renewal period will be fixed to this value. This takes an integer number of seconds, or a string duration (e.g. \&quot;24h\&quot;). | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleReadPeriodResponse.new(
  period: null,
  token_period: null
)
```

