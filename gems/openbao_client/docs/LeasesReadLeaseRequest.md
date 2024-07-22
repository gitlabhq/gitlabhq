# OpenbaoClient::LeasesReadLeaseRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **lease_id** | **String** | The lease identifier to renew. This is included with a lease. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesReadLeaseRequest.new(
  lease_id: null
)
```

