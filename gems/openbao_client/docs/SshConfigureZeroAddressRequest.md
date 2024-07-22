# OpenbaoClient::SshConfigureZeroAddressRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **roles** | **Array&lt;String&gt;** | [Required] Comma separated list of role names which allows credentials to be requested for any IP address. CIDR blocks previously registered under these roles will be ignored. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshConfigureZeroAddressRequest.new(
  roles: null
)
```

