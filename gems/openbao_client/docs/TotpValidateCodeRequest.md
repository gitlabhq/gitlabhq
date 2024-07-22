# OpenbaoClient::TotpValidateCodeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **code** | **String** | TOTP code to be validated. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TotpValidateCodeRequest.new(
  code: null
)
```

