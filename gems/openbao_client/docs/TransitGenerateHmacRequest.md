# OpenbaoClient::TransitGenerateHmacRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **algorithm** | **String** | Algorithm to use (POST body parameter). Valid values are: * sha2-224 * sha2-256 * sha2-384 * sha2-512 * sha3-224 * sha3-256 * sha3-384 * sha3-512 Defaults to \&quot;sha2-256\&quot;. | [optional][default to &#39;sha2-256&#39;] |
| **batch_input** | **Array&lt;Object&gt;** | Specifies a list of items to be processed in a single batch. When this parameter is set, if the parameter &#39;input&#39; is also set, it will be ignored. Any batch output will preserve the order of the batch input. | [optional] |
| **input** | **String** | The base64-encoded input data | [optional] |
| **key_version** | **Integer** | The version of the key to use for generating the HMAC. Must be 0 (for latest) or a value greater than or equal to the min_encryption_version configured on the key. | [optional] |
| **urlalgorithm** | **String** | Algorithm to use (POST URL parameter) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitGenerateHmacRequest.new(
  algorithm: null,
  batch_input: null,
  input: null,
  key_version: null,
  urlalgorithm: null
)
```

