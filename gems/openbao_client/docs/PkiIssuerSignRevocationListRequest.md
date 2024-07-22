# OpenbaoClient::PkiIssuerSignRevocationListRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **crl_number** | **Integer** | The sequence number to be written within the CRL Number extension. | [optional] |
| **delta_crl_base_number** | **Integer** | Using a zero or greater value specifies the base CRL revision number to encode within a Delta CRL indicator extension, otherwise the extension will not be added. | [optional][default to -1] |
| **extensions** | **Array&lt;Object&gt;** | A list of maps containing extensions with keys id (string), critical (bool), value (string) | [optional] |
| **format** | **String** | The format of the combined CRL, can be \&quot;pem\&quot; or \&quot;der\&quot;. If \&quot;der\&quot;, the value will be base64 encoded. Defaults to \&quot;pem\&quot;. | [optional][default to &#39;pem&#39;] |
| **next_update** | **String** | The amount of time the generated CRL should be valid; defaults to 72 hours. | [optional][default to &#39;72h&#39;] |
| **revoked_certs** | **Array&lt;Object&gt;** | A list of maps containing the keys serial_number (string), revocation_time (string), and extensions (map with keys id (string), critical (bool), value (string)) | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiIssuerSignRevocationListRequest.new(
  crl_number: null,
  delta_crl_base_number: null,
  extensions: null,
  format: null,
  next_update: null,
  revoked_certs: null
)
```

