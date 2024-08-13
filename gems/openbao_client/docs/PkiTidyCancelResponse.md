# OpenbaoClient::PkiTidyCancelResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **acme_account_deleted_count** | **Integer** | The number of revoked acme accounts removed | [optional] |
| **acme_account_revoked_count** | **Integer** | The number of unused acme accounts revoked | [optional] |
| **acme_account_safety_buffer** | **Integer** | Safety buffer after creation after which accounts lacking orders are revoked | [optional] |
| **acme_orders_deleted_count** | **Integer** | The number of expired, unused acme orders removed | [optional] |
| **cert_store_deleted_count** | **Integer** | The number of certificate storage entries deleted | [optional] |
| **cross_revoked_cert_deleted_count** | **Integer** |  | [optional] |
| **current_cert_store_count** | **Integer** | The number of revoked certificate entries deleted | [optional] |
| **current_revoked_cert_count** | **Integer** | The number of revoked certificate entries deleted | [optional] |
| **error** | **String** | The error message | [optional] |
| **internal_backend_uuid** | **String** |  | [optional] |
| **issuer_safety_buffer** | **Integer** | Issuer safety buffer | [optional] |
| **last_auto_tidy_finished** | **String** | Time the last auto-tidy operation finished | [optional] |
| **message** | **String** | Message of the operation | [optional] |
| **missing_issuer_cert_count** | **Integer** |  | [optional] |
| **pause_duration** | **String** | Duration to pause between tidying certificates | [optional] |
| **revocation_queue_deleted_count** | **Integer** |  | [optional] |
| **revocation_queue_safety_buffer** | **Integer** | Revocation queue safety buffer | [optional] |
| **revoked_cert_deleted_count** | **Integer** | The number of revoked certificate entries deleted | [optional] |
| **safety_buffer** | **Integer** | Safety buffer time duration | [optional] |
| **state** | **String** | One of Inactive, Running, Finished, or Error | [optional] |
| **tidy_acme** | **Boolean** | Tidy Unused Acme Accounts, and Orders | [optional] |
| **tidy_cert_store** | **Boolean** | Tidy certificate store | [optional] |
| **tidy_cross_cluster_revoked_certs** | **Boolean** | Tidy the cross-cluster revoked certificate store | [optional] |
| **tidy_expired_issuers** | **Boolean** | Tidy expired issuers | [optional] |
| **tidy_move_legacy_ca_bundle** | **Boolean** |  | [optional] |
| **tidy_revocation_queue** | **Boolean** |  | [optional] |
| **tidy_revoked_cert_issuer_associations** | **Boolean** | Tidy revoked certificate issuer associations | [optional] |
| **tidy_revoked_certs** | **Boolean** | Tidy revoked certificates | [optional] |
| **time_finished** | **String** | Time the operation finished | [optional] |
| **time_started** | **String** | Time the operation started | [optional] |
| **total_acme_account_count** | **Integer** | Total number of acme accounts iterated over | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiTidyCancelResponse.new(
  acme_account_deleted_count: null,
  acme_account_revoked_count: null,
  acme_account_safety_buffer: null,
  acme_orders_deleted_count: null,
  cert_store_deleted_count: null,
  cross_revoked_cert_deleted_count: null,
  current_cert_store_count: null,
  current_revoked_cert_count: null,
  error: null,
  internal_backend_uuid: null,
  issuer_safety_buffer: null,
  last_auto_tidy_finished: null,
  message: null,
  missing_issuer_cert_count: null,
  pause_duration: null,
  revocation_queue_deleted_count: null,
  revocation_queue_safety_buffer: null,
  revoked_cert_deleted_count: null,
  safety_buffer: null,
  state: null,
  tidy_acme: null,
  tidy_cert_store: null,
  tidy_cross_cluster_revoked_certs: null,
  tidy_expired_issuers: null,
  tidy_move_legacy_ca_bundle: null,
  tidy_revocation_queue: null,
  tidy_revoked_cert_issuer_associations: null,
  tidy_revoked_certs: null,
  time_finished: null,
  time_started: null,
  total_acme_account_count: null
)
```

