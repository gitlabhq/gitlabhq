# OpenbaoClient::EntityMergeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **conflicting_alias_ids_to_keep** | **Array&lt;String&gt;** | Alias IDs to keep in case of conflicting aliases. Ignored if no conflicting aliases found | [optional] |
| **force** | **Boolean** | Setting this will follow the &#39;mine&#39; strategy for merging MFA secrets. If there are secrets of the same type both in entities that are merged from and in entity into which all others are getting merged, secrets in the destination will be unaltered. If not set, this API will throw an error containing all the conflicts. | [optional] |
| **from_entity_ids** | **Array&lt;String&gt;** | Entity IDs which need to get merged | [optional] |
| **to_entity_id** | **String** | Entity ID into which all the other entities need to get merged | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::EntityMergeRequest.new(
  conflicting_alias_ids_to_keep: null,
  force: null,
  from_entity_ids: null,
  to_entity_id: null
)
```

