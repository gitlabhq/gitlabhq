# OpenbaoClient::CertWriteCertificateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_common_names** | **Array&lt;String&gt;** | A comma-separated list of names. At least one must exist in the Common Name. Supports globbing. | [optional] |
| **allowed_dns_sans** | **Array&lt;String&gt;** | A comma-separated list of DNS names. At least one must exist in the SANs. Supports globbing. | [optional] |
| **allowed_email_sans** | **Array&lt;String&gt;** | A comma-separated list of Email Addresses. At least one must exist in the SANs. Supports globbing. | [optional] |
| **allowed_metadata_extensions** | **Array&lt;String&gt;** | A comma-separated string or array of oid extensions. Upon successful authentication, these extensions will be added as metadata if they are present in the certificate. The metadata key will be the string consisting of the oid numbers separated by a dash (-) instead of a dot (.) to allow usage in ACL templates. | [optional] |
| **allowed_names** | **Array&lt;String&gt;** | A comma-separated list of names. At least one must exist in either the Common Name or SANs. Supports globbing. This parameter is deprecated, please use allowed_common_names, allowed_dns_sans, allowed_email_sans, allowed_uri_sans. | [optional] |
| **allowed_organizational_units** | **Array&lt;String&gt;** | A comma-separated list of Organizational Units names. At least one must exist in the OU field. | [optional] |
| **allowed_uri_sans** | **Array&lt;String&gt;** | A comma-separated list of URIs. At least one must exist in the SANs. Supports globbing. | [optional] |
| **bound_cidrs** | **Array&lt;String&gt;** | Use \&quot;token_bound_cidrs\&quot; instead. If this and \&quot;token_bound_cidrs\&quot; are both specified, only \&quot;token_bound_cidrs\&quot; will be used. | [optional] |
| **certificate** | **String** | The public certificate that should be trusted. Must be x509 PEM encoded. | [optional] |
| **display_name** | **String** | The display name to use for clients using this certificate. | [optional] |
| **lease** | **Integer** | Use \&quot;token_ttl\&quot; instead. If this and \&quot;token_ttl\&quot; are both specified, only \&quot;token_ttl\&quot; will be used. | [optional] |
| **max_ttl** | **Integer** | Use \&quot;token_max_ttl\&quot; instead. If this and \&quot;token_max_ttl\&quot; are both specified, only \&quot;token_max_ttl\&quot; will be used. | [optional] |
| **ocsp_ca_certificates** | **String** | Any additional CA certificates needed to communicate with OCSP servers | [optional] |
| **ocsp_enabled** | **Boolean** | Whether to attempt OCSP verification of certificates at login | [optional] |
| **ocsp_fail_open** | **Boolean** | If set to true, if an OCSP revocation cannot be made successfully, login will proceed rather than failing. If false, failing to get an OCSP status fails the request. | [optional][default to false] |
| **ocsp_query_all_servers** | **Boolean** | If set to true, rather than accepting the first successful OCSP response, query all servers and consider the certificate valid only if all servers agree. | [optional][default to false] |
| **ocsp_servers_override** | **Array&lt;String&gt;** | A comma-separated list of OCSP server addresses. If unset, the OCSP server is determined from the AuthorityInformationAccess extension on the certificate being inspected. | [optional] |
| **period** | **Integer** | Use \&quot;token_period\&quot; instead. If this and \&quot;token_period\&quot; are both specified, only \&quot;token_period\&quot; will be used. | [optional] |
| **policies** | **Array&lt;String&gt;** | Use \&quot;token_policies\&quot; instead. If this and \&quot;token_policies\&quot; are both specified, only \&quot;token_policies\&quot; will be used. | [optional] |
| **required_extensions** | **Array&lt;String&gt;** | A comma-separated string or array of extensions formatted as \&quot;oid:value\&quot;. Expects the extension value to be some type of ASN1 encoded string. All values much match. Supports globbing on \&quot;value\&quot;. | [optional] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or JSON list of CIDR blocks. If set, specifies the blocks of IP addresses which are allowed to use the generated token. | [optional] |
| **token_explicit_max_ttl** | **Integer** | If set, tokens created via this role carry an explicit maximum TTL. During renewal, the current maximum TTL values of the role and the mount are not checked for changes, and any updates to these values will have no effect on the token being renewed. | [optional] |
| **token_max_ttl** | **Integer** | The maximum lifetime of the generated token | [optional] |
| **token_no_default_policy** | **Boolean** | If true, the &#39;default&#39; policy will not automatically be added to generated tokens | [optional] |
| **token_num_uses** | **Integer** | The maximum number of times a token may be used, a value of zero means unlimited | [optional] |
| **token_period** | **Integer** | If set, tokens created via this role will have no max lifetime; instead, their renewal period will be fixed to this value. This takes an integer number of seconds, or a string duration (e.g. \&quot;24h\&quot;). | [optional] |
| **token_policies** | **Array&lt;String&gt;** | Comma-separated list of policies | [optional] |
| **token_strictly_bind_ip** | **Boolean** | If true, CIDRs for the token will be strictly bound to the source IP address of the login request | [optional] |
| **token_ttl** | **Integer** | The initial ttl of the token to generate | [optional] |
| **token_type** | **String** | The type of token to generate, service or batch | [optional][default to &#39;default-service&#39;] |
| **ttl** | **Integer** | Use \&quot;token_ttl\&quot; instead. If this and \&quot;token_ttl\&quot; are both specified, only \&quot;token_ttl\&quot; will be used. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CertWriteCertificateRequest.new(
  allowed_common_names: null,
  allowed_dns_sans: null,
  allowed_email_sans: null,
  allowed_metadata_extensions: null,
  allowed_names: null,
  allowed_organizational_units: null,
  allowed_uri_sans: null,
  bound_cidrs: null,
  certificate: null,
  display_name: null,
  lease: null,
  max_ttl: null,
  ocsp_ca_certificates: null,
  ocsp_enabled: null,
  ocsp_fail_open: null,
  ocsp_query_all_servers: null,
  ocsp_servers_override: null,
  period: null,
  policies: null,
  required_extensions: null,
  token_bound_cidrs: null,
  token_explicit_max_ttl: null,
  token_max_ttl: null,
  token_no_default_policy: null,
  token_num_uses: null,
  token_period: null,
  token_policies: null,
  token_strictly_bind_ip: null,
  token_ttl: null,
  token_type: null,
  ttl: null
)
```

