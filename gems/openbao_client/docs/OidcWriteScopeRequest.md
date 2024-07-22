# OpenbaoClient::OidcWriteScopeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **description** | **String** | The description of the scope | [optional] |
| **template** | **String** | The template string to use for the scope. This may be in string-ified JSON or base64 format. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteScopeRequest.new(
  description: null,
  template: null
)
```

