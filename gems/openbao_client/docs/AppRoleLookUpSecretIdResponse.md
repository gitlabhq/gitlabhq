# OpenbaoClient::AppRoleLookUpSecretIdResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cidr_list** | **Array&lt;String&gt;** | List of CIDR blocks enforcing secret IDs to be used from specific set of IP addresses. If &#39;bound_cidr_list&#39; is set on the role, then the list of CIDR blocks listed here should be a subset of the CIDR blocks listed on the role. | [optional] |
| **creation_time** | **Time** |  | [optional] |
| **expiration_time** | **Time** |  | [optional] |
| **last_updated_time** | **Time** |  | [optional] |
| **metadata** | **Object** |  | [optional] |
| **secret_id_accessor** | **String** | Accessor of the secret ID | [optional] |
| **secret_id_num_uses** | **Integer** | Number of times a secret ID can access the role, after which the secret ID will expire. | [optional] |
| **secret_id_ttl** | **Integer** | Duration in seconds after which the issued secret ID expires. | [optional] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | List of CIDR blocks. If set, specifies the blocks of IP addresses which can use the returned token. Should be a subset of the token CIDR blocks listed on the role, if any. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleLookUpSecretIdResponse.new(
  cidr_list: null,
  creation_time: null,
  expiration_time: null,
  last_updated_time: null,
  metadata: null,
  secret_id_accessor: null,
  secret_id_num_uses: null,
  secret_id_ttl: null,
  token_bound_cidrs: null
)
```

