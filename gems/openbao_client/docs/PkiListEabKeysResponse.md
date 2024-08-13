# OpenbaoClient::PkiListEabKeysResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_info** | **Object** | EAB details keyed by the eab key id | [optional] |
| **keys** | **Array&lt;String&gt;** | A list of unused eab keys | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiListEabKeysResponse.new(
  key_info: null,
  keys: null
)
```

