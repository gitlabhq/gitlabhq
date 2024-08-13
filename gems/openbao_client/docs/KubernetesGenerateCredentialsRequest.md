# OpenbaoClient::KubernetesGenerateCredentialsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **audiences** | **Array&lt;String&gt;** | The intended audiences of the generated credentials | [optional] |
| **cluster_role_binding** | **Boolean** | If true, generate a ClusterRoleBinding to grant permissions across the whole cluster instead of within a namespace. Requires the OpenBao role to have kubernetes_role_type set to ClusterRole. | [optional] |
| **kubernetes_namespace** | **String** | The name of the Kubernetes namespace in which to generate the credentials |  |
| **ttl** | **Integer** | The TTL of the generated credentials | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KubernetesGenerateCredentialsRequest.new(
  audiences: null,
  cluster_role_binding: null,
  kubernetes_namespace: null,
  ttl: null
)
```

