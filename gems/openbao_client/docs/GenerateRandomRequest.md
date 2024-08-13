# OpenbaoClient::GenerateRandomRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bytes** | **Integer** | The number of bytes to generate (POST body parameter). Defaults to 32 (256 bits). | [optional][default to 32] |
| **format** | **String** | Encoding format to use. Can be \&quot;hex\&quot; or \&quot;base64\&quot;. Defaults to \&quot;base64\&quot;. | [optional][default to &#39;base64&#39;] |
| **source** | **String** | Which system to source random data from, ether \&quot;platform\&quot;, \&quot;seal\&quot;, or \&quot;all\&quot;. | [optional][default to &#39;platform&#39;] |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::GenerateRandomRequest.new(
  bytes: null,
  format: null,
  source: null,
  urlbytes: null
)
```

