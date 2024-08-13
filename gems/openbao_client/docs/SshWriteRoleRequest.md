# OpenbaoClient::SshWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm_signer** | **String** | [Not applicable for OTP type] [Optional for CA type] When supplied, this value specifies a signing algorithm for the key. Possible values: ssh-rsa, rsa-sha2-256, rsa-sha2-512, default, or the empty string. | [optional] |
| **allow_bare_domains** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, host certificates that are requested are allowed to use the base domains listed in \&quot;allowed_domains\&quot;, e.g. \&quot;example.com\&quot;. This is a separate option as in some cases this can be considered a security threat. | [optional] |
| **allow_host_certificates** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, certificates are allowed to be signed for use as a &#39;host&#39;. | [optional][default to false] |
| **allow_subdomains** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, host certificates that are requested are allowed to use subdomains of those listed in \&quot;allowed_domains\&quot;. | [optional] |
| **allow_user_certificates** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, certificates are allowed to be signed for use as a &#39;user&#39;. | [optional][default to false] |
| **allow_user_key_ids** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If true, users can override the key ID for a signed certificate with the \&quot;key_id\&quot; field. When false, the key ID will always be the token display name. The key ID is logged by the SSH server and can be useful for auditing. | [optional] |
| **allowed_critical_options** | **String** | [Not applicable for OTP type] [Optional for CA type] A comma-separated list of critical options that certificates can have when signed. To allow any critical options, set this to an empty string. | [optional] |
| **allowed_domains** | **String** | [Not applicable for OTP type] [Optional for CA type] If this option is not specified, client can request for a signed certificate for any valid host. If only certain domains are allowed, then this list enforces it. | [optional] |
| **allowed_domains_template** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, Allowed domains can be specified using identity template policies. Non-templated domains are also permitted. | [optional][default to false] |
| **allowed_extensions** | **String** | [Not applicable for OTP type] [Optional for CA type] A comma-separated list of extensions that certificates can have when signed. An empty list means that no extension overrides are allowed by an end-user; explicitly specify &#39;*&#39; to allow any extensions to be set. | [optional] |
| **allowed_user_key_lengths** | **Object** | [Not applicable for OTP type] [Optional for CA type] If set, allows the enforcement of key types and minimum key sizes to be signed. | [optional] |
| **allowed_users** | **String** | [Optional for all types] [Works differently for CA type] If this option is not specified, or is &#39;*&#39;, client can request a credential for any valid user at the remote host, including the admin user. If only certain usernames are to be allowed, then this list enforces it. If this field is set, then credentials can only be created for default_user and usernames present in this list. Setting this option will enable all the users with access to this role to fetch credentials for all other usernames in this list. Use with caution. N.B.: with the CA type, an empty list means that no users are allowed; explicitly specify &#39;*&#39; to allow any user. | [optional] |
| **allowed_users_template** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, Allowed users can be specified using identity template policies. Non-templated users are also permitted. | [optional][default to false] |
| **cidr_list** | **String** | [Optional for OTP type] [Not applicable for CA type] Comma separated list of CIDR blocks for which the role is applicable for. CIDR blocks can belong to more than one role. | [optional] |
| **default_critical_options** | **Object** | [Not applicable for OTP type] [Optional for CA type] Critical options certificates should have if none are provided when signing. This field takes in key value pairs in JSON format. Note that these are not restricted by \&quot;allowed_critical_options\&quot;. Defaults to none. | [optional] |
| **default_extensions** | **Object** | [Not applicable for OTP type] [Optional for CA type] Extensions certificates should have if none are provided when signing. This field takes in key value pairs in JSON format. Note that these are not restricted by \&quot;allowed_extensions\&quot;. Defaults to none. | [optional] |
| **default_extensions_template** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, Default extension values can be specified using identity template policies. Non-templated extension values are also permitted. | [optional][default to false] |
| **default_user** | **String** | [Required for OTP type] [Optional for CA type] Default username for which a credential will be generated. When the endpoint &#39;creds/&#39; is used without a username, this value will be used as default username. | [optional] |
| **default_user_template** | **Boolean** | [Not applicable for OTP type] [Optional for CA type] If set, Default user can be specified using identity template policies. Non-templated users are also permitted. | [optional][default to false] |
| **exclude_cidr_list** | **String** | [Optional for OTP type] [Not applicable for CA type] Comma separated list of CIDR blocks. IP addresses belonging to these blocks are not accepted by the role. This is particularly useful when big CIDR blocks are being used by the role and certain parts of it needs to be kept out. | [optional] |
| **key_id_format** | **String** | [Not applicable for OTP type] [Optional for CA type] When supplied, this value specifies a custom format for the key id of a signed certificate. The following variables are available for use: &#39;{{token_display_name}}&#39; - The display name of the token used to make the request. &#39;{{role_name}}&#39; - The name of the role signing the request. &#39;{{public_key_hash}}&#39; - A SHA256 checksum of the public key that is being signed. | [optional] |
| **key_type** | **String** | [Required for all types] Type of key used to login to hosts. It can be either &#39;otp&#39; or &#39;ca&#39;. &#39;otp&#39; type requires agent to be installed in remote hosts. | [optional] |
| **max_ttl** | **Integer** | [Not applicable for OTP type] [Optional for CA type] The maximum allowed lease duration | [optional] |
| **not_before_duration** | **Integer** | [Not applicable for OTP type] [Optional for CA type] The duration that the SSH certificate should be backdated by at issuance. | [optional][default to 30] |
| **port** | **Integer** | [Optional for OTP type] [Not applicable for CA type] Port number for SSH connection. Default is &#39;22&#39;. Port number does not play any role in creation of OTP. For &#39;otp&#39; type, this is just a way to inform client about the port number to use. Port number will be returned to client by OpenBao server along with OTP. | [optional] |
| **ttl** | **Integer** | [Not applicable for OTP type] [Optional for CA type] The lease duration if no specific lease duration is requested. The lease duration controls the expiration of certificates issued by this backend. Defaults to the value of max_ttl. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshWriteRoleRequest.new(
  algorithm_signer: null,
  allow_bare_domains: null,
  allow_host_certificates: null,
  allow_subdomains: null,
  allow_user_certificates: null,
  allow_user_key_ids: null,
  allowed_critical_options: null,
  allowed_domains: null,
  allowed_domains_template: null,
  allowed_extensions: null,
  allowed_user_key_lengths: null,
  allowed_users: null,
  allowed_users_template: null,
  cidr_list: null,
  default_critical_options: null,
  default_extensions: null,
  default_extensions_template: null,
  default_user: null,
  default_user_template: null,
  exclude_cidr_list: null,
  key_id_format: null,
  key_type: null,
  max_ttl: null,
  not_before_duration: null,
  port: null,
  ttl: null
)
```

