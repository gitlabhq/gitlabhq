# OpenbaoClient::RadiusLoginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **password** | **String** | Password for this user. | [optional] |
| **urlusername** | **String** | Username to be used for login. (URL parameter) | [optional] |
| **username** | **String** | Username to be used for login. (POST request body) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RadiusLoginRequest.new(
  password: null,
  urlusername: null,
  username: null
)
```

