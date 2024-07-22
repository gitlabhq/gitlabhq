# OpenbaoClient::PkiSetSignedIntermediateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | PEM-format certificate. This must be a CA certificate with a public key matching the previously-generated key from the generation endpoint. Additional parent CAs may be optionally appended to the bundle. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiSetSignedIntermediateRequest.new(
  certificate: null
)
```

