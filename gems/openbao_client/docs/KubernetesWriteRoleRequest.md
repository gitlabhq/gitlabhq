# OpenbaoClient::KubernetesWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allowed_kubernetes_namespace_selector** | **String** | A label selector for Kubernetes namespaces in which credentials can be generated. Accepts either a JSON or YAML object. If set with allowed_kubernetes_namespaces, the conditions are conjuncted. | [optional] |
| **allowed_kubernetes_namespaces** | **Array&lt;String&gt;** | A list of the Kubernetes namespaces in which credentials can be generated. If set to \&quot;*\&quot; all namespaces are allowed. | [optional] |
| **extra_annotations** | **Object** | Additional annotations to apply to all generated Kubernetes objects. | [optional] |
| **extra_labels** | **Object** | Additional labels to apply to all generated Kubernetes objects. | [optional] |
| **generated_role_rules** | **String** | The Role or ClusterRole rules to use when generating a role. Accepts either a JSON or YAML object. If set, the entire chain of Kubernetes objects will be generated. | [optional] |
| **kubernetes_role_name** | **String** | The pre-existing Role or ClusterRole to bind a generated service account to. If set, Kubernetes token, service account, and role binding objects will be created. | [optional] |
| **kubernetes_role_type** | **String** | Specifies whether the Kubernetes role is a Role or ClusterRole. | [optional][default to &#39;Role&#39;] |
| **name_template** | **String** | The name template to use when generating service accounts, roles and role bindings. If unset, a default template is used. | [optional] |
| **service_account_name** | **String** | The pre-existing service account to generate tokens for. Mutually exclusive with all role parameters. If set, only a Kubernetes service account token will be created. | [optional] |
| **token_default_audiences** | **Array&lt;String&gt;** | The default audiences for generated Kubernetes service account tokens. If not set or set to \&quot;\&quot;, will use k8s cluster default. | [optional] |
| **token_default_ttl** | **Integer** | The default ttl for generated Kubernetes service account tokens. If not set or set to 0, will use system default. | [optional] |
| **token_max_ttl** | **Integer** | The maximum ttl for generated Kubernetes service account tokens. If not set or set to 0, will use system default. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KubernetesWriteRoleRequest.new(
  allowed_kubernetes_namespace_selector: null,
  allowed_kubernetes_namespaces: null,
  extra_annotations: null,
  extra_labels: null,
  generated_role_rules: null,
  kubernetes_role_name: null,
  kubernetes_role_type: null,
  name_template: null,
  service_account_name: null,
  token_default_audiences: null,
  token_default_ttl: null,
  token_max_ttl: null
)
```

