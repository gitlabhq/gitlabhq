# OpenbaoClient::PkiRotateRootRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alt_names** | **String** | The requested Subject Alternative Names, if any, in a comma-delimited list. May contain both DNS names and email addresses. | [optional] |
| **common_name** | **String** | The requested common name; if you want more than one, specify the alternative names in the alt_names map. If not specified when signing, the common name will be taken from the CSR; other names must still be specified in alt_names or ip_sans. | [optional] |
| **country** | **Array&lt;String&gt;** | If set, Country will be set to this value. | [optional] |
| **exclude_cn_from_sans** | **Boolean** | If true, the Common Name will not be included in DNS or Email Subject Alternate Names. Defaults to false (CN is included). | [optional][default to false] |
| **ext_key_usage** | **Array&lt;String&gt;** | A comma-separated string or list of extended key usages. Valid values can be found at https://golang.org/pkg/crypto/x509/#ExtKeyUsage -- simply drop the \&quot;ExtKeyUsage\&quot; part of the name. To remove all key usages from being set, set this value to an empty list. | [optional] |
| **ext_key_usage_oids** | **Array&lt;String&gt;** | A comma-separated string or list of extended key usage oids. | [optional] |
| **format** | **String** | Format for returned data. Can be \&quot;pem\&quot;, \&quot;der\&quot;, or \&quot;pem_bundle\&quot;. If \&quot;pem_bundle\&quot;, any private key and issuing cert will be appended to the certificate pem. If \&quot;der\&quot;, the value will be base64 encoded. Defaults to \&quot;pem\&quot;. | [optional][default to &#39;pem&#39;] |
| **ip_sans** | **Array&lt;String&gt;** | The requested IP SANs, if any, in a comma-delimited list | [optional] |
| **issuer_name** | **String** | Provide a name to the generated or existing issuer, the name must be unique across all issuers and not be the reserved value &#39;default&#39; | [optional] |
| **key_bits** | **Integer** | The number of bits to use. Allowed values are 0 (universal default); with rsa key_type: 2048 (default), 3072, or 4096; with ec key_type: 224, 256 (default), 384, or 521; ignored with ed25519. | [optional][default to 0] |
| **key_name** | **String** | Provide a name to the generated or existing key, the name must be unique across all keys and not be the reserved value &#39;default&#39; | [optional] |
| **key_ref** | **String** | Reference to a existing key; either \&quot;default\&quot; for the configured default key, an identifier or the name assigned to the key. | [optional][default to &#39;default&#39;] |
| **key_type** | **String** | The type of key to use; defaults to RSA. \&quot;rsa\&quot; \&quot;ec\&quot; and \&quot;ed25519\&quot; are the only valid values. | [optional][default to &#39;rsa&#39;] |
| **key_usage** | **Array&lt;String&gt;** | A comma-separated string or list of key usages (not extended key usages). Valid values can be found at https://golang.org/pkg/crypto/x509/#KeyUsage -- simply drop the \&quot;KeyUsage\&quot; part of the name. To remove all key usages from being set, set this value to an empty list. | [optional] |
| **locality** | **Array&lt;String&gt;** | If set, Locality will be set to this value. | [optional] |
| **max_path_length** | **Integer** | The maximum allowable path length | [optional][default to -1] |
| **not_after** | **String** | Set the not after field of the certificate with specified date value. The value format should be given in UTC format YYYY-MM-ddTHH:MM:SSZ | [optional] |
| **not_before_duration** | **Integer** | The duration before now which the certificate needs to be backdated by. | [optional][default to 30] |
| **organization** | **Array&lt;String&gt;** | If set, O (Organization) will be set to this value. | [optional] |
| **other_sans** | **Array&lt;String&gt;** | Requested other SANs, in an array with the format &lt;oid&gt;;UTF8:&lt;utf8 string value&gt; for each entry. | [optional] |
| **ou** | **Array&lt;String&gt;** | If set, OU (OrganizationalUnit) will be set to this value. | [optional] |
| **permitted_dns_domains** | **Array&lt;String&gt;** | Domains for which this certificate is allowed to sign or issue child certificates. If set, all DNS names (subject and alt) on child certs must be exact matches or subsets of the given domains (see https://tools.ietf.org/html/rfc5280#section-4.2.1.10). | [optional] |
| **postal_code** | **Array&lt;String&gt;** | If set, Postal Code will be set to this value. | [optional] |
| **private_key_format** | **String** | Format for the returned private key. Generally the default will be controlled by the \&quot;format\&quot; parameter as either base64-encoded DER or PEM-encoded DER. However, this can be set to \&quot;pkcs8\&quot; to have the returned private key contain base64-encoded pkcs8 or PEM-encoded pkcs8 instead. Defaults to \&quot;der\&quot;. | [optional][default to &#39;der&#39;] |
| **province** | **Array&lt;String&gt;** | If set, Province will be set to this value. | [optional] |
| **serial_number** | **String** | The Subject&#39;s requested serial number, if any. See RFC 4519 Section 2.31 &#39;serialNumber&#39; for a description of this field. If you want more than one, specify alternative names in the alt_names map using OID 2.5.4.5. This has no impact on the final certificate&#39;s Serial Number field. | [optional] |
| **signature_bits** | **Integer** | The number of bits to use in the signature algorithm; accepts 256 for SHA-2-256, 384 for SHA-2-384, and 512 for SHA-2-512. Defaults to 0 to automatically detect based on key length (SHA-2-256 for RSA keys, and matching the curve size for NIST P-Curves). | [optional][default to 0] |
| **street_address** | **Array&lt;String&gt;** | If set, Street Address will be set to this value. | [optional] |
| **ttl** | **Integer** | The requested Time To Live for the certificate; sets the expiration date. If not specified the role default, backend default, or system default TTL is used, in that order. Cannot be larger than the mount max TTL. Note: this only has an effect when generating a CA cert or signing a CA cert, not when generating a CSR for an intermediate CA. | [optional] |
| **uri_sans** | **Array&lt;String&gt;** | The requested URI SANs, if any, in a comma-delimited list. | [optional] |
| **use_pss** | **Boolean** | Whether or not to use PSS signatures when using a RSA key-type issuer. Defaults to false. | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiRotateRootRequest.new(
  alt_names: null,
  common_name: null,
  country: null,
  exclude_cn_from_sans: null,
  ext_key_usage: null,
  ext_key_usage_oids: null,
  format: null,
  ip_sans: null,
  issuer_name: null,
  key_bits: null,
  key_name: null,
  key_ref: null,
  key_type: null,
  key_usage: null,
  locality: null,
  max_path_length: null,
  not_after: null,
  not_before_duration: null,
  organization: null,
  other_sans: null,
  ou: null,
  permitted_dns_domains: null,
  postal_code: null,
  private_key_format: null,
  province: null,
  serial_number: null,
  signature_bits: null,
  street_address: null,
  ttl: null,
  uri_sans: null,
  use_pss: null
)
```

