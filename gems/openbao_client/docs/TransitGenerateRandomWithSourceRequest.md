# OpenbaoClient::TransitGenerateRandomWithSourceRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bytes** | **Integer** | The number of bytes to generate (POST body parameter). Defaults to 32 (256 bits). | [optional][default to 32] |
| **format** | **String** | Encoding format to use. Can be \&quot;hex\&quot; or \&quot;base64\&quot;. Defaults to \&quot;base64\&quot;. | [optional][default to &#39;base64&#39;] |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitGenerateRandomWithSourceRequest.new(
  bytes: null,
  format: null,
  urlbytes: null
)
```

