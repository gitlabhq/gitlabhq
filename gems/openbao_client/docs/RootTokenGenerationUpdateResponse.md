# OpenbaoClient::RootTokenGenerationUpdateResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **complete** | **Boolean** |  | [optional] |
| **encoded_root_token** | **String** |  | [optional] |
| **encoded_token** | **String** |  | [optional] |
| **nonce** | **String** |  | [optional] |
| **otp** | **String** |  | [optional] |
| **otp_length** | **Integer** |  | [optional] |
| **pgp_fingerprint** | **String** |  | [optional] |
| **progress** | **Integer** |  | [optional] |
| **required** | **Integer** |  | [optional] |
| **started** | **Boolean** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RootTokenGenerationUpdateResponse.new(
  complete: null,
  encoded_root_token: null,
  encoded_token: null,
  nonce: null,
  otp: null,
  otp_length: null,
  pgp_fingerprint: null,
  progress: null,
  required: null,
  started: null
)
```

