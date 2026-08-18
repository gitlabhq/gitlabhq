---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 증명 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- `slsa_provenance_statement`라는 이름의 [기능 플래그](../administration/feature_flags/_index.md)와 함께 GitLab 18.5에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/547865). 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

이 API를 사용하여 [증명 증거](../ci/pipeline_security/slsa/level_3/provenance_v1.md)와 상호작용합니다.

## 증명 증거 {#provenance-attestations}

일부 엔드포인트는 응답의 일부로 [Sigstore 번들](https://docs.sigstore.dev/about/bundle/)을 반환합니다. [glab](https://docs.gitlab.com/cli/) 또는 [cosign](https://github.com/sigstore/cosign)을 사용하여 이를 확인할 수 있습니다. 증명에 대한 자세한 내용은 [SLSA 증명 사양](../ci/pipeline_security/slsa/level_3/provenance_v1.md)을 참조하세요.

## 모든 증명 나열 {#list-all-attestations}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205784)(18.5 이상).

{{< /history >}}

지정된 프로젝트 및 SHA-256 해시에 대한 모든 증명을 나열합니다.

```plaintext
GET /:id/attestations/:subject_digest
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `subject_digest` | 문자열 | 예 | 아티팩트의 16진수 인코딩 SHA-256 해시 |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/namespace%2fproject/attestations/5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa"
```

응답 예시:

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

## 증명 다운로드 {#download-an-attestation}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212141)(18.7 이상).

{{< /history >}}

프로젝트 및 증명 IID별로 특정 증명 Sigstore 번들을 다운로드합니다. 번들 자체는 응답 본문에서 반환됩니다. 이 파일 형식에 대한 자세한 내용은 [Sigstore 문서](https://docs.sigstore.dev/about/bundle/)를 참조하세요.

```plaintext
GET /:id/attestations/:attestation_iid/download
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `attestation_iid` | 정수 | 예 | 목록 증명 API 엔드포인트에서 반환된 증명의 IID입니다. |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/72356192/attestations/1/download
```

응답 예시:

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
