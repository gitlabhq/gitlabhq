# OpenbaoClient::RabbitMqConfigureConnectionRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **connection_uri** | **String** | RabbitMQ Management URI | [optional] |
| **password** | **String** | Password of the provided RabbitMQ management user | [optional] |
| **password_policy** | **String** | Name of the password policy to use to generate passwords for dynamic credentials. | [optional] |
| **username** | **String** | Username of a RabbitMQ management administrator | [optional] |
| **username_template** | **String** | Template describing how dynamic usernames are generated. | [optional] |
| **verify_connection** | **Boolean** | If set, connection_uri is verified by actually connecting to the RabbitMQ management API | [optional][default to true] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RabbitMqConfigureConnectionRequest.new(
  connection_uri: null,
  password: null,
  password_policy: null,
  username: null,
  username_template: null,
  verify_connection: null
)
```

