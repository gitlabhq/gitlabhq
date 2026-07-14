---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 데이터 관리 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- [GitLab 18.3](https://gitlab.com/gitlab-org/gitlab/-/issues/537707) 에서 [플래그](../../administration/feature_flags/_index.md) `geo_primary_verification_view`로 도입되었습니다. 기본적으로 비활성화됨. 이 기능은 [실험](../../policy/development_stages_support.md) 버전입니다.
- 이 플래그는 GitLab 18.8에서 기본적으로 활성화됩니다.

{{< /history >}}

데이터 관리 API를 사용하여 인스턴스의 데이터를 관리합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

## 모델 정보 검색 {#retrieve-model-information}

인스턴스의 데이터 모델에 대한 정보를 검색합니다. 이 작업은 [실험](../../policy/development_stages_support.md) 버전이며 예고 없이 변경되거나 제거될 수 있습니다.

```plaintext
GET /admin/data_management/:model_name
```

`:model_name` 매개변수는 다음 중 하나여야 합니다:

- `ci_job_artifacts`
- `ci_pipeline_artifacts`
- `ci_secure_files`
- `container_repositories`
- `dependency_proxy_blobs`
- `dependency_proxy_manifests`
- `design_management_repositories`
- `group_wiki_repositories`
- `lfs_objects`
- `merge_request_diffs`
- `packages_debian_project_component_files`
- `packages_nuget_symbols`
- `packages_package_files`
- `pages_deployments`
- `projects`
- `projects_wiki_repositories`
- `snippet_repositories`
- `supply_chain_attestations`
- `terraform_state_versions`
- `uploads`

지원되는 속성:

| 속성        | 유형   | 필수 | 설명                                                                                                                 |
|------------------|--------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`     | 문자열 | 예      | 요청된 모델의 복수형 이름입니다. 위의 `:model_name` 목록에 속해야 합니다.                                    |
| `checksum_state` | 문자열 | 아니요       | 체크섬 상태로 검색합니다. 허용 값: pending, started, succeeded, failed, disabled.                                   |
| `identifiers`    | 배열  | 아니요       | 정수 또는 base64 인코딩된 문자열일 수 있는 요청된 모델의 고유 식별자 배열로 결과를 필터링합니다. |

이 엔드포인트는 모델의 기본 키에서 [키셋 페이지 매김](../rest/_index.md#keyset-based-pagination)을 지원하며, 오름차순 또는 내림차순으로 정렬합니다. 키셋 페이지 매김을 사용하려면 요청에 `pagination=keyset` 매개변수를 추가합니다. 기본적으로 키셋 페이지 매김은 오름차순으로 정렬된 페이지당 20개의 레코드를 로드합니다. 쿼리 매개변수 `sort`를 사용하여 정렬 순서를 수정할 수 있으며, `asc` 또는 `desc` 값을 사용할 수 있습니다. 페이지당 레코드 수를 선택하려면 매개변수 `per_page`를 사용합니다.

성공하면 [`200`](../rest/troubleshooting.md#status-codes)와 모델에 대한 정보를 반환합니다. 다음 응답 속성을 포함합니다:

| 속성              | 유형              | 설명                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | 가능한 경우 Geo 관련 체크섬 정보입니다.                               |
| `created_at`           | 타임스탬프         | 생성 타임스탬프(가능한 경우)입니다.                                              |
| `file_size`            | 정수           | 개체의 크기(가능한 경우)입니다.                                              |
| `model_class`          | 문자열            | 모델의 클래스 이름입니다.                                                       |
| `record_identifier`    | 문자열 또는 정수 | 레코드의 고유 식별자입니다. 정수 또는 base64 인코딩된 문자열일 수 있습니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects?pagination=keyset"
```

응답 예:

```json
[
  {
    "record_identifier": 1,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:10.173Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.643Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  },
  {
    "record_identifier": 2,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:14.402Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.214Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  }
]
```

## 모델 레코드의 체크섬 재계산 {#recalculate-checksums-for-model-records}

제공된 경우 `checksum_state` 및 `identifiers` 매개변수로 필터링된 지정된 모델의 선택된 레코드에 대한 체크섬을 재계산합니다. 요청은 배경 작업을 대기열에 추가하여 재계산을 수행합니다.

```plaintext
PUT /admin/data_management/:model_name/checksum
```

| 속성          | 유형    | 필수 | 설명                                                                                                                 |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`       | 문자열  | 예      | 요청된 모델의 복수형 이름입니다. 위의 `:model_name` 목록에 속해야 합니다.                                    |
| `checksum_state`   | 문자열  | 아니요       | 체크섬 상태로 필터링합니다. 허용 값: pending, started, succeeded, failed, disabled.                                   |
| `identifiers`      | 배열   | 아니요       | 정수 또는 base64 인코딩된 문자열일 수 있는 요청된 모델의 고유 식별자 배열로 레코드를 필터링합니다. |

성공하면 [`200`](../rest/troubleshooting.md#status-codes)와 다음 정보를 포함하는 JSON 응답을 반환합니다:

| 속성 | 유형   | 설명                                       |
|-----------|--------|---------------------------------------------------|
| `message` | 문자열 | 성공 또는 오류에 대한 정보 메시지입니다. |
| `status`  | 문자열 | "success" 또는 "error"일 수 있습니다.                      |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/checksum"
```

응답 예:

```json
{
  "status": "success",
  "message": "Batch update job has been successfully enqueued."
}
```

## 모델 레코드에 대한 정보 검색 {#retrieve-information-about-a-model-record}

지정된 모델 레코드에 대한 정보를 검색합니다.

```plaintext
GET /admin/data_management/:model_name/:id
```

| 속성           | 유형              | 필수 | 설명                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | 문자열            | 예      | 요청된 모델의 복수형 이름입니다. 위의 `:model_name` 목록에 속해야 합니다.    |
| `record_identifier` | 문자열 또는 정수 | 예      | 요청된 모델의 고유 식별자입니다. 정수 또는 base64 인코딩된 문자열일 수 있습니다. |

성공하면 [`200`](../rest/troubleshooting.md#status-codes)와 특정 모델 레코드에 대한 정보를 반환합니다. 다음 응답 속성을 포함합니다:

| 속성              | 유형              | 설명                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | 가능한 경우 Geo 관련 체크섬 정보입니다.                               |
| `created_at`           | 타임스탬프         | 생성 타임스탬프(가능한 경우)입니다.                                              |
| `file_size`            | 정수           | 개체의 크기(가능한 경우)입니다.                                              |
| `model_class`          | 문자열            | 모델의 클래스 이름입니다.                                                       |
| `record_identifier`    | 문자열 또는 정수 | 레코드의 고유 식별자입니다. 정수 또는 base64 인코딩된 문자열일 수 있습니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1"
```

응답 예:

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<object checksum>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```

## 모델 레코드의 체크섬 재계산 {#recalculate-the-checksum-of-a-model-record}

지정된 모델 레코드의 체크섬을 재계산합니다. 체크섬 값은 md5 또는 sha256 알고리즘으로 해시된 쿼리된 모델의 표현입니다.

```plaintext
PUT /admin/data_management/:model_name/:record_identifier/checksum
```

| 속성           | 유형              | 필수 | 설명                                                                                                               |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `model_name`        | 문자열            | 예      | 요청된 모델의 복수형 이름입니다. 위의 `:model_name` 목록에 속해야 합니다.                                  |
| `record_identifier` | 문자열 또는 정수 | 예      | 레코드의 고유 식별자입니다. 정수 또는 base64 인코딩된 문자열(GET 쿼리의 응답에서 가져옴)일 수 있습니다. |

성공하면 [`200`](../rest/troubleshooting.md#status-codes)와 특정 모델 레코드에 대한 정보를 반환합니다.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1/checksum"
```

응답 예:

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<sha256 or md5 string>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```
