# OpenbaoClient::PkiRevokeIssuerResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ca_chain** | **Array&lt;String&gt;** | Certificate Authority Chain | [optional] |
| **certificate** | **String** | Certificate | [optional] |
| **crl_distribution_points** | **Array&lt;String&gt;** | Specifies the URL values for the CRL Distribution Points field | [optional] |
| **delta_crl_distribution_points** | **Array&lt;String&gt;** | Specifies the URL values for the Delta CRL Distribution Points field | [optional] |
| **issuer_id** | **String** | ID of the issuer | [optional] |
| **issuer_name** | **String** | Name of the issuer | [optional] |
| **issuing_certificates** | **Array&lt;String&gt;** | Specifies the URL values for the Issuing Certificate field | [optional] |
| **key_id** | **String** | ID of the Key | [optional] |
| **leaf_not_after_behavior** | **String** |  | [optional] |
| **manual_chain** | **Array&lt;String&gt;** | Manual Chain | [optional] |
| **ocsp_servers** | **Array&lt;String&gt;** | Specifies the URL values for the OCSP Servers field | [optional] |
| **revocation_signature_algorithm** | **String** | Which signature algorithm to use when building CRLs | [optional] |
| **revocation_time** | **Integer** | Time of revocation | [optional] |
| **revocation_time_rfc3339** | **Time** | RFC formatted time of revocation | [optional] |
| **revoked** | **Boolean** | Whether the issuer was revoked | [optional] |
| **usage** | **String** | Allowed usage | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRevokeIssuerResponse.new(
  ca_chain: null,
  certificate: null,
  crl_distribution_points: null,
  delta_crl_distribution_points: null,
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

