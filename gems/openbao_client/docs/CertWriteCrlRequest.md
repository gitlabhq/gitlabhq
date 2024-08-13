# OpenbaoClient::CertWriteCrlRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **crl** | **String** | The public CRL that should be trusted to attest to certificates&#39; validity statuses. May be DER or PEM encoded. Note: the expiration time is ignored; if the CRL is no longer valid, delete it using the same name as specified here. | [optional] |
| **url** | **String** | The URL of a CRL distribution point. Only one of &#39;crl&#39; or &#39;url&#39; parameters should be specified. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CertWriteCrlRequest.new(
  crl: null,
  url: null
)
```

