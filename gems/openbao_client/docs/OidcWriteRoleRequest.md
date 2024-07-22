# OpenbaoClient::OidcWriteRoleRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **client_id** | **String** | Optional client_id | [optional] |
| **key** | **String** | The OIDC key to use for generating tokens. The specified key must already exist. |  |
| **template** | **String** | The template string to use for generating tokens. This may be in string-ified JSON or base64 format. | [optional] |
| **ttl** | **Integer** | TTL of the tokens generated against the role. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteRoleRequest.new(
  client_id: null,
  key: null,
  template: null,
  ttl: null
)
```

