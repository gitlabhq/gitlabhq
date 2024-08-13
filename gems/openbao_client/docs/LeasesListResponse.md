# OpenbaoClient::LeasesListResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **counts** | **Integer** | Number of matching leases per mount | [optional] |
| **lease_count** | **Integer** | Number of matching leases | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesListResponse.new(
  counts: null,
  lease_count: null
)
```

