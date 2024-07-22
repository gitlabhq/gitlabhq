# OpenbaoClient::TransitConfigureKeysRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disable_upsert** | **Boolean** | Whether to allow automatic upserting (creation) of keys on the encrypt endpoint. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitConfigureKeysRequest.new(
  disable_upsert: null
)
```

