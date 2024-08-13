# OpenbaoClient::AuthEnableMethodRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **config** | **Object** | Configuration for this mount, such as plugin_name. | [optional] |
| **description** | **String** | User-friendly description for this credential backend. | [optional] |
| **external_entropy_access** | **Boolean** | Whether to give the mount access to OpenBao&#39;s external entropy. | [optional][default to false] |
| **local** | **Boolean** | Mark the mount as a local mount, which is not replicated and is unaffected by replication. | [optional][default to false] |
| **options** | **Object** | The options to pass into the backend. Should be a json object with string keys and values. | [optional] |
| **plugin_name** | **String** | Name of the auth plugin to use based from the name in the plugin catalog. | [optional] |
| **plugin_version** | **String** | The semantic version of the plugin to use. | [optional] |
| **seal_wrap** | **Boolean** | Whether to turn on seal wrapping for the mount. | [optional][default to false] |
| **type** | **String** | The type of the backend. Example: \&quot;userpass\&quot; | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AuthEnableMethodRequest.new(
  config: null,
  description: null,
  external_entropy_access: null,
  local: null,
  options: null,
  plugin_name: null,
  plugin_version: null,
  seal_wrap: null,
  type: null
)
```

