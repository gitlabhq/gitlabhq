# OpenbaoClient::SshIssueCertificateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_type** | **String** | Type of certificate to be created; either \&quot;user\&quot; or \&quot;host\&quot;. | [optional][default to &#39;user&#39;] |
| **critical_options** | **Object** | Critical options that the certificate should be signed for. | [optional] |
| **extensions** | **Object** | Extensions that the certificate should be signed for. | [optional] |
| **key_bits** | **Integer** | Specifies the number of bits to use for the generated keys. | [optional][default to 0] |
| **key_id** | **String** | Key id that the created certificate should have. If not specified, the display name of the token will be used. | [optional] |
| **key_type** | **String** | Specifies the desired key type; must be &#x60;rsa&#x60;, &#x60;ed25519&#x60; or &#x60;ec&#x60; | [optional][default to &#39;rsa&#39;] |
| **ttl** | **Integer** | The requested Time To Live for the SSH certificate; sets the expiration date. If not specified the role default, backend default, or system default TTL is used, in that order. Cannot be later than the role max TTL. | [optional] |
| **valid_principals** | **String** | Valid principals, either usernames or hostnames, that the certificate should be signed for. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshIssueCertificateRequest.new(
  cert_type: null,
  critical_options: null,
  extensions: null,
  key_bits: null,
  key_id: null,
  key_type: null,
  ttl: null,
  valid_principals: null
)
```

