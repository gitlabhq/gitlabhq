# OpenbaoClient::KvWriteUndeletePathRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **versions** | **Array&lt;Integer&gt;** | The versions to unarchive. The versions will be restored and their data will be returned on normal get requests. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteUndeletePathRequest.new(
  versions: null
)
```

