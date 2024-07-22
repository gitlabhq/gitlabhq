# OpenbaoClient::SshConfigureCaRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **generate_signing_key** | **Boolean** | Generate SSH key pair internally rather than use the private_key and public_key fields. | [optional][default to true] |
| **key_bits** | **Integer** | Specifies the desired key bits when generating variable-length keys (such as when key_type&#x3D;\&quot;ssh-rsa\&quot;) or which NIST P-curve to use when key_type&#x3D;\&quot;ec\&quot; (256, 384, or 521). | [optional][default to 0] |
| **key_type** | **String** | Specifies the desired key type when generating; could be a OpenSSH key type identifier (ssh-rsa, ecdsa-sha2-nistp256, ecdsa-sha2-nistp384, ecdsa-sha2-nistp521, or ssh-ed25519) or an algorithm (rsa, ec, ed25519). | [optional][default to &#39;ssh-rsa&#39;] |
| **private_key** | **String** | Private half of the SSH key that will be used to sign certificates. | [optional] |
| **public_key** | **String** | Public half of the SSH key that will be used to sign certificates. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::SshConfigureCaRequest.new(
  generate_signing_key: null,
  key_bits: null,
  key_type: null,
  private_key: null,
  public_key: null
)
```

