# OpenbaoClient::MountsTuneConfigurationParametersRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_managed_keys** | **Array&lt;String&gt;** |  | [optional] |
| **allowed_response_headers** | **Array&lt;String&gt;** | A list of headers to whitelist and allow a plugin to set on responses. | [optional] |
| **audit_non_hmac_request_keys** | **Array&lt;String&gt;** | The list of keys in the request data object that will not be HMAC&#39;ed by audit devices. | [optional] |
| **audit_non_hmac_response_keys** | **Array&lt;String&gt;** | The list of keys in the response data object that will not be HMAC&#39;ed by audit devices. | [optional] |
| **default_lease_ttl** | **String** | The default lease TTL for this mount. | [optional] |
| **description** | **String** | User-friendly description for this credential backend. | [optional] |
| **listing_visibility** | **String** | Determines the visibility of the mount in the UI-specific listing endpoint. Accepted value are &#39;unauth&#39; and &#39;hidden&#39;, with the empty default (&#39;&#39;) behaving like &#39;hidden&#39;. | [optional] |
| **max_lease_ttl** | **String** | The max lease TTL for this mount. | [optional] |
| **options** | **Object** | The options to pass into the backend. Should be a json object with string keys and values. | [optional] |
| **passthrough_request_headers** | **Array&lt;String&gt;** | A list of headers to whitelist and pass from the request to the plugin. | [optional] |
| **plugin_version** | **String** | The semantic version of the plugin to use. | [optional] |
| **token_type** | **String** | The type of token to issue (service or batch). | [optional] |
| **user_lockout_config** | **Object** | The user lockout configuration to pass into the backend. Should be a json object with string keys and values. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::MountsTuneConfigurationParametersRequest.new(
  allowed_managed_keys: null,
  allowed_response_headers: null,
  audit_non_hmac_request_keys: null,
  audit_non_hmac_response_keys: null,
  default_lease_ttl: null,
  description: null,
  listing_visibility: null,
  max_lease_ttl: null,
  options: null,
  passthrough_request_headers: null,
  plugin_version: null,
  token_type: null,
  user_lockout_config: null
)
```

