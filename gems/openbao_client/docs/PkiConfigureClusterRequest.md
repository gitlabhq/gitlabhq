# OpenbaoClient::PkiConfigureClusterRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **aia_path** | **String** | Optional URI to this mount&#39;s AIA distribution point; may refer to an external non-OpenBao responder. This is for resolving AIA URLs and providing the {{cluster_aia_path}} template parameter and will not be used for other purposes. As such, unlike path above, this could safely be an insecure transit mechanism (like HTTP without TLS). For example: http://cdn.example.com/pr1/pki | [optional] |
| **path** | **String** | Canonical URI to this mount on this performance replication cluster&#39;s external address. This is for resolving AIA URLs and providing the {{cluster_path}} template parameter but might be used for other purposes in the future. This should only point back to this particular PR replica and should not ever point to another PR cluster. It may point to any node in the PR replica, including standby nodes, and need not always point to the active node. For example: https://pr1.bao.example.com:8200/v1/pki | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureClusterRequest.new(
  aia_path: null,
  path: null
)
```

