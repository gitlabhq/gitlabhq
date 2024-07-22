# OpenbaoClient::TransitCreateKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allow_plaintext_backup** | **Boolean** | Enables taking a backup of the named key in plaintext format. Once set, this cannot be disabled. | [optional] |
| **auto_rotate_period** | **Integer** | Amount of time the key should live before being automatically rotated. A value of 0 (default) disables automatic rotation for the key. | [optional][default to 0] |
| **context** | **String** | Base64 encoded context for key derivation. When reading a key with key derivation enabled, if the key type supports public keys, this will return the public key for the given context. | [optional] |
| **convergent_encryption** | **Boolean** | Whether to support convergent encryption. This is only supported when using a key with key derivation enabled and will require all requests to carry both a context and 96-bit (12-byte) nonce. The given nonce will be used in place of a randomly generated nonce. As a result, when the same context and nonce are supplied, the same ciphertext is generated. It is *very important* when using this mode that you ensure that all nonces are unique for a given context. Failing to do so will severely impact the ciphertext&#39;s security. | [optional] |
| **derived** | **Boolean** | Enables key derivation mode. This allows for per-transaction unique keys for encryption operations. | [optional] |
| **exportable** | **Boolean** | Enables keys to be exportable. This allows for all the valid keys in the key ring to be exported. | [optional] |
| **key_size** | **Integer** | The key size in bytes for the algorithm. Only applies to HMAC and must be no fewer than 32 bytes and no more than 512 | [optional][default to 0] |
| **type** | **String** | The type of key to create. Currently, \&quot;aes128-gcm96\&quot; (symmetric), \&quot;aes256-gcm96\&quot; (symmetric), \&quot;ecdsa-p256\&quot; (asymmetric), \&quot;ecdsa-p384\&quot; (asymmetric), \&quot;ecdsa-p521\&quot; (asymmetric), \&quot;ed25519\&quot; (asymmetric), \&quot;rsa-2048\&quot; (asymmetric), \&quot;rsa-3072\&quot; (asymmetric), \&quot;rsa-4096\&quot; (asymmetric) are supported. Defaults to \&quot;aes256-gcm96\&quot;. | [optional][default to &#39;aes256-gcm96&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitCreateKeyRequest.new(
  allow_plaintext_backup: null,
  auto_rotate_period: null,
  context: null,
  convergent_encryption: null,
  derived: null,
  exportable: null,
  key_size: null,
  type: null
)
```

