# OpenbaoClient::DatabaseConfigureConnectionRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_roles** | **Array&lt;String&gt;** | Comma separated string or array of the role names allowed to get creds from this database connection. If empty no roles are allowed. If \&quot;*\&quot; all roles are allowed. | [optional] |
| **password_policy** | **String** | Password policy to use when generating passwords. | [optional] |
| **plugin_name** | **String** | The name of a builtin or previously registered plugin known to OpenBao. This endpoint will create an instance of that plugin type. | [optional] |
| **plugin_version** | **String** | The version of the plugin to use. | [optional] |
| **root_rotation_statements** | **Array&lt;String&gt;** | Specifies the database statements to be executed to rotate the root user&#39;s credentials. See the plugin&#39;s API page for more information on support and formatting for this parameter. | [optional] |
| **verify_connection** | **Boolean** | If true, the connection details are verified by actually connecting to the database. Defaults to true. | [optional][default to true] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::DatabaseConfigureConnectionRequest.new(
  allowed_roles: null,
  password_policy: null,
  plugin_name: null,
  plugin_version: null,
  root_rotation_statements: null,
  verify_connection: null
)
```

