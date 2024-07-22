# OpenbaoClient::SshGenerateCredentialsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ip** | **String** | [Required] IP of the remote host | [optional] |
| **username** | **String** | [Optional] Username in remote host | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshGenerateCredentialsRequest.new(
  ip: null,
  username: null
)
```

