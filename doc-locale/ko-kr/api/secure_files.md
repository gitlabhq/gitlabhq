---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 수준 보안 파일 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)되었습니다. 기능 플래그 `ci_secure_files` 제거됨.

{{< /history >}}

이 API를 사용하여 프로젝트의 [보안 파일](../ci/secure_files/_index.md)을 관리합니다.

## 프로젝트의 모든 보안 파일 나열 {#list-all-secure-files-for-a-project}

지정된 프로젝트의 모든 보안 파일을 나열합니다.

```plaintext
GET /projects/:project_id/secure_files
```

지원되는 속성:

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files"
```

응답 예시:

```json
[
    {
        "id": 1,
        "name": "myfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": null,
        "metadata": null
    },
    {
        "id": 2,
        "name": "myfile.cer",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aa2",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": "2023-09-21T14:55:59.000Z",
        "metadata": {
            "id":"75949910542696343243264405377658443914",
            "issuer": {
                "C":"US",
                "O":"Apple Inc.",
                "CN":"Apple Worldwide Developer Relations Certification Authority",
                "OU":"G3"
            },
            "subject": {
                "C":"US",
                "O":"Organization Name",
                "CN":"Apple Distribution: Organization Name (ABC123XYZ)",
                "OU":"ABC123XYZ",
                "UID":"ABC123XYZ"
            },
            "expires_at":"2023-09-21T14:55:59.000Z"
        }
    }
]
```

## 보안 파일의 세부 정보 검색 {#retrieve-details-of-a-secure-file}

프로젝트에서 지정된 보안 파일의 세부 정보를 검색합니다.

```plaintext
GET /projects/:project_id/secure_files/:id
```

지원되는 속성:

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수        | 예      | 보안 파일의 ID입니다. |
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```

응답 예시:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## 보안 파일 생성 {#create-a-secure-file}

지정된 프로젝트에서 보안 파일을 생성합니다.

```plaintext
POST /projects/:project_id/secure_files
```

지원되는 속성:

| 속성       | 유형           | 필수 | 설명 |
|-----------------|----------------|----------|-------------|
| `file`          | 파일           | 예      | 업로드되는 파일(5MB 제한)입니다. |
| `name`          | 문자열         | 예      | 업로드되는 파일의 이름입니다. 파일 이름은 프로젝트 내에서 고유해야 합니다. |
| `project_id`    | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files" \
  --form "name=myfile.jks" \
  --form "file=@/path/to/file/myfile.jks"
```

응답 예시:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## 보안 파일 다운로드 {#download-a-secure-file}

프로젝트에서 지정된 보안 파일의 내용을 다운로드합니다.

```plaintext
GET /projects/:project_id/secure_files/:id/download
```

지원되는 속성:

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수        | 예      | 보안 파일의 ID입니다. |
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1/download" \
  --output myfile.jks
```

## 보안 파일 삭제 {#delete-a-secure-file}

프로젝트에서 지정된 보안 파일을 삭제합니다.

```plaintext
DELETE /projects/:project_id/secure_files/:id
```

지원되는 속성:

| 속성    | 유형           | 필수 | 설명 |
|--------------|----------------|----------|-------------|
| `id`         | 정수        | 예      | 보안 파일의 ID입니다. |
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
