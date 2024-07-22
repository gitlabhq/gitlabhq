# OpenbaoClient::KvWriteConfigRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cas_required** | **Boolean** | If true, the backend will require the cas parameter to be set for each write | [optional] |
| **delete_version_after** | **Integer** | If set, the length of time before a version is deleted. A negative duration disables the use of delete_version_after on all keys. A zero duration clears the current setting. Accepts a Go duration format string. | [optional] |
| **max_versions** | **Integer** | The number of versions to keep for each key. Defaults to 10 | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteConfigRequest.new(
  cas_required: null,
  delete_version_after: null,
  max_versions: null
)
```

