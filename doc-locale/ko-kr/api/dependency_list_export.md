---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 종속성 목록 내보내기 API를 사용하여 프로젝트 또는 그룹 종속성의 내보내기 파일을 생성하고 다운로드합니다.
title: 종속성 목록 내보내기 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [종속성 목록](../user/application_security/dependency_list/_index.md)을 내보냅니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

## 종속성 목록 내보내기 만들기 {#create-a-dependency-list-export}

{{< history >}}

- [GitLab 16.4에 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/333463) 되었으며 [플래그](../administration/feature_flags/_index.md) `merge_sbom_api`가 포함되어 있습니다. 기본적으로 활성화됨.
- GitLab 16.7에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/425312)됩니다. 기능 플래그 `merge_sbom_api` 제거됨.

{{< /history >}}

파이프라인에서 감지된 모든 프로젝트 종속성에 대한 CycloneDX JSON 내보내기를 만듭니다.

인증된 사용자가 [read_dependency](../user/custom_roles/abilities.md#vulnerability-management) 권한이 없는 경우 이 요청은 `403 Forbidden` 상태 코드를 반환합니다.

SBOM 내보내기는 내보내기 작성자만 액세스할 수 있습니다.

```plaintext
POST /projects/:id/dependency_list_exports
POST /groups/:id/dependency_list_exports
POST /pipelines/:id/dependency_list_exports
```

| 특성           | 유형              | 필수   | 설명                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | 정수           | 예        | 인증된 사용자가 액세스할 수 있는 프로젝트, 그룹 또는 파이프라인의 ID입니다. |
| `export_type`       | 문자열            | 예        | 내보내기 형식입니다. 수락된 값의 목록은 [내보내기 유형](#export-types)을 참조하세요. |
| `send_email`        | 부울           | 아니오         | `true`로 설정하면 내보내기 완료 시 내보내기를 요청한 사용자에게 이메일 알림을 보냅니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/pipelines/1/dependency_list_exports" \
  --data "export_type=sbom"
```

생성된 종속성 목록 내보내기는 `expires_at` 필드에 지정된 시간에 자동으로 삭제됩니다.

응답 예시:

```json
{
  "id": 2,
  "status": "running",
  "has_finished": false,
  "export_type": "sbom",
  "send_email": false,
  "expires_at": "2025-04-06T09:35:38.746Z",
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/2",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/2/download"
}
```

### 내보내기 유형 {#export-types}

다양한 파일 형식으로 내보내기를 요청할 수 있습니다. 일부 형식은 특정 개체에만 사용할 수 있습니다.

| 내보내기 유형 | 설명 | 사용 가능한 대상 |
| ----------- | ----------- | ------------- |
| `dependency_list` | 종속성을 키-값 쌍으로 나열하는 표준 JSON 개체입니다. | 프로젝트 |
| `sbom` | [CycloneDX](https://cyclonedx.org/) 1.4 자재 명세서 | 파이프라인 |
| `cyclonedx_1_6_json` | [CycloneDX](https://cyclonedx.org/) 1.6 자재 명세서 | 프로젝트 |
| `json_array` | 구성 요소 개체를 포함하는 플랫 JSON 배열입니다. | 그룹 |
| `csv` | 쉼표로 구분된 값(CSV) 문서입니다. | 프로젝트, 그룹 |

## 단일 종속성 목록 내보내기 검색 {#retrieve-a-single-dependency-list-export}

종속성 목록 내보내기를 검색합니다.

```plaintext
GET /dependency_list_exports/:id
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 종속성 목록 내보내기의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2"
```

상태 코드는 종속성 목록 내보내기가 생성 중일 때 `202 Accepted`이고 준비가 완료되면 `200 OK`입니다.

응답 예시:

```json
{
  "id": 4,
  "has_finished": true,
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/4",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/4/download"
}
```

## 종속성 목록 내보내기 다운로드 {#download-dependency-list-export}

단일 종속성 목록 내보내기를 다운로드합니다.

```plaintext
GET /dependency_list_exports/:id/download
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 종속성 목록 내보내기의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2/download"
```

종속성 목록 내보내기가 아직 완료되지 않았거나 찾을 수 없는 경우 응답은 `404 Not Found`입니다.

응답 예시:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
  "version": 1,
  "metadata": {
    "tools": [
      {
        "vendor": "Gitlab",
        "name": "Gemnasium",
        "version": "2.34.0"
      }
    ],
    "authors": [
      {
        "name": "Gitlab",
        "email": "support@gitlab.com"
      }
    ],
    "properties": [
      {
        "name": "gitlab:dependency_scanning:input_file",
        "value": "package-lock.json"
      }
    ]
  },
  "components": [
    {
      "name": "com.fasterxml.jackson.core/jackson-core",
      "purl": "pkg:maven/com.fasterxml.jackson.core/jackson-core@2.9.2",
      "version": "2.9.2",
      "type": "library",
      "licenses": [
        {
          "license": {
            "id": "MIT",
            "url": "https://spdx.org/licenses/MIT.html"
          }
        },
        {
          "license": {
            "id": "BSD-3-Clause",
            "url": "https://spdx.org/licenses/BSD-3-Clause.html"
          }
        }
      ]
    }
  ]
}

```
