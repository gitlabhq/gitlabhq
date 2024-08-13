# OpenbaoClient::KerberosConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **add_group_aliases** | **Boolean** | If set to true, returns any groups found in LDAP as a group alias. | [optional] |
| **keytab** | **String** | Base64 encoded keytab | [optional] |
| **remove_instance_name** | **Boolean** | Remove instance/FQDN from keytab principal names. | [optional] |
| **service_account** | **String** | Service Account | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KerberosConfigureRequest.new(
  add_group_aliases: null,
  keytab: null,
  remove_instance_name: null,
  service_account: null
)
```

