# OpenbaoClient::KubernetesConfigureRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disable_local_ca_jwt** | **Boolean** | Disable defaulting to the local CA certificate and service account JWT when running in a Kubernetes pod. | [optional][default to false] |
| **kubernetes_ca_cert** | **String** | PEM encoded CA certificate to use to verify the Kubernetes API server certificate. Defaults to the local pod&#39;s CA if found. | [optional] |
| **kubernetes_host** | **String** | Kubernetes API URL to connect to. Defaults to https://$KUBERNETES_SERVICE_HOST:KUBERNETES_SERVICE_PORT if those environment variables are set. | [optional] |
| **service_account_jwt** | **String** | The JSON web token of the service account used by the secret engine to manage Kubernetes credentials. Defaults to the local pod&#39;s JWT if found. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KubernetesConfigureRequest.new(
  disable_local_ca_jwt: null,
  kubernetes_ca_cert: null,
  kubernetes_host: null,
  service_account_jwt: null
)
```

