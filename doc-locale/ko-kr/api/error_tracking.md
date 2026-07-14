---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 오류 추적 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트의 오류 추적 기능과 상호 작용합니다. 자세한 정보는 [오류 추적](../operations/error_tracking.md)을 참조하세요.

전제 조건:

- Maintainer 또는 Owner 역할이 있어야 합니다.

## 오류 추적 설정 검색 {#retrieve-error-tracking-settings}

지정된 프로젝트의 오류 추적 설정을 검색합니다.

```plaintext
GET /projects/:id/error_tracking/settings
```

| 속성 | 유형    | 필수 | 설명           |
| --------- | ------- | -------- | --------------------- |
| `id`      | 정수 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

응답 예시:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## 오류 추적 설정 생성 {#create-error-tracking-settings}

{{< history >}}

- [GitLab 15.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393035/).

{{< /history >}}

지정된 프로젝트의 오류 추적 설정을 생성합니다.

> [!note]
> 이 API는 [통합 오류 추적](../operations/integrated_error_tracking.md)을 사용할 때만 사용 가능합니다.

```plaintext
PUT /projects/:id/error_tracking/settings
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명                                                                                                                                                     |
| ------------ | ------- |----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`         | 정수 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths).                                            |
| `active`     | 부울 | 예      | `true`을 전달하여 오류 추적 설정을 활성화하거나 `false`을 전달하여 비활성화합니다.                                                                        |
| `integrated` | 부울 | 예      | `true`을 전달하여 통합 오류 추적 백엔드를 활성화합니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true&integrated=true"
```

응답 예시:

```json
{
  "active": true,
  "project_name": null,
  "sentry_external_url": null,
  "api_url": null,
  "integrated": true
}
```

## 오류 추적 프로젝트 설정 업데이트 {#update-error-tracking-project-settings}

지정된 프로젝트의 오류 추적 설정을 업데이트합니다.

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| 속성    | 유형    | 필수 | 설명           |
| ------------ | ------- | -------- | --------------------- |
| `id`         | 정수 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `active`     | 부울 | 예      | `true`을 전달하여 이미 구성된 오류 추적 설정을 활성화하거나 `false`을 전달하여 비활성화합니다. |
| `integrated` | 부울 | 아니요       | `true`을 전달하여 통합 오류 추적 백엔드를 활성화합니다. |

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

응답 예시:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## 모든 프로젝트 클라이언트 키 나열 {#list-all-project-client-keys}

지정된 프로젝트의 모든 [통합 오류 추적](../operations/integrated_error_tracking.md) 클라이언트 키를 나열합니다.

```plaintext
GET /projects/:id/error_tracking/client_keys
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "active": true,
    "public_key": "glet_aa77551d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  },
  {
    "id": 3,
    "active": true,
    "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  }
]
```

## 클라이언트 키 생성 {#create-a-client-key}

지정된 프로젝트의 [통합 오류 추적](../operations/integrated_error_tracking.md) 클라이언트 키를 생성합니다. 공개 키 속성은 자동으로 생성됩니다.

```plaintext
POST /projects/:id/error_tracking/client_keys
```

| 속성  | 유형 | 필수 | 설명 |
| ---------  | ---- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

응답 예시:

```json
{
  "id": 3,
  "active": true,
  "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
  "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
}
```

## 클라이언트 키 삭제 {#delete-a-client-key}

지정된 프로젝트에서 [통합 오류 추적](../operations/integrated_error_tracking.md) 클라이언트 키를 삭제합니다.

```plaintext
DELETE /projects/:id/error_tracking/client_keys/:key_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `key_id`  | 정수 | 예 | 클라이언트 키의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys/13"
```
