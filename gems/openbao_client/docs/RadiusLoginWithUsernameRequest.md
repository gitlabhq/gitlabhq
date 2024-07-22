# OpenbaoClient::RadiusLoginWithUsernameRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **password** | **String** | Password for this user. | [optional] |
| **username** | **String** | Username to be used for login. (POST request body) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RadiusLoginWithUsernameRequest.new(
  password: null,
  username: null
)
```

