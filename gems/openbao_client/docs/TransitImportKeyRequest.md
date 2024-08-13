# OpenbaoClient::TransitImportKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allow_plaintext_backup** | **Boolean** | Enables taking a backup of the named key in plaintext format. Once set, this cannot be disabled. | [optional] |
| **allow_rotation** | **Boolean** | True if the imported key may be rotated within OpenBao; false otherwise. | [optional] |
| **auto_rotate_period** | **Integer** | Amount of time the key should live before being automatically rotated. A value of 0 (default) disables automatic rotation for the key. | [optional][default to 0] |
| **ciphertext** | **String** | The base64-encoded ciphertext of the keys. The AES key should be encrypted using OAEP with the wrapping key and then concatenated with the import key, wrapped by the AES key. | [optional] |
| **context** | **String** | Base64 encoded context for key derivation. When reading a key with key derivation enabled, if the key type supports public keys, this will return the public key for the given context. | [optional] |
| **derived** | **Boolean** | Enables key derivation mode. This allows for per-transaction unique keys for encryption operations. | [optional] |
| **exportable** | **Boolean** | Enables keys to be exportable. This allows for all the valid keys in the key ring to be exported. | [optional] |
| **hash_function** | **String** | The hash function used as a random oracle in the OAEP wrapping of the user-generated, ephemeral AES key. Can be one of \&quot;SHA1\&quot;, \&quot;SHA224\&quot;, \&quot;SHA256\&quot; (default), \&quot;SHA384\&quot;, or \&quot;SHA512\&quot; | [optional][default to &#39;SHA256&#39;] |
| **public_key** | **String** | The plaintext PEM public key to be imported. If \&quot;ciphertext\&quot; is set, this field is ignored. | [optional] |
| **type** | **String** | The type of key being imported. Currently, \&quot;aes128-gcm96\&quot; (symmetric), \&quot;aes256-gcm96\&quot; (symmetric), \&quot;ecdsa-p256\&quot; (asymmetric), \&quot;ecdsa-p384\&quot; (asymmetric), \&quot;ecdsa-p521\&quot; (asymmetric), \&quot;ed25519\&quot; (asymmetric), \&quot;rsa-2048\&quot; (asymmetric), \&quot;rsa-3072\&quot; (asymmetric), \&quot;rsa-4096\&quot; (asymmetric) are supported. Defaults to \&quot;aes256-gcm96\&quot;. | [optional][default to &#39;aes256-gcm96&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitImportKeyRequest.new(
  allow_plaintext_backup: null,
  allow_rotation: null,
  auto_rotate_period: null,
  ciphertext: null,
  context: null,
  derived: null,
  exportable: null,
  hash_function: null,
  public_key: null,
  type: null
)
```

