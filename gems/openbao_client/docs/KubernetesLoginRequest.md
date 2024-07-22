# OpenbaoClient::KubernetesLoginRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt** | **String** | A signed JWT for authenticating a service account. This field is required. | [optional] |
| **role** | **String** | Name of the role against which the login is being attempted. This field is required | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::KubernetesLoginRequest.new(
  jwt: null,
  role: null
)
```

