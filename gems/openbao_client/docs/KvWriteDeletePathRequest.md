# OpenbaoClient::KvWriteDeletePathRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **versions** | **Array&lt;Integer&gt;** | The versions to be archived. The versioned data will not be deleted, but it will no longer be returned in normal get requests. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteDeletePathRequest.new(
  versions: null
)
```

