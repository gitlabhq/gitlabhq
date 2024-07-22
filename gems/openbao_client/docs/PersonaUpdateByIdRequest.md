# OpenbaoClient::PersonaUpdateByIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_id** | **String** | Entity ID to which this persona should be tied to | [optional] |
| **metadata** | **Object** | Metadata to be associated with the persona. In CLI, this parameter can be repeated multiple times, and it all gets merged together. For example: bao &lt;command&gt; &lt;path&gt; metadata&#x3D;key1&#x3D;value1 metadata&#x3D;key2&#x3D;value2 | [optional] |
| **mount_accessor** | **String** | Mount accessor to which this persona belongs to | [optional] |
| **name** | **String** | Name of the persona | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PersonaUpdateByIdRequest.new(
  entity_id: null,
  metadata: null,
  mount_accessor: null,
  name: null
)
```

