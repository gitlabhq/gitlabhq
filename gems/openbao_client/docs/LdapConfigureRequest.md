# OpenbaoClient::LdapConfigureRequest

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
| **length** | **Integer** | The desired length of passwords that OpenBao generates. | [optional] |
| **max_page_size** | **Integer** | If set to a value greater than 0, the LDAP backend will use the LDAP server&#39;s paged search control to request pages of up to the given size. This can be used to avoid hitting the LDAP server&#39;s maximum result size limit. Otherwise, the LDAP backend will not use the paged search control. | [optional][default to 0] |
| **max_ttl** | **Integer** | The maximum password time-to-live. | [optional] |
| **password_policy** | **String** | Password policy to use to generate passwords | [optional] |
| **request_timeout** | **Integer** | Timeout, in seconds, for the connection when making requests against the server before returning back an error. | [optional] |
| **schema** | **String** | The desired LDAP schema used when modifying user account passwords. | [optional][default to &#39;openldap&#39;] |
| **skip_static_role_import_rotation** | **Boolean** | Whether to skip the &#39;import&#39; rotation. | [optional] |
| **starttls** | **Boolean** | Issue a StartTLS command after establishing unencrypted connection (optional) | [optional] |
| **tls_max_version** | **String** | Maximum TLS version to use. Accepted values are &#39;tls10&#39;, &#39;tls11&#39;, &#39;tls12&#39; or &#39;tls13&#39;. Defaults to &#39;tls12&#39; | [optional][default to &#39;tls12&#39;] |
| **tls_min_version** | **String** | Minimum TLS version to use. Accepted values are &#39;tls10&#39;, &#39;tls11&#39;, &#39;tls12&#39; or &#39;tls13&#39;. Defaults to &#39;tls12&#39; | [optional][default to &#39;tls12&#39;] |
| **ttl** | **Integer** | The default password time-to-live. | [optional] |
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

instance = OpenbaoClient::LdapConfigureRequest.new(
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
  length: null,
  max_page_size: null,
  max_ttl: null,
  password_policy: null,
  request_timeout: null,
  schema: null,
  skip_static_role_import_rotation: null,
  starttls: null,
  tls_max_version: null,
  tls_min_version: null,
  ttl: null,
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

