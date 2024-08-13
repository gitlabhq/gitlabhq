# OpenbaoClient::JwtConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bound_issuer** | **String** | The value against which to match the &#39;iss&#39; claim in a JWT. Optional. | [optional] |
| **default_role** | **String** | The default role to use if none is provided during login. If not set, a role is required during login. | [optional] |
| **jwks_ca_pem** | **String** | The CA certificate or chain of certificates, in PEM format, to use to validate connections to the JWKS URL. If not set, system certificates are used. | [optional] |
| **jwks_url** | **String** | JWKS URL to use to authenticate signatures. Cannot be used with \&quot;oidc_discovery_url\&quot; or \&quot;jwt_validation_pubkeys\&quot;. | [optional] |
| **jwt_supported_algs** | **Array&lt;String&gt;** | A list of supported signing algorithms. Defaults to RS256. | [optional] |
| **jwt_validation_pubkeys** | **Array&lt;String&gt;** | A list of PEM-encoded public keys to use to authenticate signatures locally. Cannot be used with \&quot;jwks_url\&quot; or \&quot;oidc_discovery_url\&quot;. | [optional] |
| **namespace_in_state** | **Boolean** | Pass namespace in the OIDC state parameter instead of as a separate query parameter. With this setting, the allowed redirect URL(s) in OpenBao and on the provider side should not contain a namespace query parameter. This means only one redirect URL entry needs to be maintained on the provider side for all OpenBao namespaces that will be authenticating against it. Defaults to true for new configs. | [optional] |
| **oidc_client_id** | **String** | The OAuth Client ID configured with your OIDC provider. | [optional] |
| **oidc_client_secret** | **String** | The OAuth Client Secret configured with your OIDC provider. | [optional] |
| **oidc_discovery_ca_pem** | **String** | The CA certificate or chain of certificates, in PEM format, to use to validate connections to the OIDC Discovery URL. If not set, system certificates are used. | [optional] |
| **oidc_discovery_url** | **String** | OIDC Discovery URL, without any .well-known component (base path). Cannot be used with \&quot;jwks_url\&quot; or \&quot;jwt_validation_pubkeys\&quot;. | [optional] |
| **oidc_response_mode** | **String** | The response mode to be used in the OAuth2 request. Allowed values are &#39;query&#39; and &#39;form_post&#39;. | [optional] |
| **oidc_response_types** | **Array&lt;String&gt;** | The response types to request. Allowed values are &#39;code&#39; and &#39;id_token&#39;. Defaults to &#39;code&#39;. | [optional] |
| **provider_config** | **Object** | Provider-specific configuration. Optional. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::JwtConfigureRequest.new(
  bound_issuer: null,
  default_role: null,
  jwks_ca_pem: null,
  jwks_url: null,
  jwt_supported_algs: null,
  jwt_validation_pubkeys: null,
  namespace_in_state: null,
  oidc_client_id: null,
  oidc_client_secret: null,
  oidc_discovery_ca_pem: null,
  oidc_discovery_url: null,
  oidc_response_mode: null,
  oidc_response_types: null,
  provider_config: null
)
```

