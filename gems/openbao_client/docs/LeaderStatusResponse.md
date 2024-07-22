# OpenbaoClient::LeaderStatusResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **active_time** | **Time** |  | [optional] |
| **ha_enabled** | **Boolean** |  | [optional] |
| **is_self** | **Boolean** |  | [optional] |
| **last_wal** | **Integer** |  | [optional] |
| **leader_address** | **String** |  | [optional] |
| **leader_cluster_address** | **String** |  | [optional] |
| **performance_standby** | **Boolean** |  | [optional] |
| **performance_standby_last_remote_wal** | **Integer** |  | [optional] |
| **raft_applied_index** | **Integer** |  | [optional] |
| **raft_committed_index** | **Integer** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::LeaderStatusResponse.new(
  active_time: null,
  ha_enabled: null,
  is_self: null,
  last_wal: null,
  leader_address: null,
  leader_cluster_address: null,
  performance_standby: null,
  performance_standby_last_remote_wal: null,
  raft_applied_index: null,
  raft_committed_index: null
)
```

