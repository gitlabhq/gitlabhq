---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 러너 컨트롤러 토큰 API
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
- `last_used_at` 필드는 GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/591615)되었습니다.

{{< /history >}}

러너 컨트롤러 토큰 API를 사용하면 러너 컨트롤러의 인증 토큰을 관리할 수 있습니다. 러너 컨트롤러는 이러한 토큰을 사용하여 GitLab 인스턴스로 인증하고 러너를 관리합니다. 이 API는 토큰을 생성, 나열, 회전 및 취소하는 엔드포인트를 제공합니다.

전제 조건:

- GitLab 인스턴스에 대한 관리자(administrator) 액세스 권한이 있어야 합니다.

## 모든 러너 컨트롤러 토큰 나열 {#list-all-runner-controller-tokens}

모든 러너 컨트롤러 토큰을 나열합니다.

```plaintext
GET /runner_controllers/:id/tokens
```

매개변수:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `id`               | 정수      | 예      | 러너 컨트롤러의 ID입니다. |

응답:

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 정수 | 러너 컨트롤러 토큰의 고유 식별자입니다. |
| `runner_controller_id`  | 정수 | 관련 러너 컨트롤러의 ID입니다. |
| `description`           | 문자열  | 토큰에 대한 설명입니다. |
| `last_used_at`          | 날짜/시간| 토큰이 마지막으로 사용된 날짜 및 시간입니다. |
| `created_at`            | 날짜/시간| 토큰이 생성된 날짜 및 시간입니다. |
| `updated_at`            | 날짜/시간| 토큰이 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

응답 예시:

```json
[
    {
        "id": 1,
        "runner_controller_id": 1,
        "description": "Token for runner controller",
        "last_used_at": "2026-01-05T00:00:00Z",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "runner_controller_id": 1,
        "description": "Another token for runner controller",
        "last_used_at": "2026-01-05T00:00:00Z",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## 단일 러너 컨트롤러 토큰 검색 {#retrieve-a-single-runner-controller-token}

특정 러너 컨트롤러 토큰의 세부 정보를 ID로 검색합니다.

```plaintext
GET /runner_controllers/:id/tokens/:token_id
```

매개변수:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `id`               | 정수      | 예      | 러너 컨트롤러의 ID입니다. |
| `token_id`         | 정수      | 예      | 러너 컨트롤러 토큰의 ID입니다. |

응답:

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 필드가 포함됩니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 정수 | 러너 컨트롤러 토큰의 고유 식별자입니다. |
| `runner_controller_id`  | 정수 | 관련 러너 컨트롤러의 ID입니다. |
| `description`           | 문자열  | 토큰에 대한 설명입니다. |
| `last_used_at`          | 날짜/시간| 토큰이 마지막으로 사용된 날짜 및 시간입니다. |
| `created_at`            | 날짜/시간| 토큰이 생성된 날짜 및 시간입니다. |
| `updated_at`            | 날짜/시간| 토큰이 마지막으로 업데이트된 날짜 및 시간입니다. |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

응답 예시:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": "2026-01-05T00:00:00Z",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## 러너 컨트롤러 토큰 생성 {#create-a-runner-controller-token}

새로운 러너 컨트롤러 토큰을 생성합니다.

```plaintext
POST /runner_controllers/:id/tokens
```

매개변수:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `id`               | 정수      | 예      | 러너 컨트롤러의 ID입니다. |

지원되는 속성:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `description`      | 문자열       | 예      | 토큰에 대한 설명입니다. |

응답:

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 속성이 포함됩니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 정수 | 러너 컨트롤러 토큰의 고유 식별자입니다. |
| `runner_controller_id`  | 정수 | 관련 러너 컨트롤러의 ID입니다. |
| `description`           | 문자열  | 토큰에 대한 설명입니다. |
| `last_used_at`          | 날짜/시간| 토큰이 마지막으로 사용된 날짜 및 시간입니다. |
| `created_at`            | 날짜/시간| 토큰이 생성된 날짜 및 시간입니다. |
| `updated_at`            | 날짜/시간| 토큰이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `token`                 | 문자열  | 인증에 사용되는 실제 토큰 값입니다. |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "Content-Type: application/json" \
    --data '{"description": "Token for runner controller"}' \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

응답 예시:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```

## 러너 컨트롤러 토큰 취소 {#revoke-a-runner-controller-token}

기존 러너 컨트롤러 토큰을 취소합니다.

```plaintext
DELETE /runner_controllers/:id/tokens/:token_id
```

매개변수:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `id`               | 정수      | 예      | 러너 컨트롤러의 ID입니다. |
| `token_id`         | 정수      | 예      | 러너 컨트롤러 토큰의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

## 러너 컨트롤러 토큰 회전 {#rotate-a-runner-controller-token}

기존 러너 컨트롤러 토큰을 회전합니다.

```plaintext
POST /runner_controllers/:id/tokens/:token_id/rotate
```

매개변수:

| 속성          | 유형         | 필수 | 설명 |
|--------------------|--------------|----------|-------------|
| `id`               | 정수      | 예      | 러너 컨트롤러의 ID입니다. |
| `token_id`         | 정수      | 예      | 러너 컨트롤러 토큰의 ID입니다. |

응답:

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 속성이 포함됩니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 정수 | 러너 컨트롤러 토큰의 고유 식별자입니다. |
| `runner_controller_id`  | 정수 | 관련 러너 컨트롤러의 ID입니다. |
| `description`           | 문자열  | 토큰에 대한 설명입니다. |
| `last_used_at`          | 날짜/시간| 토큰이 마지막으로 사용된 날짜 및 시간입니다. |
| `created_at`            | 날짜/시간| 토큰이 생성된 날짜 및 시간입니다. |
| `updated_at`            | 날짜/시간| 토큰이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `token`                 | 문자열  | 인증에 사용되는 실제 토큰 값입니다. |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id/rotate"
```

응답 예시:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": "2026-01-05T00:00:00Z",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```
