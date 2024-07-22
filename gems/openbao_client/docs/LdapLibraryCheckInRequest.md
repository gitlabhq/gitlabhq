# OpenbaoClient::LdapLibraryCheckInRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **service_account_names** | **Array&lt;String&gt;** | The username/logon name for the service accounts to check in. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapLibraryCheckInRequest.new(
  service_account_names: null
)
```

