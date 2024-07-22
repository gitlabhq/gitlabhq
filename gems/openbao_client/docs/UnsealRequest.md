# OpenbaoClient::UnsealRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** | Specifies a single unseal key share. This is required unless reset is true. | [optional] |
| **reset** | **Boolean** | Specifies if previously-provided unseal keys are discarded and the unseal process is reset. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::UnsealRequest.new(
  key: null,
  reset: null
)
```

