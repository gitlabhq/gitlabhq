# OpenbaoClient::AppRoleWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bind_secret_id** | **Boolean** | Impose secret_id to be presented when logging in using this role. Defaults to &#39;true&#39;. | [optional][default to true] |
| **bound_cidr_list** | **Array&lt;String&gt;** | Use \&quot;secret_id_bound_cidrs\&quot; instead. | [optional] |
| **local_secret_ids** | **Boolean** | If set, the secret IDs generated using this role will be cluster local. This can only be set during role creation and once set, it can&#39;t be reset later. | [optional] |
| **period** | **Integer** | Use \&quot;token_period\&quot; instead. If this and \&quot;token_period\&quot; are both specified, only \&quot;token_period\&quot; will be used. | [optional] |
| **policies** | **Array&lt;String&gt;** | Use \&quot;token_policies\&quot; instead. If this and \&quot;token_policies\&quot; are both specified, only \&quot;token_policies\&quot; will be used. | [optional] |
| **role_id** | **String** | Identifier of the role. Defaults to a UUID. | [optional] |
| **secret_id_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks. If set, specifies the blocks of IP addresses which can perform the login operation. | [optional] |
| **secret_id_num_uses** | **Integer** | Number of times a SecretID can access the role, after which the SecretID will expire. Defaults to 0 meaning that the the secret_id is of unlimited use. | [optional] |
| **secret_id_ttl** | **Integer** | Duration in seconds after which the issued SecretID should expire. Defaults to 0, meaning no expiration. | [optional] |
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

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteRoleRequest.new(
  bind_secret_id: null,
  bound_cidr_list: null,
  local_secret_ids: null,
  period: null,
  policies: null,
  role_id: null,
  secret_id_bound_cidrs: null,
  secret_id_num_uses: null,
  secret_id_ttl: null,
  token_bound_cidrs: null,
  token_explicit_max_ttl: null,
  token_max_ttl: null,
  token_no_default_policy: null,
  token_num_uses: null,
  token_period: null,
  token_policies: null,
  token_strictly_bind_ip: null,
  token_ttl: null,
  token_type: null
)
```

