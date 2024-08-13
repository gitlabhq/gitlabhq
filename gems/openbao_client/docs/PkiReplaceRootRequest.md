# OpenbaoClient::PkiReplaceRootRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **default** | **String** | Reference (name or identifier) to the default issuer. | [optional][default to &#39;next&#39;] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiReplaceRootRequest.new(
  default: null
)
```

