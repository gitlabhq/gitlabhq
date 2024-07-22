# OpenbaoClient::KerberosConfigureLdapRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **anonymous_group_search** | **Boolean** | Use anonymous binds when performing LDAP group searches (if true the initial credentials will still be used for the initial connection test). | [optional][default to false] |
| **binddn** | **String** | LDAP DN for searching for the user DN (optional) | [optional] |
| **bindpass** | **String** | LDAP password for searching for the user DN (optional) | [optional] |
| **case_sensitive_names** | **Boolean** | If true, case sensitivity will be used when comparing usernames and groups for matching policies. | [optional] |
| **certificate** | **String** | CA certificate to use when verifying LDAP server certificate, must be x509 PEM encoded (optional) | [optional] |
| **client_tls_cert** | **String** | Client certificate to provide to the LDAP server, must be x509 PEM encoded (optional) | [optional] |
| **client_tls_key** | **String** | Client certificate key to provide to the LDAP server, must be x509 PEM encoded (optional) | [optional] |
| **connection_timeout** | **Integer** | Timeout, in seconds, when attempting to connect to the LDAP server before trying the next URL in the configuration. | [optional] |
| **deny_null_bind** | **Boolean** | Denies an unauthenticated LDAP bind request if the user&#39;s password is empty; defaults to true | [optional][default to true] |
| **dereference_aliases** | **String** | When aliases should be dereferenced on search operations. Accepted values are &#39;never&#39;, &#39;finding&#39;, &#39;searching&#39;, &#39;always&#39;. Defaults to &#39;never&#39;. | [optional][default to &#39;never&#39;] |
| **discoverdn** | **Boolean** | Use anonymous bind to discover the bind DN of a user (optional) | [optional] |
| **groupattr** | **String** | LDAP attribute to follow on objects returned by &lt;groupfilter&gt; in order to enumerate user group membership. Examples: \&quot;cn\&quot; or \&quot;memberOf\&quot;, etc. Default: cn | [optional][default to &#39;cn&#39;] |
| **groupdn** | **String** | LDAP search base to use for group membership search (eg: ou&#x3D;Groups,dc&#x3D;example,dc&#x3D;org) | [optional] |
| **groupfilter** | **String** | Go template for querying group membership of user (optional) The template can access the following context variables: UserDN, Username Example: (&amp;(objectClass&#x3D;group)(member:1.2.840.113556.1.4.1941:&#x3D;{{.UserDN}})) Default: (|(memberUid&#x3D;{{.Username}})(member&#x3D;{{.UserDN}})(uniqueMember&#x3D;{{.UserDN}})) | [optional][default to &#39;(|(memberUid&#x3D;{{.Username}})(member&#x3D;{{.UserDN}})(uniqueMember&#x3D;{{.UserDN}}))&#39;] |
| **insecure_tls** | **Boolean** | Skip LDAP server SSL Certificate verification - VERY insecure (optional) | [optional] |
| **max_page_size** | **Integer** | If set to a value greater than 0, the LDAP backend will use the LDAP server&#39;s paged search control to request pages of up to the given size. This can be used to avoid hitting the LDAP server&#39;s maximum result size limit. Otherwise, the LDAP backend will not use the paged search control. | [optional][default to 0] |
| **request_timeout** | **Integer** | Timeout, in seconds, for the connection when making requests against the server before returning back an error. | [optional] |
| **starttls** | **Boolean** | Issue a StartTLS command after establishing unencrypted connection (optional) | [optional] |
| **tls_max_version** | **String** | Maximum TLS version to use. Accepted values are &#39;tls10&#39;, &#39;tls11&#39;, &#39;tls12&#39; or &#39;tls13&#39;. Defaults to &#39;tls12&#39; | [optional][default to &#39;tls12&#39;] |
| **tls_min_version** | **String** | Minimum TLS version to use. Accepted values are &#39;tls10&#39;, &#39;tls11&#39;, &#39;tls12&#39; or &#39;tls13&#39;. Defaults to &#39;tls12&#39; | [optional][default to &#39;tls12&#39;] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or JSON list of CIDR blocks. If set, specifies the blocks of IP addresses which are allowed to use the generated token. | [optional] |
| **token_explicit_max_ttl** | **Integer** | If set, tokens created via this role carry an explicit maximum TTL. During renewal, the current maximum TTL values of the role and the mount are not checked for changes, and any updates to these values will have no effect on the token being renewed. | [optional] |
| **token_max_ttl** | **Integer** | The maximum lifetime of the generated token | [optional] |
| **token_no_default_policy** | **Boolean** | If true, the &#39;default&#39; policy will not automatically be added to generated tokens | [optional] |
| **token_num_uses** | **Integer** | The maximum number of times a token may be used, a value of zero means unlimited | [optional] |
| **token_period** | **Integer** | If set, tokens created via this role will have no max lifetime; instead, their renewal period will be fixed to this value. This takes an integer number of seconds, or a string duration (e.g. \&quot;24h\&quot;). | [optional] |
| **token_policies** | **Array&lt;String&gt;** | Comma-separated list of policies. This will apply to all tokens generated by this auth method, in addition to any configured for specific users/groups. | [optional] |
| **token_strictly_bind_ip** | **Boolean** | If true, CIDRs for the token will be strictly bound to the source IP address of the login request | [optional] |
| **token_ttl** | **Integer** | The initial ttl of the token to generate | [optional] |
| **token_type** | **String** | The type of token to generate, service or batch | [optional][default to &#39;default-service&#39;] |
| **upndomain** | **String** | Enables userPrincipalDomain login with [username]@UPNDomain (optional) | [optional] |
| **url** | **String** | LDAP URL to connect to (default: ldap://127.0.0.1). Multiple URLs can be specified by concatenating them with commas; they will be tried in-order. | [optional][default to &#39;ldap://127.0.0.1&#39;] |
| **use_pre111_group_cn_behavior** | **Boolean** | In Vault 1.1.1 (prior to OpenBao&#39;s fork), a fix for handling group CN values of different cases unfortunately introduced a regression that could cause previously defined groups to not be found due to a change in the resulting name. If set true, the pre-1.1.1 behavior for matching group CNs will be used. This is only needed in some upgrade scenarios for backwards compatibility. It is enabled by default if the config is upgraded but disabled by default on new configurations. | [optional] |
| **use_token_groups** | **Boolean** | If true, use the Active Directory tokenGroups constructed attribute of the user to find the group memberships. This will find all security groups including nested ones. | [optional][default to false] |
| **userattr** | **String** | Attribute used for users (default: cn) | [optional][default to &#39;cn&#39;] |
| **userdn** | **String** | LDAP domain to use for users (eg: ou&#x3D;People,dc&#x3D;example,dc&#x3D;org) | [optional] |
| **userfilter** | **String** | Go template for LDAP user search filer (optional) The template can access the following context variables: UserAttr, Username Default: ({{.UserAttr}}&#x3D;{{.Username}}) | [optional][default to &#39;({{.UserAttr}}&#x3D;{{.Username}})&#39;] |
| **username_as_alias** | **Boolean** | If true, sets the alias name to the username | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KerberosConfigureLdapRequest.new(
  anonymous_group_search: null,
  binddn: null,
  bindpass: null,
  case_sensitive_names: null,
  certificate: null,
  client_tls_cert: null,
  client_tls_key: null,
  connection_timeout: null,
  deny_null_bind: null,
  dereference_aliases: null,
  discoverdn: null,
  groupattr: null,
  groupdn: null,
  groupfilter: null,
  insecure_tls: null,
  max_page_size: null,
  request_timeout: null,
  starttls: null,
  tls_max_version: null,
  tls_min_version: null,
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
  upndomain: null,
  url: null,
  use_pre111_group_cn_behavior: null,
  use_token_groups: null,
  userattr: null,
  userdn: null,
  userfilter: null,
  username_as_alias: null
)
```

