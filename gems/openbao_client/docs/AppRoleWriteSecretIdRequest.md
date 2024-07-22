# OpenbaoClient::AppRoleWriteSecretIdRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **after** | **String** | Optional entry to list begin listing after, not required to exist. Only used in list operations. | [optional] |
| **cidr_list** | **Array&lt;String&gt;** | Comma separated string or list of CIDR blocks enforcing secret IDs to be used from specific set of IP addresses. If &#39;bound_cidr_list&#39; is set on the role, then the list of CIDR blocks listed here should be a subset of the CIDR blocks listed on the role. | [optional] |
| **limit** | **Integer** | Optional number of entries to return; defaults to all entries. Only used in list operations. | [optional] |
| **metadata** | **String** | Metadata to be tied to the SecretID. This should be a JSON formatted string containing the metadata in key value pairs. | [optional] |
| **num_uses** | **Integer** | Number of times this SecretID can be used, after which the SecretID expires. Overrides secret_id_num_uses role option when supplied. May not be higher than role&#39;s secret_id_num_uses. | [optional] |
| **token_bound_cidrs** | **Array&lt;String&gt;** | Comma separated string or JSON list of CIDR blocks. If set, specifies the blocks of IP addresses which are allowed to use the generated token. | [optional] |
| **ttl** | **Integer** | Duration in seconds after which this SecretID expires. Overrides secret_id_ttl role option when supplied. May not be longer than role&#39;s secret_id_ttl. | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::AppRoleWriteSecretIdRequest.new(
  after: null,
  cidr_list: null,
  limit: null,
  metadata: null,
  num_uses: null,
  token_bound_cidrs: null,
  ttl: null
)
```

