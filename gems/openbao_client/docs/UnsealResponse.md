# OpenbaoClient::UnsealResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **build_date** | **String** |  | [optional] |
| **cluster_id** | **String** |  | [optional] |
| **cluster_name** | **String** |  | [optional] |
| **initialized** | **Boolean** |  | [optional] |
| **migration** | **Boolean** |  | [optional] |
| **n** | **Integer** |  | [optional] |
| **nonce** | **String** |  | [optional] |
| **progress** | **Integer** |  | [optional] |
| **recovery_seal** | **Boolean** |  | [optional] |
| **sealed** | **Boolean** |  | [optional] |
| **storage_type** | **String** |  | [optional] |
| **t** | **Integer** |  | [optional] |
| **type** | **String** |  | [optional] |
| **version** | **String** |  | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::UnsealResponse.new(
  build_date: null,
  cluster_id: null,
  cluster_name: null,
  initialized: null,
  migration: null,
  n: null,
  nonce: null,
  progress: null,
  recovery_seal: null,
  sealed: null,
  storage_type: null,
  t: null,
  type: null,
  version: null
)
```

