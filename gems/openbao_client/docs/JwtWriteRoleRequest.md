# OpenbaoClient::JwtWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_redirect_uris** | **Array&lt;String&gt;** | Comma-separated list of allowed values for redirect_uri | [optional] |
| **bound_audiences** | **Array&lt;String&gt;** | Comma-separated list of &#39;aud&#39; claims that are valid for login; any match is sufficient | [optional] |
| **bound_cidrs** | **Array&lt;String&gt;** | Use \&quot;token_bound_cidrs\&quot; instead. If this and \&quot;token_bound_cidrs\&quot; are both specified, only \&quot;token_bound_cidrs\&quot; will be used. | [optional] |
| **bound_claims** | **Object** | Map of claims/values which must match for login | [optional] |
| **bound_claims_type** | **String** | How to interpret values in the map of claims/values (which must match for login): allowed values are &#39;string&#39; or &#39;glob&#39; | [optional][default to &#39;string&#39;] |
| **bound_subject** | **String** | The &#39;sub&#39; claim that is valid for login. Optional. | [optional] |
| **claim_mappings** | **Object** | Mappings of claims (key) that will be copied to a metadata field (value) | [optional] |
| **clock_skew_leeway** | **Integer** | Duration in seconds of leeway when validating all claims to account for clock skew. Defaults to 60 (1 minute) if set to 0 and can be disabled if set to -1. | [optional] |
| **expiration_leeway** | **Integer** | Duration in seconds of leeway when validating expiration of a token to account for clock skew. Defaults to 150 (2.5 minutes) if set to 0 and can be disabled if set to -1. | [optional][default to 150] |
| **groups_claim** | **String** | The claim to use for the Identity group alias names | [optional] |
| **max_age** | **Integer** | Specifies the allowable elapsed time in seconds since the last time the user was actively authenticated. | [optional] |
| **max_ttl** | **Integer** | Use \&quot;token_max_ttl\&quot; instead. If this and \&quot;token_max_ttl\&quot; are both specified, only \&quot;token_max_ttl\&quot; will be used. | [optional] |
| **not_before_leeway** | **Integer** | Duration in seconds of leeway when validating not before values of a token to account for clock skew. Defaults to 150 (2.5 minutes) if set to 0 and can be disabled if set to -1. | [optional][default to 150] |
| **num_uses** | **Integer** | Use \&quot;token_num_uses\&quot; instead. If this and \&quot;token_num_uses\&quot; are both specified, only \&quot;token_num_uses\&quot; will be used. | [optional] |
| **oidc_scopes** | **Array&lt;String&gt;** | Comma-separated list of OIDC scopes | [optional] |
| **period** | **Integer** | Use \&quot;token_period\&quot; instead. If this and \&quot;token_period\&quot; are both specified, only \&quot;token_period\&quot; will be used. | [optional] |
| **policies** | **Array&lt;String&gt;** | Use \&quot;token_policies\&quot; instead. If this and \&quot;token_policies\&quot; are both specified, only \&quot;token_policies\&quot; will be used. | [optional] |
| **role_type** | **String** | Type of the role, either &#39;jwt&#39; or &#39;oidc&#39;. | [optional] |
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
| **user_claim** | **String** | The claim to use for the Identity entity alias name | [optional] |
| **user_claim_json_pointer** | **Boolean** | If true, the user_claim value will use JSON pointer syntax for referencing claims. | [optional] |
| **verbose_oidc_logging** | **Boolean** | Log received OIDC tokens and claims when debug-level logging is active. Not recommended in production since sensitive information may be present in OIDC responses. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::JwtWriteRoleRequest.new(
  allowed_redirect_uris: null,
  bound_audiences: null,
  bound_cidrs: null,
  bound_claims: null,
  bound_claims_type: null,
  bound_subject: null,
  claim_mappings: null,
  clock_skew_leeway: null,
  expiration_leeway: null,
  groups_claim: null,
  max_age: null,
  max_ttl: null,
  not_before_leeway: null,
  num_uses: null,
  oidc_scopes: null,
  period: null,
  policies: null,
  role_type: null,
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
  ttl: null,
  user_claim: null,
  user_claim_json_pointer: null,
  verbose_oidc_logging: null
)
```

