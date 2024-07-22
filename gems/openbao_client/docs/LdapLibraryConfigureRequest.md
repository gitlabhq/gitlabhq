# OpenbaoClient::LdapLibraryConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disable_check_in_enforcement** | **Boolean** | Disable the default behavior of requiring that check-ins are performed by the entity that checked them out. | [optional][default to false] |
| **max_ttl** | **Integer** | In seconds, the max amount of time a check-out&#39;s renewals should last. Defaults to 24 hours. | [optional][default to 86400] |
| **service_account_names** | **Array&lt;String&gt;** | The username/logon name for the service accounts with which this set will be associated. | [optional] |
| **ttl** | **Integer** | In seconds, the amount of time a check-out should last. Defaults to 24 hours. | [optional][default to 86400] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapLibraryConfigureRequest.new(
  disable_check_in_enforcement: null,
  max_ttl: null,
  service_account_names: null,
  ttl: null
)
```

