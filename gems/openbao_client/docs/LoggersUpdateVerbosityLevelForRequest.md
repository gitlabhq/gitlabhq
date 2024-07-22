# OpenbaoClient::LoggersUpdateVerbosityLevelForRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **level** | **String** | Log verbosity level. Supported values (in order of detail) are \&quot;trace\&quot;, \&quot;debug\&quot;, \&quot;info\&quot;, \&quot;warn\&quot;, and \&quot;error\&quot;. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LoggersUpdateVerbosityLevelForRequest.new(
  level: null
)
```

