# OpenbaoClient::MfaConfigureDuoMethodRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **api_hostname** | **String** | API host name for Duo. | [optional] |
| **integration_key** | **String** | Integration key for Duo. | [optional] |
| **method_name** | **String** | The unique name identifier for this MFA method. | [optional] |
| **push_info** | **String** | Push information for Duo. | [optional] |
| **secret_key** | **String** | Secret key for Duo. | [optional] |
| **use_passcode** | **Boolean** | If true, the user is reminded to use the passcode upon MFA validation. This option does not enforce using the passcode. Defaults to false. | [optional] |
| **username_format** | **String** | A template string for mapping Identity names to MFA method names. Values to subtitute should be placed in {{}}. For example, \&quot;{{alias.name}}@example.com\&quot;. Currently-supported mappings: alias.name: The name returned by the mount configured via the mount_accessor parameter If blank, the Alias&#39;s name field will be used as-is. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaConfigureDuoMethodRequest.new(
  api_hostname: null,
  integration_key: null,
  method_name: null,
  push_info: null,
  secret_key: null,
  use_passcode: null,
  username_format: null
)
```

