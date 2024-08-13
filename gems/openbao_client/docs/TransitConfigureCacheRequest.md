# OpenbaoClient::TransitConfigureCacheRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **size** | **Integer** | Size of cache, use 0 for an unlimited cache size, defaults to 0 | [optional][default to 0] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitConfigureCacheRequest.new(
  size: null
)
```

