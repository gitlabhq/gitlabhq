---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 러너 컨트롤러 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) 되었으며 [플래그](../administration/feature_flags/_index.md) `FF_USE_JOB_ROUTER`로 명명됩니다. 이 기능은 [실험](../policy/development_stages_support.md) 이며 [GitLab 테스트 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)의 적용을 받습니다.
- `connected` 필드는 GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/591615)되었습니다.

{{< /history >}}

러너 컨트롤러 API를 사용하여 CI/CD 작업 허용 제어를 위한 러너 컨트롤러를 관리할 수 있습니다. 러너 컨트롤러는 작업 라우터에 연결하고 사용자 지정 정책에 대한 작업을 평가하여 허용 또는 거부를 결정합니다. 이 API는 러너 컨트롤러를 생성, 읽기, 업데이트 및 삭제하는 엔드포인트를 제공합니다.

전제 조건:

- GitLab 인스턴스에 대한 관리자(administrator) 액세스 권한이 있어야 합니다.

## 모든 러너 컨트롤러 나열 {#list-all-runner-controllers}

모든 러너 컨트롤러를 나열합니다.

```plaintext
GET /runner_controllers
```

응답:

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형         | 설명 |
|--------------------|--------------|-------------|
| `id`               | 정수      | 러너 컨트롤러의 고유 식별자입니다. |
| `description`      | 문자열       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |
| `created_at`       | 날짜/시간     | 러너 컨트롤러가 생성된 날짜 및 시간입니다. |
| `updated_at`       | 날짜/시간     | 러너 컨트롤러가 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

응답 예시:

```json
[
    {
        "id": 1,
        "description": "Runner controller",
        "state": "enabled",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "description": "Another runner controller",
        "state": "disabled",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## 단일 러너 컨트롤러 검색 {#retrieve-a-single-runner-controller}

ID로 특정 러너 컨트롤러의 세부 정보를 검색합니다.

```plaintext
GET /runner_controllers/:id
```

응답:

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형         | 설명 |
|--------------------|--------------|-------------|
| `id`               | 정수      | 러너 컨트롤러의 고유 식별자입니다. |
| `description`      | 문자열       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |
| `connected`        | 부울      | 러너 컨트롤러가 현재 연결되어 있는지 여부입니다. 러너 컨트롤러는 지난 한 시간 이내에 활성 토큰 중 하나 이상을 사용할 때 연결된 것으로 간주됩니다. |
| `created_at`       | 날짜/시간     | 러너 컨트롤러가 생성된 날짜 및 시간입니다. |
| `updated_at`       | 날짜/시간     | 러너 컨트롤러가 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1"
```

응답 예시:

```json
{
    "id": 1,
    "description": "Runner controller",
    "state": "enabled",
    "connected": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## 러너 컨트롤러 등록 {#register-a-runner-controller}

새 러너 컨트롤러를 등록합니다.

```plaintext
POST /runner_controllers
```

지원되는 속성:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `description`      | 문자열       | 아니요       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 아니요       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |

응답:

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형         | 설명 |
|--------------------|--------------|-------------|
| `id`               | 정수      | 러너 컨트롤러의 고유 식별자입니다. |
| `description`      | 문자열       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |
| `created_at`       | 날짜/시간     | 러너 컨트롤러가 생성된 날짜 및 시간입니다. |
| `updated_at`       | 날짜/시간     | 러너 컨트롤러가 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "New runner controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

응답 예시:

```json
{
    "id": 3,
    "description": "New runner controller",
    "state": "dry_run",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-05T00:00:00Z"
}
```

## 러너 컨트롤러 업데이트 {#update-a-runner-controller}

ID로 기존 러너 컨트롤러의 세부 정보를 업데이트합니다.

```plaintext
PUT /runner_controllers/:id
```

지원되는 속성:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `description`      | 문자열       | 아니요       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 아니요       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형         | 설명 |
|--------------------|--------------|-------------|
| `id`               | 정수      | 러너 컨트롤러의 고유 식별자입니다. |
| `description`      | 문자열       | 러너 컨트롤러에 대한 설명입니다. |
| `state`            | 문자열       | 러너 컨트롤러의 상태입니다. 유효한 값은 `disabled` (기본값), `enabled`, 또는 `dry_run`입니다. |
| `created_at`       | 날짜/시간     | 러너 컨트롤러가 생성된 날짜 및 시간입니다. |
| `updated_at`       | 날짜/시간     | 러너 컨트롤러가 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Updated runner controller", "state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

응답 예시:

```json
{
    "id": 3,
    "description": "Updated runner controller",
    "state": "enabled",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-06T00:00:00Z"
}
```

## 러너 컨트롤러 삭제 {#delete-a-runner-controller}

ID로 특정 러너 컨트롤러를 삭제합니다.

```plaintext
DELETE /runner_controllers/:id
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

## 러너 컨트롤러 범위 {#runner-controller-scopes}

러너 컨트롤러 범위는 러너 컨트롤러가 허용 제어를 위해 평가하는 작업을 정의합니다. 러너 컨트롤러는 허용 요청을 받으려면 최소한 하나의 범위를 가져야 합니다. 범위가 없으면 상태가 `enabled` 또는 `dry_run`인 경우에도 컨트롤러는 비활성 상태로 유지됩니다.

러너 컨트롤러 범위는 두 가지 상호 배타적 범위 지정 유형을 지원합니다:

- **인스턴스 범위**: 러너 컨트롤러는 GitLab 인스턴스의 모든 러너에 대한 작업을 평가합니다.
- **러너 범위**: 러너 컨트롤러는 특정 인스턴스 러너에 대해서만 작업을 평가합니다.

러너 컨트롤러는 인스턴스 범위 또는 하나 이상의 러너 범위를 가질 수 있지만 둘 다는 아닙니다.

> [!note]
> 인스턴스 및 러너 범위만 사용할 수 있습니다. 추가 범위 유형 (그룹, 프로젝트)은 [이슈 586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419)에서 제안됩니다.

### 러너 컨트롤러의 모든 범위 나열 {#list-all-scopes-for-a-runner-controller}

특정 러너 컨트롤러에 대해 구성된 모든 범위를 나열합니다:

```plaintext
GET /runner_controllers/:id/scopes
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | 정수 | 예      | 러너 컨트롤러의 ID입니다.         |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                              | 유형         | 설명                                               |
|----------------------------------------|--------------|-----------------------------------------------------------|
| `instance_level_scopings`              | 객체 배열 | 러너 컨트롤러의 인스턴스 범위 목록입니다. |
| `instance_level_scopings[].created_at` | 날짜/시간     | 범위가 생성된 날짜 및 시간입니다.           |
| `instance_level_scopings[].updated_at` | 날짜/시간     | 범위가 마지막으로 업데이트된 날짜 및 시간입니다.      |
| `runner_level_scopings`                | 객체 배열 | 러너 컨트롤러의 러너 범위 목록입니다.  |
| `runner_level_scopings[].runner_id`    | 정수      | 러너의 ID입니다.                                     |
| `runner_level_scopings[].created_at`   | 날짜/시간     | 범위가 생성된 날짜 및 시간입니다.           |
| `runner_level_scopings[].updated_at`   | 날짜/시간     | 범위가 마지막으로 업데이트된 날짜 및 시간입니다.      |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes"
```

응답 예시:

```json
{
    "instance_level_scopings": [
        {
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
    ],
    "runner_level_scopings": []
}
```

### 인스턴스 범위 추가 {#add-instance-scope}

러너 컨트롤러에 인스턴스 범위를 추가합니다. 추가되면 러너 컨트롤러는 GitLab 인스턴스의 모든 러너에 대한 작업을 평가합니다.

러너 컨트롤러는 하나의 인스턴스 범위만 가질 수 있습니다. 인스턴스 범위가 이미 존재하면 이 엔드포인트는 오류를 반환합니다.

```plaintext
POST /runner_controllers/:id/scopes/instance
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | 정수 | 예      | 러너 컨트롤러의 ID입니다.         |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성               | 유형     | 설명                                          |
|-------------------------|----------|------------------------------------------------------|
| `created_at`            | 날짜/시간 | 범위 지정이 생성된 날짜 및 시간입니다.      |
| `updated_at`            | 날짜/시간 | 범위 지정이 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

응답 예시:

```json
{
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### 인스턴스 범위 제거 {#remove-instance-scope}

러너 컨트롤러에서 인스턴스 범위를 제거합니다.

```plaintext
DELETE /runner_controllers/:id/scopes/instance
```

지원되는 속성:

| 속성     | 유형    | 필수 | 설명                                          |
|---------------|---------|----------|------------------------------------------------------|
| `id`          | 정수 | 예      | 러너 컨트롤러의 ID입니다.                     |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

### 러너 범위 추가 {#add-runner-scope}

{{< history >}}

- GitLab 18.10에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/586417).

{{< /history >}}

러너 컨트롤러에 러너 범위를 추가합니다. 추가되면 러너 컨트롤러는 지정된 러너에 대해서만 작업을 평가합니다.

인스턴스 범위가 있는 러너 컨트롤러는 러너 범위를 가질 수 없습니다. 러너 범위를 추가하기 전에 인스턴스 범위를 제거합니다.

```plaintext
POST /runner_controllers/:id/scopes/runners/:runner_id
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                      |
|-------------|---------|----------|----------------------------------|
| `id`        | 정수 | 예      | 러너 컨트롤러의 ID입니다. |
| `runner_id` | 정수 | 예      | 러너의 ID입니다. 인스턴스 러너여야 합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형     | 설명                                          |
|--------------|----------|------------------------------------------------------|
| `runner_id`  | 정수  | 러너의 ID입니다.                                |
| `created_at` | 날짜/시간 | 범위가 생성된 날짜 및 시간입니다.      |
| `updated_at` | 날짜/시간 | 범위가 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```

응답 예시:

```json
{
    "runner_id": 5,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### 러너 범위 제거 {#remove-runner-scope}

{{< history >}}

- GitLab 18.10에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/586417).

{{< /history >}}

러너 컨트롤러에서 러너 범위를 제거합니다.

```plaintext
DELETE /runner_controllers/:id/scopes/runners/:runner_id
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                      |
|-------------|---------|----------|----------------------------------|
| `id`        | 정수 | 예      | 러너 컨트롤러의 ID입니다. |
| `runner_id` | 정수 | 예      | 러너의 ID입니다.            |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```
