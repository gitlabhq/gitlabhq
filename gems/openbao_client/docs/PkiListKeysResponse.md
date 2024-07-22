# OpenbaoClient::PkiListKeysResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_info** | **Object** | Key info with issuer name | [optional] |
| **keys** | **Array&lt;String&gt;** | A list of keys | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiListKeysResponse.new(
  key_info: null,
  keys: null
)
```

