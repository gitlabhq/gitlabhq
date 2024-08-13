# OpenbaoClient::RekeyAttemptInitializeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **backup** | **Boolean** | Specifies if using PGP-encrypted keys, whether OpenBao should also store a plaintext backup of the PGP-encrypted keys. | [optional] |
| **pgp_keys** | **Array&lt;String&gt;** | Specifies an array of PGP public keys used to encrypt the output unseal keys. Ordering is preserved. The keys must be base64-encoded from their original binary representation. The size of this array must be the same as secret_shares. | [optional] |
| **require_verification** | **Boolean** | Turns on verification functionality | [optional] |
| **secret_shares** | **Integer** | Specifies the number of shares to split the unseal key into. | [optional] |
| **secret_threshold** | **Integer** | Specifies the number of shares required to reconstruct the unseal key. This must be less than or equal secret_shares. If using OpenBao HSM with auto-unsealing, this value must be the same as secret_shares. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RekeyAttemptInitializeRequest.new(
  backup: null,
  pgp_keys: null,
  require_verification: null,
  secret_shares: null,
  secret_threshold: null
)
```

