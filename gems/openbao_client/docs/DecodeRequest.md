# OpenbaoClient::DecodeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **encoded_token** | **String** | Specifies the encoded token (result from generate-root). | [optional] |
| **otp** | **String** | Specifies the otp code for decode. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::DecodeRequest.new(
  encoded_token: null,
  otp: null
)
```

