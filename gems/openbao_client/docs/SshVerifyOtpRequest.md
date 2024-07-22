# OpenbaoClient::SshVerifyOtpRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **otp** | **String** | [Required] One-Time-Key that needs to be validated | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshVerifyOtpRequest.new(
  otp: null
)
```

