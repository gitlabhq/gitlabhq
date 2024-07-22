# OpenbaoClient::PkiImportKeyResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_id** | **String** | ID assigned to this key. | [optional] |
| **key_name** | **String** | Name assigned to this key. | [optional] |
| **key_type** | **String** | The type of key to use; defaults to RSA. \&quot;rsa\&quot; \&quot;ec\&quot; and \&quot;ed25519\&quot; are the only valid values. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiImportKeyResponse.new(
  key_id: null,
  key_name: null,
  key_type: null
)
```

