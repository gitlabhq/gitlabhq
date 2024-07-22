# OpenbaoClient::PkiRootSignSelfIssuedResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | Certificate | [optional] |
| **issuing_ca** | **String** | Issuing CA | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRootSignSelfIssuedResponse.new(
  certificate: null,
  issuing_ca: null
)
```

