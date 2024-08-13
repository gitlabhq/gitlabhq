# OpenbaoClient::RawWriteRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **after** | **String** | Optional entry to list begin listing after, not required to exist. Only used in list operations. | [optional] |
| **compressed** | **Boolean** |  | [optional] |
| **compression_type** | **String** |  | [optional] |
| **encoding** | **String** |  | [optional] |
| **limit** | **Integer** | Optional number of entries to return; defaults to all entries. Only used in list operations. | [optional] |
| **path** | **String** |  | [optional] |
| **value** | **String** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RawWriteRequest.new(
  after: null,
  compressed: null,
  compression_type: null,
  encoding: null,
  limit: null,
  path: null,
  value: null
)
```

