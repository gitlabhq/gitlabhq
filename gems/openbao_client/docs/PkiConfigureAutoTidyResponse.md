# OpenbaoClient::PkiConfigureAutoTidyResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **acme_account_safety_buffer** | **Integer** | Safety buffer after creation after which accounts lacking orders are revoked | [optional] |
| **enabled** | **Boolean** | Specifies whether automatic tidy is enabled or not | [optional] |
| **interval_duration** | **Integer** | Specifies the duration between automatic tidy operation | [optional] |
| **issuer_safety_buffer** | **Integer** | Issuer safety buffer | [optional] |
| **maintain_stored_certificate_counts** | **Boolean** |  | [optional] |
| **pause_duration** | **String** | Duration to pause between tidying certificates | [optional] |
| **publish_stored_certificate_count_metrics** | **Boolean** |  | [optional] |
| **revocation_queue_safety_buffer** | **Integer** |  | [optional] |
| **safety_buffer** | **Integer** | Safety buffer time duration | [optional] |
| **tidy_acme** | **Boolean** | Tidy Unused Acme Accounts, and Orders | [optional] |
| **tidy_cert_store** | **Boolean** | Specifies whether to tidy up the certificate store | [optional] |
| **tidy_cross_cluster_revoked_certs** | **Boolean** | Tidy the cross-cluster revoked certificate store | [optional] |
| **tidy_expired_issuers** | **Boolean** | Specifies whether tidy expired issuers | [optional] |
| **tidy_move_legacy_ca_bundle** | **Boolean** |  | [optional] |
| **tidy_revocation_queue** | **Boolean** |  | [optional] |
| **tidy_revoked_cert_issuer_associations** | **Boolean** | Specifies whether to associate revoked certificates with their corresponding issuers | [optional] |
| **tidy_revoked_certs** | **Boolean** | Specifies whether to remove all invalid and expired certificates from storage | [optional] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureAutoTidyResponse.new(
  acme_account_safety_buffer: null,
  enabled: null,
  interval_duration: null,
  issuer_safety_buffer: null,
  maintain_stored_certificate_counts: null,
  pause_duration: null,
  publish_stored_certificate_count_metrics: null,
  revocation_queue_safety_buffer: null,
  safety_buffer: null,
  tidy_acme: null,
  tidy_cert_store: null,
  tidy_cross_cluster_revoked_certs: null,
  tidy_expired_issuers: null,
  tidy_move_legacy_ca_bundle: null,
  tidy_revocation_queue: null,
  tidy_revoked_cert_issuer_associations: null,
  tidy_revoked_certs: null
)
```

