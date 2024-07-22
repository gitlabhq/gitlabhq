# OpenbaoClient::PkiConfigureKeysRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **default** | **String** | Reference (name or identifier) of the default key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureKeysRequest.new(
  default: null
)
```

