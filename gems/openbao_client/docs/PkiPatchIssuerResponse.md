# OpenbaoClient::PkiPatchIssuerResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **Array&lt;String&gt;** | CA Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **crl_distribution_points** | **Array&lt;String&gt;** | CRL Distribution Points | [optional] |
| **delta_crl_distribution_points** | **Array&lt;String&gt;** | Delta CRL Distribution Points | [optional] |
| **enable_aia_url_templating** | **Boolean** | Whether or not templating is enabled for AIA fields | [optional] |
| **issuer_id** | **String** | Issuer Id | [optional] |
| **issuer_name** | **String** | Issuer Name | [optional] |
| **issuing_certificates** | **Array&lt;String&gt;** | Issuing Certificates | [optional] |
| **key_id** | **String** | Key Id | [optional] |
| **leaf_not_after_behavior** | **String** | Leaf Not After Behavior | [optional] |
| **manual_chain** | **Array&lt;String&gt;** | Manual Chain | [optional] |
| **ocsp_servers** | **Array&lt;String&gt;** | OCSP Servers | [optional] |
| **revocation_signature_algorithm** | **String** | Revocation Signature Alogrithm | [optional] |
| **revocation_time** | **Integer** |  | [optional] |
| **revocation_time_rfc3339** | **String** |  | [optional] |
| **revoked** | **Boolean** | Revoked | [optional] |
| **usage** | **String** | Usage | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiPatchIssuerResponse.new(
  ca_chain: null,
  certificate: null,
  crl_distribution_points: null,
  delta_crl_distribution_points: null,
  enable_aia_url_templating: null,
  issuer_id: null,
  issuer_name: null,
  issuing_certificates: null,
  key_id: null,
  leaf_not_after_behavior: null,
  manual_chain: null,
  ocsp_servers: null,
  revocation_signature_algorithm: null,
  revocation_time: null,
  revocation_time_rfc3339: null,
  revoked: null,
  usage: null
)
```

