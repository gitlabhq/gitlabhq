# OpenbaoClient::TransitTrimKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **min_available_version** | **Integer** | The minimum available version for the key ring. All versions before this version will be permanently deleted. This value can at most be equal to the lesser of &#39;min_decryption_version&#39; and &#39;min_encryption_version&#39;. This is not allowed to be set when either &#39;min_encryption_version&#39; or &#39;min_decryption_version&#39; is set to zero. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitTrimKeyRequest.new(
  min_available_version: null
)
```

