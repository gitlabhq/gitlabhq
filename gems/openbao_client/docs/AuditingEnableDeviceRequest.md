# OpenbaoClient::AuditingEnableDeviceRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **description** | **String** | User-friendly description for this audit backend. | [optional] |
| **local** | **Boolean** | Mark the mount as a local mount, which is not replicated and is unaffected by replication. | [optional][default to false] |
| **options** | **Object** | Configuration options for the audit backend. | [optional] |
| **type** | **String** | The type of the backend. Example: \&quot;mysql\&quot; | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AuditingEnableDeviceRequest.new(
  description: null,
  local: null,
  options: null,
  type: null
)
```

