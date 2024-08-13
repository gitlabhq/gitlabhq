# OpenbaoClient::KerberosWriteGroupRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policies** | **Array&lt;String&gt;** | Comma-separated list of policies associated to the group. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KerberosWriteGroupRequest.new(
  policies: null
)
```

