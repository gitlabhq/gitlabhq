# OpenbaoClient::SshSignCertificateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_type** | **String** | Type of certificate to be created; either \&quot;user\&quot; or \&quot;host\&quot;. | [optional][default to &#39;user&#39;] |
| **critical_options** | **Object** | Critical options that the certificate should be signed for. | [optional] |
| **extensions** | **Object** | Extensions that the certificate should be signed for. | [optional] |
| **key_id** | **String** | Key id that the created certificate should have. If not specified, the display name of the token will be used. | [optional] |
| **public_key** | **String** | SSH public key that should be signed. | [optional] |
| **ttl** | **Integer** | The requested Time To Live for the SSH certificate; sets the expiration date. If not specified the role default, backend default, or system default TTL is used, in that order. Cannot be later than the role max TTL. | [optional] |
| **valid_principals** | **String** | Valid principals, either usernames or hostnames, that the certificate should be signed for. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshSignCertificateRequest.new(
  cert_type: null,
  critical_options: null,
  extensions: null,
  key_id: null,
  public_key: null,
  ttl: null,
  valid_principals: null
)
```

