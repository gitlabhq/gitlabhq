# OpenbaoClient::MountsReadTuningInformationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_managed_keys** | **Array&lt;String&gt;** |  | [optional] |
| **allowed_response_headers** | **Array&lt;String&gt;** | A list of headers to whitelist and allow a plugin to set on responses. | [optional] |
| **audit_non_hmac_request_keys** | **Array&lt;String&gt;** |  | [optional] |
| **audit_non_hmac_response_keys** | **Array&lt;String&gt;** |  | [optional] |
| **default_lease_ttl** | **Integer** | The default lease TTL for this mount. | [optional] |
| **description** | **String** | User-friendly description for this credential backend. | [optional] |
| **external_entropy_access** | **Boolean** |  | [optional] |
| **force_no_cache** | **Boolean** |  | [optional] |
| **listing_visibility** | **String** |  | [optional] |
| **max_lease_ttl** | **Integer** | The max lease TTL for this mount. | [optional] |
| **options** | **Object** | The options to pass into the backend. Should be a json object with string keys and values. | [optional] |
| **passthrough_request_headers** | **Array&lt;String&gt;** |  | [optional] |
| **plugin_version** | **String** | The semantic version of the plugin to use. | [optional] |
| **token_type** | **String** | The type of token to issue (service or batch). | [optional] |
| **user_lockout_counter_reset_duration** | **Integer** |  | [optional] |
| **user_lockout_disable** | **Boolean** |  | [optional] |
| **user_lockout_duration** | **Integer** |  | [optional] |
| **user_lockout_threshold** | **Integer** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MountsReadTuningInformationResponse.new(
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

