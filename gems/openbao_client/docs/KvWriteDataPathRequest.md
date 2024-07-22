# OpenbaoClient::KvWriteDataPathRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **data** | **Object** | The contents of the data map will be stored and returned on read. | [optional] |
| **options** | **Object** | Options for writing a KV entry. Set the \&quot;cas\&quot; value to use a Check-And-Set operation. If not set the write will be allowed. If set to 0 a write will only be allowed if the key doesn’t exist. If the index is non-zero the write will only be allowed if the key’s current version matches the version specified in the cas parameter. | [optional] |
| **version** | **Integer** | If provided during a read, the value at the version number will be returned | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteDataPathRequest.new(
  data: null,
  options: null,
  version: null
)
```

