# OpenbaoClient::AuthReadConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **accessor** | **String** |  | [optional] |
| **config** | **Object** |  | [optional] |
| **deprecation_status** | **String** |  | [optional] |
| **description** | **String** |  | [optional] |
| **external_entropy_access** | **Boolean** |  | [optional] |
| **local** | **Boolean** |  | [optional] |
| **options** | **Object** |  | [optional] |
| **plugin_version** | **String** |  | [optional] |
| **running_plugin_version** | **String** |  | [optional] |
| **running_sha256** | **String** |  | [optional] |
| **seal_wrap** | **Boolean** |  | [optional] |
| **type** | **String** |  | [optional] |
| **uuid** | **String** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AuthReadConfigurationResponse.new(
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

