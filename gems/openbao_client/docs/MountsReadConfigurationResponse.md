# OpenbaoClient::MountsReadConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **accessor** | **String** |  | [optional] |
| **config** | **Object** | Configuration for this mount, such as default_lease_ttl and max_lease_ttl. | [optional] |
| **deprecation_status** | **String** |  | [optional] |
| **description** | **String** | User-friendly description for this mount. | [optional] |
| **external_entropy_access** | **Boolean** |  | [optional] |
| **local** | **Boolean** | Mark the mount as a local mount, which is not replicated and is unaffected by replication. | [optional][default to false] |
| **options** | **Object** | The options to pass into the backend. Should be a json object with string keys and values. | [optional] |
| **plugin_version** | **String** | The semantic version of the plugin to use. | [optional] |
| **running_plugin_version** | **String** |  | [optional] |
| **running_sha256** | **String** |  | [optional] |
| **seal_wrap** | **Boolean** | Whether to turn on seal wrapping for the mount. | [optional][default to false] |
| **type** | **String** | The type of the backend. Example: \&quot;passthrough\&quot; | [optional] |
| **uuid** | **String** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MountsReadConfigurationResponse.new(
  accessor: null,
  config: null,
  deprecation_status: null,
  description: null,
  external_entropy_access: null,
  local: null,
  options: null,
  plugin_version: null,
  running_plugin_version: null,
  running_sha256: null,
  seal_wrap: null,
  type: null,
  uuid: null
)
```

