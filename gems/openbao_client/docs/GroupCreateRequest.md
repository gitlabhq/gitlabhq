# OpenbaoClient::GroupCreateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group. If set, updates the corresponding existing group. | [optional] |
| **member_entity_ids** | **Array&lt;String&gt;** | Entity IDs to be assigned as group members. | [optional] |
| **member_group_ids** | **Array&lt;String&gt;** | Group IDs to be assigned as group members. | [optional] |
| **metadata** | **Object** | Metadata to be associated with the group. In CLI, this parameter can be repeated multiple times, and it all gets merged together. For example: bao &lt;command&gt; &lt;path&gt; metadata&#x3D;key1&#x3D;value1 metadata&#x3D;key2&#x3D;value2 | [optional] |
| **name** | **String** | Name of the group. | [optional] |
| **policies** | **Array&lt;String&gt;** | Policies to be tied to the group. | [optional] |
| **type** | **String** | Type of the group, &#39;internal&#39; or &#39;external&#39;. Defaults to &#39;internal&#39; | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::GroupCreateRequest.new(
  id: null,
  member_entity_ids: null,
  member_group_ids: null,
  metadata: null,
  name: null,
  policies: null,
  type: null
)
```

