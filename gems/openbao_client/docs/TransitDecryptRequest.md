# OpenbaoClient::TransitDecryptRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **associated_data** | **String** | When using an AEAD cipher mode, such as AES-GCM, this parameter allows passing associated data (AD/AAD) into the encryption function; this data must be passed on subsequent decryption requests but can be transited in plaintext. On successful decryption, both the ciphertext and the associated data are attested not to have been tampered with. | [optional] |
| **batch_input** | **Array&lt;Object&gt;** | Specifies a list of items to be decrypted in a single batch. When this parameter is set, if the parameters &#39;ciphertext&#39; and &#39;context&#39; are also set, they will be ignored. Any batch output will preserve the order of the batch input. | [optional] |
| **ciphertext** | **String** | The ciphertext to decrypt, provided as returned by encrypt. | [optional] |
| **context** | **String** | Base64 encoded context for key derivation. Required if key derivation is enabled. | [optional] |
| **partial_failure_response_code** | **Integer** | Ordinarily, if a batch item fails to decrypt due to a bad input, but other batch items succeed, the HTTP response code is 400 (Bad Request). Some applications may want to treat partial failures differently. Providing the parameter returns the given response code integer instead of a 400 in this case. If all values fail HTTP 400 is still returned. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitDecryptRequest.new(
  associated_data: null,
  batch_input: null,
  ciphertext: null,
  context: null,
  partial_failure_response_code: null
)
```

