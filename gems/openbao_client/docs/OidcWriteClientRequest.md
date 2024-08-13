# OpenbaoClient::OidcWriteClientRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **access_token_ttl** | **Integer** | The time-to-live for access tokens obtained by the client. | [optional] |
| **assignments** | **Array&lt;String&gt;** | Comma separated string or array of assignment resources. | [optional] |
| **client_type** | **String** | The client type based on its ability to maintain confidentiality of credentials. The following client types are supported: &#39;confidential&#39;, &#39;public&#39;. Defaults to &#39;confidential&#39;. | [optional][default to &#39;confidential&#39;] |
| **id_token_ttl** | **Integer** | The time-to-live for ID tokens obtained by the client. | [optional] |
| **key** | **String** | A reference to a named key resource. Cannot be modified after creation. Defaults to the &#39;default&#39; key. | [optional][default to &#39;default&#39;] |
| **redirect_uris** | **Array&lt;String&gt;** | Comma separated string or array of redirect URIs used by the client. One of these values must exactly match the redirect_uri parameter value used in each authentication request. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::OidcWriteClientRequest.new(
  access_token_ttl: null,
  assignments: null,
  client_type: null,
  id_token_ttl: null,
  key: null,
  redirect_uris: null
)
```

