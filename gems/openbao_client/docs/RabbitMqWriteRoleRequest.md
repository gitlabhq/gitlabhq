# OpenbaoClient::RabbitMqWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tags** | **String** | Comma-separated list of tags for this role. | [optional] |
| **vhost_topics** | **String** | A nested map of virtual hosts and exchanges to topic permissions. | [optional] |
| **vhosts** | **String** | A map of virtual hosts to permissions. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RabbitMqWriteRoleRequest.new(
  tags: null,
  vhost_topics: null,
  vhosts: null
)
```

