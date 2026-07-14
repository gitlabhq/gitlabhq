---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 모델 레지스트리 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 머신러닝 [모델 레지스트리](../user/project/ml/model_registry/_index.md)와 상호작용합니다.

`:model_version_id` 속성은 각 엔드포인트에서 모델 버전 ID 또는 후보 실행 ID를 허용합니다. 자세한 내용은 [모델 버전 및 후보 ID](#model-version-and-candidate-ids)를 참조하세요.

## 머신러닝 모델 패키지 파일 다운로드 {#download-a-machine-learning-model-package-file}

머신러닝 모델 패키지에서 지정된 파일을 다운로드합니다.

```plaintext
GET /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

지원되는 속성:

| 속성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `model_version_id` | 정수 또는 문자열 | 예      | 모델 버전 ID 또는 후보 실행 ID입니다. [모델 버전 및 후보 ID](#model-version-and-candidate-ids)를 참조하세요. |
| `file_name`        | 문자열            | 예      | 파일 이름입니다. |
| `path`             | 문자열            | 아니요       | 파일의 디렉터리 경로입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 파일 내용을 반환합니다.

요청 예시:

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt"
```

디렉터리 경로를 사용한 요청 예시:

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/foo.txt"
```

## 모델 패키지 파일 업로드 {#upload-a-model-package-file}

머신러닝 모델 패키지에 파일을 업로드합니다.

### 업로드 승인 {#authorize-the-upload}

머신러닝 모델 패키지에 파일 업로드를 승인합니다.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name/authorize
```

지원되는 속성:

| 속성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `model_version_id` | 정수 또는 문자열 | 예      | 모델 버전 ID 또는 후보 실행 ID입니다. [모델 버전 및 후보 ID](#model-version-and-candidate-ids)를 참조하세요. |
| `file_name`        | 문자열            | 예      | 파일 이름입니다. |
| `path`             | 문자열            | 아니요       | 파일의 디렉터리 경로입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl/authorize"
```

### 파일 전송 {#send-the-file}

머신러닝 모델 패키지에 파일을 업로드합니다.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

지원되는 속성:

| 속성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `model_version_id` | 정수 또는 문자열 | 예      | 모델 버전 ID 또는 후보 실행 ID입니다. [모델 버전 및 후보 ID](#model-version-and-candidate-ids)를 참조하세요. |
| `file_name`        | 문자열            | 예      | 파일 이름입니다. |
| `path`             | 문자열            | 아니요       | 파일의 디렉터리 경로입니다. |
| `file`             | 파일              | 예      | 업로드할 파일입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl"
```

디렉터리 경로를 사용한 요청 예시:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/model.pkl"
```

## 모델 버전 및 후보 ID {#model-version-and-candidate-ids}

`:model_version_id` 속성은 모델 버전 ID 또는 후보 실행 ID를 허용합니다.

모델 버전 ID를 찾으려면 모델 버전 페이지의 URL을 확인하세요. 예를 들어 `https://gitlab.example.com/my-namespace/my-project/-/ml/models/1/versions/5`에서 모델 버전 ID는 `5`입니다.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/5/files/model.pkl"
```

후보 실행 ID를 사용하려면 후보의 내부 ID 앞에 `candidate:`을 붙입니다. 예를 들어 `https://gitlab.example.com/my-namespace/my-project/-/ml/candidates/5`에서 `:model_version_id`의 값은 `candidate:5`입니다.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/candidate:5/files/model.pkl"
```
