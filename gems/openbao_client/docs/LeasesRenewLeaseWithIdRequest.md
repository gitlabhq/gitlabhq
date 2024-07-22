# OpenbaoClient::LeasesRenewLeaseWithIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **increment** | **Integer** | The desired increment in seconds to the lease | [optional] |
| **lease_id** | **String** | The lease identifier to renew. This is included with a lease. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesRenewLeaseWithIdRequest.new(
  increment: null,
  lease_id: null
)
```

