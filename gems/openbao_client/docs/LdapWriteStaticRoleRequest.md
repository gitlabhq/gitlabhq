# OpenbaoClient::LdapWriteStaticRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **dn** | **String** | The distinguished name of the entry to manage. | [optional] |
| **rotation_period** | **Integer** | Period for automatic credential rotation of the given entry. | [optional] |
| **skip_import_rotation** | **Boolean** | Skip the initial pasword rotation on import (has no effect on updates) | [optional] |
| **username** | **String** | The username/logon name for the entry with which this role will be associated. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapWriteStaticRoleRequest.new(
  dn: null,
  rotation_period: null,
  skip_import_rotation: null,
  username: null
)
```

