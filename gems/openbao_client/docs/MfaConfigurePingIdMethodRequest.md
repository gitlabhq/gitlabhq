# OpenbaoClient::MfaConfigurePingIdMethodRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_name** | **String** | The unique name identifier for this MFA method. | [optional] |
| **settings_file_base64** | **String** | The settings file provided by Ping, Base64-encoded. This must be a settings file suitable for third-party clients, not the PingID SDK or PingFederate. | [optional] |
| **username_format** | **String** | A template string for mapping Identity names to MFA method names. Values to subtitute should be placed in {{}}. For example, \&quot;{{alias.name}}@example.com\&quot;. Currently-supported mappings: alias.name: The name returned by the mount configured via the mount_accessor parameter If blank, the Alias&#39;s name field will be used as-is. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaConfigurePingIdMethodRequest.new(
  method_name: null,
  settings_file_base64: null,
  username_format: null
)
```

