# OpenbaoClient::RekeyAttemptReadProgressResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **backup** | **Boolean** |  | [optional] |
| **n** | **Integer** |  | [optional] |
| **nounce** | **String** |  | [optional] |
| **pgp_fingerprints** | **Array&lt;String&gt;** |  | [optional] |
| **progress** | **Integer** |  | [optional] |
| **required** | **Integer** |  | [optional] |
| **started** | **String** |  | [optional] |
| **t** | **Integer** |  | [optional] |
| **verification_nonce** | **String** |  | [optional] |
| **verification_required** | **Boolean** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::RekeyAttemptReadProgressResponse.new(
  backup: null,
  n: null,
  nounce: null,
  pgp_fingerprints: null,
  progress: null,
  required: null,
  started: null,
  t: null,
  verification_nonce: null,
  verification_required: null
)
```

