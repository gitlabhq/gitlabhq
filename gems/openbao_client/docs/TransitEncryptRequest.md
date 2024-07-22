# OpenbaoClient::TransitEncryptRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **associated_data** | **String** | When using an AEAD cipher mode, such as AES-GCM, this parameter allows passing associated data (AD/AAD) into the encryption function; this data must be passed on subsequent decryption requests but can be transited in plaintext. On successful decryption, both the ciphertext and the associated data are attested not to have been tampered with. | [optional] |
| **batch_input** | **Array&lt;Object&gt;** | Specifies a list of items to be encrypted in a single batch. When this parameter is set, if the parameters &#39;plaintext&#39; and &#39;context&#39; are also set, they will be ignored. Any batch output will preserve the order of the batch input. | [optional] |
| **context** | **String** | Base64 encoded context for key derivation. Required if key derivation is enabled | [optional] |
| **convergent_encryption** | **Boolean** | This parameter will only be used when a key is expected to be created. Whether to support convergent encryption. This is only supported when using a key with key derivation enabled and will require all requests to carry both a context and 96-bit (12-byte) nonce. The given nonce will be used in place of a randomly generated nonce. As a result, when the same context and nonce are supplied, the same ciphertext is generated. It is *very important* when using this mode that you ensure that all nonces are unique for a given context. Failing to do so will severely impact the ciphertext&#39;s security. | [optional] |
| **key_version** | **Integer** | The version of the key to use for encryption. Must be 0 (for latest) or a value greater than or equal to the min_encryption_version configured on the key. | [optional] |
| **partial_failure_response_code** | **Integer** | Ordinarily, if a batch item fails to encrypt due to a bad input, but other batch items succeed, the HTTP response code is 400 (Bad Request). Some applications may want to treat partial failures differently. Providing the parameter returns the given response code integer instead of a 400 in this case. If all values fail HTTP 400 is still returned. | [optional] |
| **plaintext** | **String** | Base64 encoded plaintext value to be encrypted | [optional] |
| **type** | **String** | This parameter is required when encryption key is expected to be created. When performing an upsert operation, the type of key to create. Currently, \&quot;aes128-gcm96\&quot; (symmetric) and \&quot;aes256-gcm96\&quot; (symmetric) are the only types supported. Defaults to \&quot;aes256-gcm96\&quot;. | [optional][default to &#39;aes256-gcm96&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitEncryptRequest.new(
  associated_data: null,
  batch_input: null,
  context: null,
  convergent_encryption: null,
  key_version: null,
  partial_failure_response_code: null,
  plaintext: null,
  type: null
)
```

