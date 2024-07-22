# OpenbaoClient::DatabaseWriteStaticRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **credential_config** | **Object** | The configuration for the given credential_type. | [optional] |
| **credential_type** | **String** | The type of credential to manage. Options include: &#39;password&#39;, &#39;rsa_private_key&#39;. Defaults to &#39;password&#39;. | [optional][default to &#39;password&#39;] |
| **db_name** | **String** | Name of the database this role acts on. | [optional] |
| **rotation_period** | **Integer** | Period for automatic credential rotation of the given username. Not valid unless used with \&quot;username\&quot;. | [optional] |
| **rotation_statements** | **Array&lt;String&gt;** | Specifies the database statements to be executed to rotate the accounts credentials. Not every plugin type will support this functionality. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |
| **username** | **String** | Name of the static user account for OpenBao to manage. Requires \&quot;rotation_period\&quot; to be specified | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::DatabaseWriteStaticRoleRequest.new(
  credential_config: null,
  credential_type: null,
  db_name: null,
  rotation_period: null,
  rotation_statements: null,
  username: null
)
```

