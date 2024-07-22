# OpenbaoClient::PluginsCatalogRegisterPluginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **args** | **Array&lt;String&gt;** | The args passed to plugin command. | [optional] |
| **command** | **String** | The command used to start the plugin. The executable defined in this command must exist in OpenBao&#39;s plugin directory. | [optional] |
| **env** | **Array&lt;String&gt;** | The environment variables passed to plugin command. Each entry is of the form \&quot;key&#x3D;value\&quot;. | [optional] |
| **sha256** | **String** | The SHA256 sum of the executable used in the command field. This should be HEX encoded. | [optional] |
| **type** | **String** | The type of the plugin, may be auth, secret, or database | [optional] |
| **version** | **String** | The semantic version of the plugin to use. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PluginsCatalogRegisterPluginRequest.new(
  args: null,
  command: null,
  env: null,
  sha256: null,
  type: null,
  version: null
)
```

