# OpenbaoClient::PkiConfigureAcmeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allow_role_ext_key_usage** | **Boolean** | whether the ExtKeyUsage field from a role is used, defaults to false meaning that certificate will be signed with ServerAuth. | [optional][default to false] |
| **allowed_issuers** | **Array&lt;String&gt;** | which issuers are allowed for use with ACME; by default, this will only be the primary (default) issuer | [optional] |
| **allowed_roles** | **Array&lt;String&gt;** | which roles are allowed for use with ACME; by default via &#39;*&#39;, these will be all roles including sign-verbatim; when concrete role names are specified, any default_directory_policy role must be included to allow usage of the default acme directories under /pki/acme/directory and /pki/issuer/:issuer_id/acme/directory. | [optional] |
| **default_directory_policy** | **String** | the policy to be used for non-role-qualified ACME requests; by default ACME issuance will be otherwise unrestricted, equivalent to the sign-verbatim endpoint; one may also specify a role to use as this policy, as \&quot;role:&lt;role_name&gt;\&quot;, the specified role must be allowed by allowed_roles | [optional][default to &#39;sign-verbatim&#39;] |
| **dns_resolver** | **String** | DNS resolver to use for domain resolution on this mount. Defaults to using the default system resolver. Must be in the format &lt;host&gt;:&lt;port&gt;, with both parts mandatory. | [optional][default to &#39;&#39;] |
| **eab_policy** | **String** | Specify the policy to use for external account binding behaviour, &#39;not-required&#39;, &#39;new-account-required&#39; or &#39;always-required&#39; | [optional][default to &#39;always-required&#39;] |
| **enabled** | **Boolean** | whether ACME is enabled, defaults to false meaning that clusters will by default not get ACME support | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureAcmeRequest.new(
  allow_role_ext_key_usage: null,
  allowed_issuers: null,
  allowed_roles: null,
  default_directory_policy: null,
  dns_resolver: null,
  eab_policy: null,
  enabled: null
)
```

