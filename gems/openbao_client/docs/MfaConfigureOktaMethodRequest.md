# OpenbaoClient::MfaConfigureOktaMethodRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **api_token** | **String** | Okta API key. | [optional] |
| **base_url** | **String** | The base domain to use for the Okta API. When not specified in the configuration, \&quot;okta.com\&quot; is used. | [optional] |
| **method_name** | **String** | The unique name identifier for this MFA method. | [optional] |
| **org_name** | **String** | Name of the organization to be used in the Okta API. | [optional] |
| **primary_email** | **Boolean** | If true, the username will only match the primary email for the account. Defaults to false. | [optional] |
| **production** | **Boolean** | (DEPRECATED) Use base_url instead. | [optional] |
| **username_format** | **String** | A template string for mapping Identity names to MFA method names. Values to substitute should be placed in {{}}. For example, \&quot;{{entity.name}}@example.com\&quot;. If blank, the Entity&#39;s name field will be used as-is. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaConfigureOktaMethodRequest.new(
  api_token: null,
  base_url: null,
  method_name: null,
  org_name: null,
  primary_email: null,
  production: null,
  username_format: null
)
```

