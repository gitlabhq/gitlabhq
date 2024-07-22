# OpenbaoClient::PkiConfigureIssuersRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **default** | **String** | Reference (name or identifier) to the default issuer. | [optional] |
| **default_follows_latest_issuer** | **Boolean** | Whether the default issuer should automatically follow the latest generated or imported issuer. Defaults to false. | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureIssuersRequest.new(
  default: null,
  default_follows_latest_issuer: null
)
```

