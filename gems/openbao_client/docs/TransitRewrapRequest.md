# OpenbaoClient::TransitRewrapRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **batch_input** | **Array&lt;Object&gt;** | Specifies a list of items to be re-encrypted in a single batch. When this parameter is set, if the parameters &#39;ciphertext&#39; and &#39;context&#39; are also set, they will be ignored. Any batch output will preserve the order of the batch input. | [optional] |
| **ciphertext** | **String** | Ciphertext value to rewrap | [optional] |
| **context** | **String** | Base64 encoded context for key derivation. Required for derived keys. | [optional] |
| **key_version** | **Integer** | The version of the key to use for encryption. Must be 0 (for latest) or a value greater than or equal to the min_encryption_version configured on the key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitRewrapRequest.new(
  batch_input: null,
  ciphertext: null,
  context: null,
  key_version: null
)
```

