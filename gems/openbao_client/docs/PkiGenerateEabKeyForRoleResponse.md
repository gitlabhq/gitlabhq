# OpenbaoClient::PkiGenerateEabKeyForRoleResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **acme_directory** | **String** | The ACME directory to which the key belongs | [optional] |
| **created_on** | **Time** | An RFC3339 formatted date time when the EAB token was created | [optional] |
| **id** | **String** | The EAB key identifier | [optional] |
| **key** | **String** | The EAB hmac key | [optional] |
| **key_type** | **String** | The EAB key type | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiGenerateEabKeyForRoleResponse.new(
  acme_directory: null,
  created_on: null,
  id: null,
  key: null,
  key_type: null
)
```

