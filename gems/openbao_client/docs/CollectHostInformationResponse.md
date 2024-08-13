# OpenbaoClient::CollectHostInformationResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cpu** | **Array&lt;Object&gt;** |  | [optional] |
| **cpu_times** | **Array&lt;Object&gt;** |  | [optional] |
| **disk** | **Array&lt;Object&gt;** |  | [optional] |
| **host** | **Object** |  | [optional] |
| **memory** | **Object** |  | [optional] |
| **timestamp** | **Time** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::CollectHostInformationResponse.new(
  cpu: null,
  cpu_times: null,
  disk: null,
  host: null,
  memory: null,
  timestamp: null
)
```

