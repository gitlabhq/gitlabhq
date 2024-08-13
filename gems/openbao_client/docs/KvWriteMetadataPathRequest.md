# OpenbaoClient::KvWriteMetadataPathRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **after** | **String** | Optional entry to list begin listing after, not required to exist. Only used for listing. | [optional] |
| **cas_required** | **Boolean** | If true the key will require the cas parameter to be set on all write requests. If false, the backend’s configuration will be used. | [optional] |
| **custom_metadata** | **Object** | User-provided key-value pairs that are used to describe arbitrary and version-agnostic information about a secret. | [optional] |
| **delete_version_after** | **Integer** | The length of time before a version is deleted. If not set, the backend&#39;s configured delete_version_after is used. Cannot be greater than the backend&#39;s delete_version_after. A zero duration clears the current setting. A negative duration will cause an error. | [optional] |
| **limit** | **Integer** | Optional number of entries to return; defaults to all entries. Only used for listing. | [optional] |
| **max_versions** | **Integer** | The number of versions to keep. If not set, the backend’s configured max version is used. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KvWriteMetadataPathRequest.new(
  after: null,
  cas_required: null,
  custom_metadata: null,
  delete_version_after: null,
  limit: null,
  max_versions: null
)
```

