# OpenbaoClient::RootTokenGenerationUpdateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** | Specifies a single unseal key share. | [optional] |
| **nonce** | **String** | Specifies the nonce of the attempt. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RootTokenGenerationUpdateRequest.new(
  key: null,
  nonce: null
)
```

