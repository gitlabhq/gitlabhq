---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Attestations API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) in GitLab 18.5 [with a flag](../administration/feature_flags/_index.md) named `slsa_provenance_statement`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Use this API to interact with [provenance attestations](../ci/pipeline_security/slsa/provenance_v1.md).

## Provenance attestations

Some endpoints return [Sigstore bundles](https://docs.sigstore.dev/about/bundle/) as part of the response. You
can verify these using [glab](https://docs.gitlab.com/cli/) or
[cosign](https://github.com/sigstore/cosign). For more information on
provenance, see [SLSA provenance specification](../ci/pipeline_security/slsa/provenance_v1.md)

## List all attestations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205784) in 18.5.

{{< /history >}}

Get a list of all attestations for a specific project and SHA-256 hash.

```plaintext
GET /:id/attestations/:subject_digest
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `subject_digest` | string | yes | The hex encoded SHA-256 hash of the artifact |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/namespace%2fproject/attestations/5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa"
```

Example response:

```json
[
  {
    "id": 1,
    "iid": 1,
    "created_at": "2025-10-07T20:59:27.085Z",
    "updated_at": "2025-10-07T20:59:27.085Z",
    "expire_at": "2027-10-07T20:59:26.967Z",
    "project_id": 1,
    "build_id": 1,
    "status": "success",
    "predicate_kind": "provenance",
    "predicate_type": "https://slsa.dev/provenance/v1",
    "subject_digest": "76c34666f719ef14bd2b124a7db51e9c05e4db2e12a84800296d559064eebe2c",
    "download_url": "https://gitlab.example.com/api/v4/projects/1/attestations/1/download"
  }
]
```

## Download attestation

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212141) in 18.7.

{{< /history >}}

Download a specific provenance Sigstore bundle by project and attestation IID.
The bundle itself will be returned in the response body. For more information
on this file format, please see the relevant [Sigstore documentation](https://docs.sigstore.dev/about/bundle/)

```plaintext
GET /:id/attestations/:attestation_iid/download
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `attestation_iid` | integer | yes | The IID of the attestation, as returned by the list attestations API endpoint. |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/72356192/attestations/1/download
```

Example response:

```json
{
  "mediaType": "application/vnd.dev.sigstore.bundle.v0.3+json",
  "verificationMaterial": {
    "certificate": {
      "rawBytes": "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"
    },
    "tlogEntries": [
[...]
```
