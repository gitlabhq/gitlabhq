# OpenbaoClient::TokenWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_entity_aliases** | **Array&lt;String&gt;** | String or JSON list of allowed entity aliases. If set, specifies the entity aliases which are allowed to be used during token generation. This field supports globbing. | [optional] |
| **allowed_policies** | **Array&lt;String&gt;** | If set, tokens can be created with any subset of the policies in this list, rather than the normal semantics of tokens being a subset of the calling token&#39;s policies. The parameter is a comma-delimited string of policy names. | [optional] |
| **allowed_policies_glob** | **Array&lt;String&gt;** | If set, tokens can be created with any subset of glob matched policies in this list, rather than the normal semantics of tokens being a subset of the calling token&#39;s policies. The parameter is a comma-delimited string of policy name globs. | [optional] |
| **bound_cidrs** | **Array&lt;String&gt;** | Use &#39;token_bound_cidrs&#39; instead. | [optional] |
| **disallowed_policies** | **Array&lt;String&gt;** | If set, successful token creation via this role will require that no policies in the given list are requested. The parameter is a comma-delimited string of policy names. | [optional] |
| **disallowed_policies_glob** | **Array&lt;String&gt;** | If set, successful token creation via this role will require that no requested policies glob match any of policies in this list. The parameter is a comma-delimited string of policy name globs. | [optional] |
| **explicit_max_ttl** | **Integer** | Use &#39;token_explicit_max_ttl&#39; instead. | [optional] |
| **orphan** | **Boolean** | If true, tokens created via this role will be orphan tokens (have no parent) | [optional] |
| **path_suffix** | **String** | If set, tokens created via this role will contain the given suffix as a part of their path. This can be used to assist use of the &#39;revoke-prefix&#39; endpoint later on. The given suffix must match the regular expression.\\w[\\w-.]+\\w | [optional] |
| **period** | **Integer** | Use &#39;token_period&#39; instead. | [optional] |
| **renewable** | **Boolean** | Tokens created via this role will be renewable or not according to this value. Defaults to \&quot;true\&quot;. | [optional][default to true] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or JSON list of CIDR blocks. If set, specifies the blocks of IP addresses which are allowed to use the generated token. | [optional] |
| **token_explicit_max_ttl** | **Integer** | If set, tokens created via this role carry an explicit maximum TTL. During renewal, the current maximum TTL values of the role and the mount are not checked for changes, and any updates to these values will have no effect on the token being renewed. | [optional] |
| **token_no_default_policy** | **Boolean** | If true, the &#39;default&#39; policy will not automatically be added to generated tokens | [optional] |
| **token_num_uses** | **Integer** | The maximum number of times a token may be used, a value of zero means unlimited | [optional] |
| **token_period** | **Integer** | If set, tokens created via this role will have no max lifetime; instead, their renewal period will be fixed to this value. This takes an integer number of seconds, or a string duration (e.g. \&quot;24h\&quot;). | [optional] |
| **token_type** | **String** | The type of token to generate, service or batch | [optional][default to &#39;default-service&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TokenWriteRoleRequest.new(
  allowed_entity_aliases: null,
  allowed_policies: null,
  allowed_policies_glob: null,
  bound_cidrs: null,
  disallowed_policies: null,
  disallowed_policies_glob: null,
  explicit_max_ttl: null,
  orphan: null,
  path_suffix: null,
  period: null,
  renewable: null,
  token_bound_cidrs: null,
  token_explicit_max_ttl: null,
  token_no_default_policy: null,
  token_num_uses: null,
  token_period: null,
  token_type: null
)
```

