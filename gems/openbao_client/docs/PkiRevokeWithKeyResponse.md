# OpenbaoClient::PkiRevokeWithKeyResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **revocation_time** | **Integer** | Revocation Time | [optional] |
| **revocation_time_rfc3339** | **Time** | Revocation Time | [optional] |
| **state** | **String** | Revocation State | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRevokeWithKeyResponse.new(
  revocation_time: null,
  revocation_time_rfc3339: null,
  state: null
)
```

