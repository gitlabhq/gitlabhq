# OpenbaoClient::PkiIssuerSignSelfIssuedRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | PEM-format self-issued certificate to be signed. | [optional] |
| **require_matching_certificate_algorithms** | **Boolean** | If true, require the public key algorithm of the signer to match that of the self issued certificate. | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuerSignSelfIssuedRequest.new(
  certificate: null,
  require_matching_certificate_algorithms: null
)
```

