# OpenbaoClient::LeasesRevokeLeaseWithId2Request

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **lease_id** | **String** | The lease identifier to renew. This is included with a lease. | [optional] |
| **sync** | **Boolean** | Whether or not to perform the revocation synchronously | [optional][default to true] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesRevokeLeaseWithId2Request.new(
  lease_id: null,
  sync: null
)
```

