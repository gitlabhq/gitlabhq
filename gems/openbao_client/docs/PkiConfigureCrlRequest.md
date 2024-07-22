# OpenbaoClient::PkiConfigureCrlRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auto_rebuild** | **Boolean** | If set to true, enables automatic rebuilding of the CRL | [optional] |
| **auto_rebuild_grace_period** | **String** | The time before the CRL expires to automatically rebuild it, when enabled. Must be shorter than the CRL expiry. Defaults to 12h. | [optional][default to &#39;12h&#39;] |
| **cross_cluster_revocation** | **Boolean** | Whether to enable a global, cross-cluster revocation queue. Must be used with auto_rebuild&#x3D;true. | [optional] |
| **delta_rebuild_interval** | **String** | The time between delta CRL rebuilds if a new revocation has occurred. Must be shorter than the CRL expiry. Defaults to 15m. | [optional][default to &#39;15m&#39;] |
| **disable** | **Boolean** | If set to true, disables generating the CRL entirely. | [optional] |
| **enable_delta** | **Boolean** | Whether to enable delta CRLs between authoritative CRL rebuilds | [optional] |
| **expiry** | **String** | The amount of time the generated CRL should be valid; defaults to 72 hours | [optional][default to &#39;72h&#39;] |
| **ocsp_disable** | **Boolean** | If set to true, ocsp unauthorized responses will be returned. | [optional] |
| **ocsp_expiry** | **String** | The amount of time an OCSP response will be valid (controls the NextUpdate field); defaults to 12 hours | [optional][default to &#39;1h&#39;] |
| **unified_crl** | **Boolean** | If set to true enables global replication of revocation entries, also enabling unified versions of OCSP and CRLs if their respective features are enabled. disable for CRLs and ocsp_disable for OCSP. | [optional][default to false] |
| **unified_crl_on_existing_paths** | **Boolean** | If set to true, existing CRL and OCSP paths will return the unified CRL instead of a response based on cluster-local data | [optional][default to false] |

## Example

```ruby
require 'openbao_client'

instance = OpenbaoClient::PkiConfigureCrlRequest.new(
  auto_rebuild: null,
  auto_rebuild_grace_period: null,
  cross_cluster_revocation: null,
  delta_rebuild_interval: null,
  disable: null,
  enable_delta: null,
  expiry: null,
  ocsp_disable: null,
  ocsp_expiry: null,
  unified_crl: null,
  unified_crl_on_existing_paths: null
)
```

