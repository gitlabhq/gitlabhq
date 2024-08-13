# OpenbaoClient::PkiIssuerSignWithRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alt_names** | **String** | The requested Subject Alternative Names, if any, in a comma-delimited list. If email protection is enabled for the role, this may contain email addresses. | [optional] |
| **common_name** | **String** | The requested common name; if you want more than one, specify the alternative names in the alt_names map. If email protection is enabled in the role, this may be an email address. | [optional] |
| **csr** | **String** | PEM-format CSR to be signed. | [optional][default to &#39;&#39;] |
| **exclude_cn_from_sans** | **Boolean** | If true, the Common Name will not be included in DNS or Email Subject Alternate Names. Defaults to false (CN is included). | [optional][default to false] |
| **format** | **String** | Format for returned data. Can be \&quot;pem\&quot;, \&quot;der\&quot;, or \&quot;pem_bundle\&quot;. If \&quot;pem_bundle\&quot;, any private key and issuing cert will be appended to the certificate pem. If \&quot;der\&quot;, the value will be base64 encoded. Defaults to \&quot;pem\&quot;. | [optional][default to &#39;pem&#39;] |
| **ip_sans** | **Array&lt;String&gt;** | The requested IP SANs, if any, in a comma-delimited list | [optional] |
| **not_after** | **String** | Set the not after field of the certificate with specified date value. The value format should be given in UTC format YYYY-MM-ddTHH:MM:SSZ | [optional] |
| **other_sans** | **Array&lt;String&gt;** | Requested other SANs, in an array with the format &lt;oid&gt;;UTF8:&lt;utf8 string value&gt; for each entry. | [optional] |
| **private_key_format** | **String** | Format for the returned private key. Generally the default will be controlled by the \&quot;format\&quot; parameter as either base64-encoded DER or PEM-encoded DER. However, this can be set to \&quot;pkcs8\&quot; to have the returned private key contain base64-encoded pkcs8 or PEM-encoded pkcs8 instead. Defaults to \&quot;der\&quot;. | [optional][default to &#39;der&#39;] |
| **remove_roots_from_chain** | **Boolean** | Whether or not to remove self-signed CA certificates in the output of the ca_chain field. | [optional][default to false] |
| **serial_number** | **String** | The Subject&#39;s requested serial number, if any. See RFC 4519 Section 2.31 &#39;serialNumber&#39; for a description of this field. If you want more than one, specify alternative names in the alt_names map using OID 2.5.4.5. This has no impact on the final certificate&#39;s Serial Number field. | [optional] |
| **ttl** | **Integer** | The requested Time To Live for the certificate; sets the expiration date. If not specified the role default, backend default, or system default TTL is used, in that order. Cannot be larger than the role max TTL. | [optional] |
| **uri_sans** | **Array&lt;String&gt;** | The requested URI SANs, if any, in a comma-delimited list. | [optional] |
| **user_ids** | **Array&lt;String&gt;** | The requested user_ids value to place in the subject, if any, in a comma-delimited list. Restricted by allowed_user_ids. Any values are added with OID 0.9.2342.19200300.100.1.1. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuerSignWithRoleRequest.new(
  alt_names: null,
  common_name: null,
  csr: null,
  exclude_cn_from_sans: null,
  format: null,
  ip_sans: null,
  not_after: null,
  other_sans: null,
  private_key_format: null,
  remove_roots_from_chain: null,
  serial_number: null,
  ttl: null,
  uri_sans: null,
  user_ids: null
)
```

