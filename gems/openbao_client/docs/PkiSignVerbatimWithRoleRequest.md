# OpenbaoClient::PkiSignVerbatimWithRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alt_names** | **String** | The requested Subject Alternative Names, if any, in a comma-delimited list. If email protection is enabled for the role, this may contain email addresses. | [optional] |
| **basic_constraints_valid_for_non_ca** | **Boolean** | Mark Basic Constraints valid when issuing non-CA certificates. | [optional][default to false] |
| **common_name** | **String** | The requested common name; if you want more than one, specify the alternative names in the alt_names map. If email protection is enabled in the role, this may be an email address. | [optional] |
| **csr** | **String** | PEM-format CSR to be signed. Values will be taken verbatim from the CSR, except for basic constraints. | [optional][default to &#39;&#39;] |
| **exclude_cn_from_sans** | **Boolean** | If true, the Common Name will not be included in DNS or Email Subject Alternate Names. Defaults to false (CN is included). | [optional][default to false] |
| **ext_key_usage** | **Array&lt;String&gt;** | A comma-separated string or list of extended key usages. Valid values can be found at https://golang.org/pkg/crypto/x509/#ExtKeyUsage -- simply drop the \&quot;ExtKeyUsage\&quot; part of the name. To remove all key usages from being set, set this value to an empty list. | [optional] |
| **ext_key_usage_oids** | **Array&lt;String&gt;** | A comma-separated string or list of extended key usage oids. | [optional] |
| **format** | **String** | Format for returned data. Can be \&quot;pem\&quot;, \&quot;der\&quot;, or \&quot;pem_bundle\&quot;. If \&quot;pem_bundle\&quot;, any private key and issuing cert will be appended to the certificate pem. If \&quot;der\&quot;, the value will be base64 encoded. Defaults to \&quot;pem\&quot;. | [optional][default to &#39;pem&#39;] |
| **ip_sans** | **Array&lt;String&gt;** | The requested IP SANs, if any, in a comma-delimited list | [optional] |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [optional][default to &#39;default&#39;] |
| **key_usage** | **Array&lt;String&gt;** | A comma-separated string or list of key usages (not extended key usages). Valid values can be found at https://golang.org/pkg/crypto/x509/#KeyUsage -- simply drop the \&quot;KeyUsage\&quot; part of the name. To remove all key usages from being set, set this value to an empty list. | [optional] |
| **not_after** | **String** | Set the not after field of the certificate with specified date value. The value format should be given in UTC format YYYY-MM-ddTHH:MM:SSZ | [optional] |
| **other_sans** | **Array&lt;String&gt;** | Requested other SANs, in an array with the format &lt;oid&gt;;UTF8:&lt;utf8 string value&gt; for each entry. | [optional] |
| **private_key_format** | **String** | Format for the returned private key. Generally the default will be controlled by the \&quot;format\&quot; parameter as either base64-encoded DER or PEM-encoded DER. However, this can be set to \&quot;pkcs8\&quot; to have the returned private key contain base64-encoded pkcs8 or PEM-encoded pkcs8 instead. Defaults to \&quot;der\&quot;. | [optional][default to &#39;der&#39;] |
| **remove_roots_from_chain** | **Boolean** | Whether or not to remove self-signed CA certificates in the output of the ca_chain field. | [optional][default to false] |
| **serial_number** | **String** | The Subject&#39;s requested serial number, if any. See RFC 4519 Section 2.31 &#39;serialNumber&#39; for a description of this field. If you want more than one, specify alternative names in the alt_names map using OID 2.5.4.5. This has no impact on the final certificate&#39;s Serial Number field. | [optional] |
| **signature_bits** | **Integer** | The number of bits to use in the signature algorithm; accepts 256 for SHA-2-256, 384 for SHA-2-384, and 512 for SHA-2-512. Defaults to 0 to automatically detect based on key length (SHA-2-256 for RSA keys, and matching the curve size for NIST P-Curves). | [optional][default to 0] |
| **ttl** | **Integer** | The requested Time To Live for the certificate; sets the expiration date. If not specified the role default, backend default, or system default TTL is used, in that order. Cannot be larger than the role max TTL. | [optional] |
| **uri_sans** | **Array&lt;String&gt;** | The requested URI SANs, if any, in a comma-delimited list. | [optional] |
| **use_pss** | **Boolean** | Whether or not to use PSS signatures when using a RSA key-type issuer. Defaults to false. | [optional][default to false] |
| **user_ids** | **Array&lt;String&gt;** | The requested user_ids value to place in the subject, if any, in a comma-delimited list. Restricted by allowed_user_ids. Any values are added with OID 0.9.2342.19200300.100.1.1. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiSignVerbatimWithRoleRequest.new(
  alt_names: null,
  basic_constraints_valid_for_non_ca: null,
  common_name: null,
  csr: null,
  exclude_cn_from_sans: null,
  ext_key_usage: null,
  ext_key_usage_oids: null,
  format: null,
  ip_sans: null,
  issuer_ref: null,
  key_usage: null,
  not_after: null,
  other_sans: null,
  private_key_format: null,
  remove_roots_from_chain: null,
  serial_number: null,
  signature_bits: null,
  ttl: null,
  uri_sans: null,
  use_pss: null,
  user_ids: null
)
```

