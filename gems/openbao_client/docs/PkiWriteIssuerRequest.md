# OpenbaoClient::PkiWriteIssuerRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **crl_distribution_points** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the CRL distribution points attribute. See also RFC 5280 Section 4.2.1.13. | [optional] |
| **delta_crl_distribution_points** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the Delta CRL distribution points attribute. See also RFC 5280 Section 4.2.1.15 and Section 5.2.6. | [optional] |
| **enable_aia_url_templating** | **Boolean** | Whether or not to enabling templating of the above AIA fields. When templating is enabled the special values &#39;{{issuer_id}}&#39;, &#39;{{cluster_path}}&#39;, &#39;{{cluster_aia_path}}&#39; are available, but the addresses are not checked for URL validity until issuance time. Using &#39;{{cluster_path}}&#39; requires /config/cluster&#39;s &#39;path&#39; member to be set on all PR Secondary clusters and using &#39;{{cluster_aia_path}}&#39; requires /config/cluster&#39;s &#39;aia_path&#39; member to be set on all PR secondary clusters. | [optional][default to false] |
| **issuer_name** | **String** | Provide a name to the generated or existing issuer, the name must be unique across all issuers and not be the reserved value &#39;default&#39; | [optional] |
| **issuing_certificates** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the issuing certificate attribute. See also RFC 5280 Section 4.2.2.1. | [optional] |
| **leaf_not_after_behavior** | **String** | Behavior of leaf&#39;s NotAfter fields: \&quot;err\&quot; to error if the computed NotAfter date exceeds that of this issuer; \&quot;truncate\&quot; to silently truncate to that of this issuer; or \&quot;permit\&quot; to allow this issuance to succeed (with NotAfter exceeding that of an issuer). Note that not all values will results in certificates that can be validated through the entire validity period. It is suggested to use \&quot;truncate\&quot; for intermediate CAs and \&quot;permit\&quot; only for root CAs. | [optional][default to &#39;err&#39;] |
| **manual_chain** | **Array&lt;String&gt;** | Chain of issuer references to use to build this issuer&#39;s computed CAChain field, when non-empty. | [optional] |
| **ocsp_servers** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the OCSP servers attribute. See also RFC 5280 Section 4.2.2.1. | [optional] |
| **revocation_signature_algorithm** | **String** | Which x509.SignatureAlgorithm name to use for signing CRLs. This parameter allows differentiation between PKCS#1v1.5 and PSS keys and choice of signature hash algorithm. The default (empty string) value is for Go to select the signature algorithm. This can fail if the underlying key does not support the requested signature algorithm, which may not be known at modification time (such as with PKCS#11 managed RSA keys). | [optional][default to &#39;&#39;] |
| **usage** | **Array&lt;String&gt;** | Comma-separated list (or string slice) of usages for this issuer; valid values are \&quot;read-only\&quot;, \&quot;issuing-certificates\&quot;, \&quot;crl-signing\&quot;, and \&quot;ocsp-signing\&quot;. Multiple values may be specified. Read-only is implicit and always set. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiWriteIssuerRequest.new(
  crl_distribution_points: null,
  delta_crl_distribution_points: null,
  enable_aia_url_templating: null,
  issuer_name: null,
  issuing_certificates: null,
  leaf_not_after_behavior: null,
  manual_chain: null,
  ocsp_servers: null,
  revocation_signature_algorithm: null,
  usage: null
)
```

