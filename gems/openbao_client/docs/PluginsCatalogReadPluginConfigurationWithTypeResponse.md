# OpenbaoClient::PluginsCatalogReadPluginConfigurationWithTypeResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **args** | **Array&lt;String&gt;** | The args passed to plugin command. | [optional] |
| **builtin** | **Boolean** |  | [optional] |
| **command** | **String** | The command used to start the plugin. The executable defined in this command must exist in OpenBao&#39;s plugin directory. | [optional] |
| **deprecation_status** | **String** |  | [optional] |
| **name** | **String** | The name of the plugin | [optional] |
| **sha256** | **String** | The SHA256 sum of the executable used in the command field. This should be HEX encoded. | [optional] |
| **version** | **String** | The semantic version of the plugin to use. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PluginsCatalogReadPluginConfigurationWithTypeResponse.new(
  args: null,
  builtin: null,
  command: null,
  deprecation_status: null,
  name: null,
  sha256: null,
  version: null
)
```

