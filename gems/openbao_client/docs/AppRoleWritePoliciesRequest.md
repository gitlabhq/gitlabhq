# OpenbaoClient::AppRoleWritePoliciesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policies** | **Array&lt;String&gt;** | Use \&quot;token_policies\&quot; instead. If this and \&quot;token_policies\&quot; are both specified, only \&quot;token_policies\&quot; will be used. | [optional] |
| **token_policies** | **Array&lt;String&gt;** | Comma-separated list of policies | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWritePoliciesRequest.new(
  policies: null,
  token_policies: null
)
```

