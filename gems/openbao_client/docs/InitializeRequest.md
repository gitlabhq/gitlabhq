# OpenbaoClient::InitializeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pgp_keys** | **Array&lt;String&gt;** | Specifies an array of PGP public keys used to encrypt the output unseal keys. Ordering is preserved. The keys must be base64-encoded from their original binary representation. The size of this array must be the same as &#x60;secret_shares&#x60;. | [optional] |
| **recovery_pgp_keys** | **Array&lt;String&gt;** | Specifies an array of PGP public keys used to encrypt the output recovery keys. Ordering is preserved. The keys must be base64-encoded from their original binary representation. The size of this array must be the same as &#x60;recovery_shares&#x60;. | [optional] |
| **recovery_shares** | **Integer** | Specifies the number of shares to split the recovery key into. | [optional] |
| **recovery_threshold** | **Integer** | Specifies the number of shares required to reconstruct the recovery key. This must be less than or equal to &#x60;recovery_shares&#x60;. | [optional] |
| **root_token_pgp_key** | **String** | Specifies a PGP public key used to encrypt the initial root token. The key must be base64-encoded from its original binary representation. | [optional] |
| **secret_shares** | **Integer** | Specifies the number of shares to split the unseal key into. | [optional] |
| **secret_threshold** | **Integer** | Specifies the number of shares required to reconstruct the unseal key. This must be less than or equal secret_shares. If using OpenBao HSM with auto-unsealing, this value must be the same as &#x60;secret_shares&#x60;. | [optional] |
| **stored_shares** | **Integer** | Specifies the number of shares that should be encrypted by the HSM and stored for auto-unsealing. Currently must be the same as &#x60;secret_shares&#x60;. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::InitializeRequest.new(
  pgp_keys: null,
  recovery_pgp_keys: null,
  recovery_shares: null,
  recovery_threshold: null,
  root_token_pgp_key: null,
  secret_shares: null,
  secret_threshold: null,
  stored_shares: null
)
```

