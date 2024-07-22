# OpenbaoClient::PkiReadUrlsConfigurationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **crl_distribution_points** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the CRL distribution points attribute. See also RFC 5280 Section 4.2.1.13. | [optional] |
| **delta_crl_distribution_points** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the Delta CRL distribution points attribute. See also RFC 5280 Section 4.2.1.15 and Section 5.2.6. | [optional] |
| **enable_templating** | **Boolean** | Whether or not to enable templating of the above AIA fields. When templating is enabled the special values &#39;{{issuer_id}}&#39; and &#39;{{cluster_path}}&#39; are available, but the addresses are not checked for URI validity until issuance time. This requires /config/cluster&#39;s path to be set on all PR Secondary clusters. | [optional] |
| **issuing_certificates** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the issuing certificate attribute. See also RFC 5280 Section 4.2.2.1. | [optional] |
| **ocsp_servers** | **Array&lt;String&gt;** | Comma-separated list of URLs to be used for the OCSP servers attribute. See also RFC 5280 Section 4.2.2.1. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiReadUrlsConfigurationResponse.new(
  crl_distribution_points: null,
  delta_crl_distribution_points: null,
  enable_templating: null,
  issuing_certificates: null,
  ocsp_servers: null
)
```

