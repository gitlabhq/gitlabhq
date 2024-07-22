# OpenbaoClient::KubernetesWriteAuthRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alias_name_source** | **String** | Source to use when deriving the Alias name. valid choices: \&quot;serviceaccount_uid\&quot; : &lt;token.uid&gt; e.g. 474b11b5-0f20-4f9d-8ca5-65715ab325e0 (most secure choice) \&quot;serviceaccount_name\&quot; : &lt;namespace&gt;/&lt;serviceaccount&gt; e.g. vault/vault-agent default: \&quot;serviceaccount_uid\&quot; | [optional][default to &#39;serviceaccount_uid&#39;] |
| **audience** | **String** | Optional Audience claim to verify in the jwt. | [optional] |
| **bound_cidrs** | **Array&lt;String&gt;** | Use \&quot;token_bound_cidrs\&quot; instead. If this and \&quot;token_bound_cidrs\&quot; are both specified, only \&quot;token_bound_cidrs\&quot; will be used. | [optional] |
| **bound_service_account_names** | **Array&lt;String&gt;** | List of service account names able to access this role. If set to \&quot;*\&quot; all names are allowed. | [optional] |
| **bound_service_account_namespace_selector** | **String** | A label selector for Kubernetes namespaces which are allowed to access this role. Accepts either a JSON or YAML object. If set with bound_service_account_namespaces, the conditions are ORed. | [optional] |
| **bound_service_account_namespaces** | **Array&lt;String&gt;** | List of namespaces allowed to access this role. If set to \&quot;*\&quot; all namespaces are allowed. | [optional] |
| **max_ttl** | **Integer** | Use \&quot;token_max_ttl\&quot; instead. If this and \&quot;token_max_ttl\&quot; are both specified, only \&quot;token_max_ttl\&quot; will be used. | [optional] |
| **num_uses** | **Integer** | Use \&quot;token_num_uses\&quot; instead. If this and \&quot;token_num_uses\&quot; are both specified, only \&quot;token_num_uses\&quot; will be used. | [optional] |
| **period** | **Integer** | Use \&quot;token_period\&quot; instead. If this and \&quot;token_period\&quot; are both specified, only \&quot;token_period\&quot; will be used. | [optional] |
| **policies** | **Array&lt;String&gt;** | Use \&quot;token_policies\&quot; instead. If this and \&quot;token_policies\&quot; are both specified, only \&quot;token_policies\&quot; will be used. | [optional] |
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

instance = OpenbaoClient::KubernetesWriteAuthRoleRequest.new(
  alias_name_source: null,
  audience: null,
  bound_cidrs: null,
  bound_service_account_names: null,
  bound_service_account_namespace_selector: null,
  bound_service_account_namespaces: null,
  max_ttl: null,
  num_uses: null,
  period: null,
  policies: null,
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

