# OpenbaoClient::GenerateHashWithAlgorithmRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm** | **String** | Algorithm to use (POST body parameter). Valid values are: * sha2-224 * sha2-256 * sha2-384 * sha2-512 Defaults to \&quot;sha2-256\&quot;. | [optional][default to &#39;sha2-256&#39;] |
| **format** | **String** | Encoding format to use. Can be \&quot;hex\&quot; or \&quot;base64\&quot;. Defaults to \&quot;hex\&quot;. | [optional][default to &#39;hex&#39;] |
| **input** | **String** | The base64-encoded input data | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::GenerateHashWithAlgorithmRequest.new(
  algorithm: null,
  format: null,
  input: null
)
```

