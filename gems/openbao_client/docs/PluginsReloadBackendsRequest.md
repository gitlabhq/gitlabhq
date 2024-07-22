# OpenbaoClient::PluginsReloadBackendsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mounts** | **Array&lt;String&gt;** | The mount paths of the plugin backends to reload. | [optional] |
| **plugin** | **String** | The name of the plugin to reload, as registered in the plugin catalog. | [optional] |
| **scope** | **String** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PluginsReloadBackendsRequest.new(
  mounts: null,
  plugin: null,
  scope: null
)
```

