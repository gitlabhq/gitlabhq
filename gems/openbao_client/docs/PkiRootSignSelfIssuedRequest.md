# OpenbaoClient::PkiRootSignSelfIssuedRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **certificate** | **String** | PEM-format self-issued certificate to be signed. | [optional] |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [optional][default to &#39;default&#39;] |
| **require_matching_certificate_algorithms** | **Boolean** | If true, require the public key algorithm of the signer to match that of the self issued certificate. | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRootSignSelfIssuedRequest.new(
  certificate: null,
  issuer_ref: null,
  require_matching_certificate_algorithms: null
)
```

