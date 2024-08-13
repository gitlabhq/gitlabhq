# OpenbaoClient::TransitConfigureKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **allow_plaintext_backup** | **Boolean** | Enables taking a backup of the named key in plaintext format. Once set, this cannot be disabled. | [optional] |
| **auto_rotate_period** | **Integer** | Amount of time the key should live before being automatically rotated. A value of 0 disables automatic rotation for the key. | [optional] |
| **deletion_allowed** | **Boolean** | Whether to allow deletion of the key | [optional] |
| **exportable** | **Boolean** | Enables export of the key. Once set, this cannot be disabled. | [optional] |
| **min_decryption_version** | **Integer** | If set, the minimum version of the key allowed to be decrypted. For signing keys, the minimum version allowed to be used for verification. | [optional] |
| **min_encryption_version** | **Integer** | If set, the minimum version of the key allowed to be used for encryption; or for signing keys, to be used for signing. If set to zero, only the latest version of the key is allowed. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitConfigureKeyRequest.new(
  allow_plaintext_backup: null,
  auto_rotate_period: null,
  deletion_allowed: null,
  exportable: null,
  min_decryption_version: null,
  min_encryption_version: null
)
```

