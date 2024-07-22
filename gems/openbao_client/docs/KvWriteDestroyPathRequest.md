# OpenbaoClient::KvWriteDestroyPathRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **versions** | **Array&lt;Integer&gt;** | The versions to destroy. Their data will be permanently deleted. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteDestroyPathRequest.new(
  versions: null
)
```

