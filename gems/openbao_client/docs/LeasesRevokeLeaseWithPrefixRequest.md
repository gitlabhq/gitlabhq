# OpenbaoClient::LeasesRevokeLeaseWithPrefixRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sync** | **Boolean** | Whether or not to perform the revocation synchronously | [optional][default to true] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeasesRevokeLeaseWithPrefixRequest.new(
  sync: null
)
```

