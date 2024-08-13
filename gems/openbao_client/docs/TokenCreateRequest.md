# OpenbaoClient::TokenCreateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **display_name** | **String** | Name to associate with this token | [optional] |
| **entity_alias** | **String** | Name of the entity alias to associate with this token | [optional] |
| **explicit_max_ttl** | **String** | Explicit Max TTL of this token | [optional] |
| **id** | **String** | Value for the token | [optional] |
| **lease** | **String** | Use &#39;ttl&#39; instead | [optional] |
| **meta** | **Object** | Arbitrary key&#x3D;value metadata to associate with the token | [optional] |
| **no_default_policy** | **Boolean** | Do not include default policy for this token | [optional] |
| **no_parent** | **Boolean** | Create the token with no parent | [optional] |
| **num_uses** | **Integer** | Max number of uses for this token | [optional] |
| **period** | **String** | Renew period | [optional] |
| **policies** | **Array&lt;String&gt;** | List of policies for the token | [optional] |
| **renewable** | **Boolean** | Allow token to be renewed past its initial TTL up to system/mount maximum TTL | [optional][default to true] |
| **ttl** | **String** | Time to live for this token | [optional] |
| **type** | **String** | Token type | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TokenCreateRequest.new(
  display_name: null,
  entity_alias: null,
  explicit_max_ttl: null,
  id: null,
  lease: null,
  meta: null,
  no_default_policy: null,
  no_parent: null,
  num_uses: null,
  period: null,
  policies: null,
  renewable: null,
  ttl: null,
  type: null
)
```

