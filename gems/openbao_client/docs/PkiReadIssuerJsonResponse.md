# OpenbaoClient::PkiReadIssuerJsonResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **Array&lt;String&gt;** | CA Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **issuer_id** | **String** | Issuer Id | [optional] |
| **issuer_name** | **String** | Issuer Name | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiReadIssuerJsonResponse.new(
  ca_chain: null,
  certificate: null,
  issuer_id: null,
  issuer_name: null
)
```

