# OpenbaoClient::LdapWriteDynamicRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **creation_ldif** | **String** | LDIF string used to create new entities within the LDAP system. This LDIF can be templated. |  |
| **default_ttl** | **Integer** | Default TTL for dynamic credentials | [optional] |
| **deletion_ldif** | **String** | LDIF string used to delete entities created within the LDAP system. This LDIF can be templated. |  |
| **max_ttl** | **Integer** | Max TTL a dynamic credential can be extended to | [optional] |
| **rollback_ldif** | **String** | LDIF string used to rollback changes in the event of a failure to create credentials. This LDIF can be templated. | [optional] |
| **username_template** | **String** | The template used to create a username | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LdapWriteDynamicRoleRequest.new(
  creation_ldif: null,
  default_ttl: null,
  deletion_ldif: null,
  max_ttl: null,
  rollback_ldif: null,
  username_template: null
)
```

