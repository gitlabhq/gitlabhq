# OpenbaoClient::LdapLibraryCheckOutRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ttl** | **Integer** | The length of time before the check-out will expire, in seconds. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapLibraryCheckOutRequest.new(
  ttl: null
)
```

