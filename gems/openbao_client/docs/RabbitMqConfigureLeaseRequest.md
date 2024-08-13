# OpenbaoClient::RabbitMqConfigureLeaseRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **max_ttl** | **Integer** | Duration after which the issued credentials should not be allowed to be renewed | [optional][default to 0] |
| **ttl** | **Integer** | Duration before which the issued credentials needs renewal | [optional][default to 0] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RabbitMqConfigureLeaseRequest.new(
  max_ttl: null,
  ttl: null
)
```

