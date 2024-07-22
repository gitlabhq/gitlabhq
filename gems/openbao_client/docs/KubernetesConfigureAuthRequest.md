# OpenbaoClient::KubernetesConfigureAuthRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disable_iss_validation** | **Boolean** | Disable JWT issuer validation (Deprecated, will be removed in a future release) | [optional][default to true] |
| **disable_local_ca_jwt** | **Boolean** | Disable defaulting to the local CA cert and service account JWT when running in a Kubernetes pod | [optional][default to false] |
| **issuer** | **String** | Optional JWT issuer. If no issuer is specified, then this plugin will use kubernetes.io/serviceaccount as the default issuer. (Deprecated, will be removed in a future release) | [optional] |
| **kubernetes_ca_cert** | **String** | PEM encoded CA cert for use by the TLS client used to talk with the API. | [optional] |
| **kubernetes_host** | **String** | Host must be a host string, a host:port pair, or a URL to the base of the Kubernetes API server. | [optional] |
| **pem_keys** | **Array&lt;String&gt;** | Optional list of PEM-formated public keys or certificates used to verify the signatures of kubernetes service account JWTs. If a certificate is given, its public key will be extracted. Not every installation of Kubernetes exposes these keys. | [optional] |
| **token_reviewer_jwt** | **String** | A service account JWT (or other token) used as a bearer token to access the TokenReview API to validate other JWTs during login. If not set the JWT used for login will be used to access the API. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KubernetesConfigureAuthRequest.new(
  disable_iss_validation: null,
  disable_local_ca_jwt: null,
  issuer: null,
  kubernetes_ca_cert: null,
  kubernetes_host: null,
  pem_keys: null,
  token_reviewer_jwt: null
)
```

