# OpenbaoClient::EntityCreateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **disabled** | **Boolean** | If set true, tokens tied to this identity will not be able to be used (but will not be revoked). | [optional] |
| **id** | **String** | ID of the entity. If set, updates the corresponding existing entity. | [optional] |
| **metadata** | **Object** | Metadata to be associated with the entity. In CLI, this parameter can be repeated multiple times, and it all gets merged together. For example: bao &lt;command&gt; &lt;path&gt; metadata&#x3D;key1&#x3D;value1 metadata&#x3D;key2&#x3D;value2 | [optional] |
| **name** | **String** | Name of the entity | [optional] |
| **policies** | **Array&lt;String&gt;** | Policies to be tied to the entity. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::EntityCreateRequest.new(
  disabled: null,
  id: null,
  metadata: null,
  name: null,
  policies: null
)
```

