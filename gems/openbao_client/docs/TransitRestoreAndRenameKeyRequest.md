# OpenbaoClient::TransitRestoreAndRenameKeyRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **backup** | **String** | Backed up key data to be restored. This should be the output from the &#39;backup/&#39; endpoint. | [optional] |
| **force** | **Boolean** | If set and a key by the given name exists, force the restore operation and override the key. | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::TransitRestoreAndRenameKeyRequest.new(
  backup: null,
  force: null
)
```

