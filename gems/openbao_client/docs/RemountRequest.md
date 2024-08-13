# OpenbaoClient::RemountRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **from** | **String** | The previous mount point. | [optional] |
| **to** | **String** | The new mount point. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RemountRequest.new(
  from: null,
  to: null
)
```

