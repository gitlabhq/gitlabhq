# OpenbaoClient::MfaWriteLoginEnforcementRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_method_accessors** | **Array&lt;String&gt;** | Array of auth mount accessor IDs | [optional] |
| **auth_method_types** | **Array&lt;String&gt;** | Array of auth mount types | [optional] |
| **identity_entity_ids** | **Array&lt;String&gt;** | Array of identity entity IDs | [optional] |
| **identity_group_ids** | **Array&lt;String&gt;** | Array of identity group IDs | [optional] |
| **mfa_method_ids** | **Array&lt;String&gt;** | Array of Method IDs that determine what methods will be enforced |  |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MfaWriteLoginEnforcementRequest.new(
  auth_method_accessors: null,
  auth_method_types: null,
  identity_entity_ids: null,
  identity_group_ids: null,
  mfa_method_ids: null
)
```

