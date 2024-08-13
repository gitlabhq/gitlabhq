# OpenbaoClient::AuthReadTuningInformationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_managed_keys** | **Array&lt;String&gt;** |  | [optional] |
| **allowed_response_headers** | **Array&lt;String&gt;** |  | [optional] |
| **audit_non_hmac_request_keys** | **Array&lt;String&gt;** |  | [optional] |
| **audit_non_hmac_response_keys** | **Array&lt;String&gt;** |  | [optional] |
| **default_lease_ttl** | **Integer** |  | [optional] |
| **description** | **String** |  | [optional] |
| **external_entropy_access** | **Boolean** |  | [optional] |
| **force_no_cache** | **Boolean** |  | [optional] |
| **listing_visibility** | **String** |  | [optional] |
| **max_lease_ttl** | **Integer** |  | [optional] |
| **options** | **Object** |  | [optional] |
| **passthrough_request_headers** | **Array&lt;String&gt;** |  | [optional] |
| **plugin_version** | **String** |  | [optional] |
| **token_type** | **String** |  | [optional] |
| **user_lockout_counter_reset_duration** | **Integer** |  | [optional] |
| **user_lockout_disable** | **Boolean** |  | [optional] |
| **user_lockout_duration** | **Integer** |  | [optional] |
| **user_lockout_threshold** | **Integer** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AuthReadTuningInformationResponse.new(
  allowed_managed_keys: null,
  allowed_response_headers: null,
  audit_non_hmac_request_keys: null,
  audit_non_hmac_response_keys: null,
  default_lease_ttl: null,
  description: null,
  external_entropy_access: null,
  force_no_cache: null,
  listing_visibility: null,
  max_lease_ttl: null,
  options: null,
  passthrough_request_headers: null,
  plugin_version: null,
  token_type: null,
  user_lockout_counter_reset_duration: null,
  user_lockout_disable: null,
  user_lockout_duration: null,
  user_lockout_threshold: null
)
```

