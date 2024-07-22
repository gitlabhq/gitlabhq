# OpenbaoClient::PkiSetSignedIntermediateResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **existing_issuers** | **Array&lt;String&gt;** | Existing issuers specified as part of the import bundle of this request | [optional] |
| **existing_keys** | **Array&lt;String&gt;** | Existing keys specified as part of the import bundle of this request | [optional] |
| **imported_issuers** | **Array&lt;String&gt;** | Net-new issuers imported as a part of this request | [optional] |
| **imported_keys** | **Array&lt;String&gt;** | Net-new keys imported as a part of this request | [optional] |
| **mapping** | **Object** | A mapping of issuer_id to key_id for all issuers included in this request | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiSetSignedIntermediateResponse.new(
  existing_issuers: null,
  existing_keys: null,
  imported_issuers: null,
  imported_keys: null,
  mapping: null
)
```

