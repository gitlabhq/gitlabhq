# OpenbaoClient::LdapWriteUserRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **groups** | **Array&lt;String&gt;** | Comma-separated list of additional groups associated with the user. | [optional] |
| **policies** | **Array&lt;String&gt;** | Comma-separated list of policies associated with the user. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapWriteUserRequest.new(
  groups: null,
  policies: null
)
```

