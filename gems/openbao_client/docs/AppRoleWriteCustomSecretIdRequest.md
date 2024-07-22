# OpenbaoClient::AppRoleWriteCustomSecretIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cidr_list** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks enforcing secret IDs to be used from specific set of IP addresses. If &#39;bound_cidr_list&#39; is set on the role, then the list of CIDR blocks listed here should be a subset of the CIDR blocks listed on the role. | [optional] |
| **metadata** | **String** | Metadata to be tied to the SecretID. This should be a JSON formatted string containing metadata in key value pairs. | [optional] |
| **num_uses** | **Integer** | Number of times this SecretID can be used, after which the SecretID expires. Overrides secret_id_num_uses role option when supplied. May not be higher than role&#39;s secret_id_num_uses. | [optional] |
| **secret_id** | **String** | SecretID to be attached to the role. | [optional] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks. If set, specifies the blocks of IP addresses which can use the returned token. Should be a subset of the token CIDR blocks listed on the role, if any. | [optional] |
| **ttl** | **Integer** | Duration in seconds after which this SecretID expires. Overrides secret_id_ttl role option when supplied. May not be longer than role&#39;s secret_id_ttl. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteCustomSecretIdRequest.new(
  cidr_list: null,
  metadata: null,
  num_uses: null,
  secret_id: null,
  token_bound_cidrs: null,
  ttl: null
)
```

