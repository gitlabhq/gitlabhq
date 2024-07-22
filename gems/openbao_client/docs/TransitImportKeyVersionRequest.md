# OpenbaoClient::TransitImportKeyVersionRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ciphertext** | **String** | The base64-encoded ciphertext of the keys. The AES key should be encrypted using OAEP with the wrapping key and then concatenated with the import key, wrapped by the AES key. | [optional] |
| **hash_function** | **String** | The hash function used as a random oracle in the OAEP wrapping of the user-generated, ephemeral AES key. Can be one of \&quot;SHA1\&quot;, \&quot;SHA224\&quot;, \&quot;SHA256\&quot; (default), \&quot;SHA384\&quot;, or \&quot;SHA512\&quot; | [optional][default to &#39;SHA256&#39;] |
| **public_key** | **String** | The plaintext public key to be imported. If \&quot;ciphertext\&quot; is set, this field is ignored. | [optional] |
| **version** | **Integer** | Key version to be updated, if left empty, a new version will be created unless a private key is specified and the &#39;Latest&#39; key is missing a private key. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitImportKeyVersionRequest.new(
  ciphertext: null,
  hash_function: null,
  public_key: null,
  version: null
)
```

