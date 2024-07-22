# OpenbaoClient::DatabaseWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **creation_statements** | **Array&lt;String&gt;** | Specifies the database statements executed to create and configure a user. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |
| **credential_config** | **Object** | The configuration for the given credential_type. | [optional] |
| **credential_type** | **String** | The type of credential to manage. Options include: &#39;password&#39;, &#39;rsa_private_key&#39;. Defaults to &#39;password&#39;. | [optional][default to &#39;password&#39;] |
| **db_name** | **String** | Name of the database this role acts on. | [optional] |
| **default_ttl** | **Integer** | Default ttl for role. | [optional] |
| **max_ttl** | **Integer** | Maximum time a credential is valid for | [optional] |
| **renew_statements** | **Array&lt;String&gt;** | Specifies the database statements to be executed to renew a user. Not every plugin type will support this functionality. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |
| **revocation_statements** | **Array&lt;String&gt;** | Specifies the database statements to be executed to revoke a user. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |
| **rollback_statements** | **Array&lt;String&gt;** | Specifies the database statements to be executed rollback a create operation in the event of an error. Not every plugin type will support this functionality. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::DatabaseWriteRoleRequest.new(
  creation_statements: null,
  credential_config: null,
  credential_type: null,
  db_name: null,
  default_ttl: null,
  max_ttl: null,
  renew_statements: null,
  revocation_statements: null,
  rollback_statements: null
)
```

