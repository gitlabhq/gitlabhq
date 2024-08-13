# OpenbaoClient::RadiusWriteUserRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policies** | **Array&lt;String&gt;** | Comma-separated list of policies associated to the user. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RadiusWriteUserRequest.new(
  policies: null
)
```

