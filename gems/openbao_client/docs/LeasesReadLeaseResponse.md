# OpenbaoClient::LeasesReadLeaseResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **expire_time** | **Time** | Optional lease expiry time | [optional] |
| **id** | **String** | Lease id | [optional] |
| **issue_time** | **Time** | Timestamp for the lease&#39;s issue time | [optional] |
| **last_renewal** | **Time** | Optional Timestamp of the last time the lease was renewed | [optional] |
| **renewable** | **Boolean** | True if the lease is able to be renewed | [optional] |
| **ttl** | **Integer** | Time to Live set for the lease, returns 0 if unset | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesReadLeaseResponse.new(
  expire_time: null,
  id: null,
  issue_time: null,
  last_renewal: null,
  renewable: null,
  ttl: null
)
```

