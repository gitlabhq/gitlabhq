---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시스템 훅 API
description: "웹후크 REST API를 사용하여 시스템 훅을 설정하고 관리합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 API를 사용하여 [시스템 훅](../administration/system_hooks.md)을 관리합니다. 시스템 훅은 그룹의 모든 프로젝트와 하위 그룹에 영향을 미치는 [그룹 웹후크](group_webhooks.md) 와 단일 프로젝트로 제한되는 [프로젝트 웹후크](project_webhooks.md)와 다릅니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

## 모든 시스템 훅 나열 {#list-all-system-hooks}

모든 시스템 훅을 나열합니다.

```plaintext
GET /hooks
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks"
```

응답 예시:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## 시스템 훅 검색 {#retrieve-system-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `token_present` 및 `signing_token_present` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325)되었습니다.

{{< /history >}}

ID로 시스템 훅을 검색합니다.

```plaintext
GET /hooks/:id
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 훅의 ID입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

응답 예시:

```json
{
  "id": 1,
  "url": "https://gitlab.example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "created_at": "2016-10-31T12:32:15.192Z",
  "push_events": true,
  "tag_push_events": false,
  "merge_requests_events": true,
  "repository_update_events": true,
  "enable_ssl_verification": true,
  "url_variables": [],
  "token_present": false,
  "signing_token_present": false
}
```

## 새 시스템 훅 추가 {#add-new-system-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `signing_token` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) 되었으며 [플래그](../administration/feature_flags/_index.md)라는 이름으로 `webhook_signing_token`입니다. 기본적으로 활성화됨.
- 기능 플래그 `webhook_signing_token`이(가) GitLab 19.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)되었습니다.

{{< /history >}}

새 시스템 훅을 추가합니다.

```plaintext
POST /hooks
```

| 속성                   | 유형    | 필수 | 설명 |
|-----------------------------|---------|----------|-------------|
| `url`                       | 문자열  | 예      | 훅 URL입니다. |
| `branch_filter_strategy`    | 문자열  | 아니요       | 푸시 이벤트를 브랜치별로 필터링합니다. 가능한 값은 `wildcard` (기본값), `regex`, `all_branches`입니다. |
| `description`               | 문자열  | 아니요       | 훅의 설명입니다. |
| `enable_ssl_verification`   | 부울 | 아니요       | 훅을 트리거할 때 SSL 검증을 수행합니다. |
| `merge_requests_events`     | 부울 | 아니요       | 머지 리퀘스트 이벤트에서 훅을 트리거합니다. |
| `name`                      | 문자열  | 아니요       | 훅의 이름입니다. |
| `push_events`               | 부울 | 아니요       | true인 경우 훅이 푸시 이벤트에서 발생합니다. |
| `push_events_branch_filter` | 문자열  | 아니요       | 일치하는 브랜치에 대해서만 푸시 이벤트에서 훅을 트리거합니다. |
| `repository_update_events`  | 부울 | 아니요       | 리포지토리 업데이트 이벤트에서 훅을 트리거합니다. |
| `signing_token`             | 문자열  | 아니요       | `webhook-signature` 헤더를 계산하는 데 사용되는 HMAC 서명 토큰입니다. `whsec_<base64>` 형식이어야 하며 32바이트 키를 인코딩합니다. 응답에서 반환되지 않습니다. |
| `tag_push_events`           | 부울 | 아니요       | true인 경우 훅이 새 태그가 푸시될 때 발생합니다. |
| `token`                     | 문자열  | 아니요       | 수신한 페이로드를 검증하는 시크릿 토큰입니다. 응답에서 반환되지 않습니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
```

응답 예시:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## 시스템 훅 업데이트 {#update-system-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `signing_token` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) 되었으며 [플래그](../administration/feature_flags/_index.md)라는 이름으로 `webhook_signing_token`입니다. 기본적으로 활성화됨.
- 기능 플래그 `webhook_signing_token`이(가) GitLab 19.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)되었습니다.

{{< /history >}}

기존 시스템 훅을 업데이트합니다.

```plaintext
PUT /hooks/:hook_id
```

| 속성                   | 유형    | 필수 | 설명 |
|-----------------------------|---------|----------|-------------|
| `hook_id`                   | 정수 | 예      | 시스템 훅의 ID입니다. |
| `branch_filter_strategy`    | 문자열  | 아니요       | 푸시 이벤트를 브랜치별로 필터링합니다. 가능한 값은 `wildcard` (기본값), `regex`, `all_branches`입니다. |
| `description`               | 문자열  | 아니요       | 훅의 설명입니다. |
| `enable_ssl_verification`   | 부울 | 아니요       | 훅을 트리거할 때 SSL 검증을 수행합니다. |
| `merge_requests_events`     | 부울 | 아니요       | 머지 리퀘스트 이벤트에서 훅을 트리거합니다. |
| `name`                      | 문자열  | 아니요       | 훅의 이름입니다. |
| `push_events`               | 부울 | 아니요       | true인 경우 훅이 푸시 이벤트에서 발생합니다. |
| `push_events_branch_filter` | 문자열  | 아니요       | 일치하는 브랜치에 대해서만 푸시 이벤트에서 훅을 트리거합니다. |
| `repository_update_events`  | 부울 | 아니요       | 리포지토리 업데이트 이벤트에서 훅을 트리거합니다. |
| `signing_token`             | 문자열  | 아니요       | `webhook-signature` 헤더를 계산하는 데 사용되는 HMAC 서명 토큰입니다. `whsec_<base64>` 형식이어야 하며 32바이트 키를 인코딩합니다. 응답에서 반환되지 않습니다. |
| `tag_push_events`           | 부울 | 아니요       | true인 경우 훅이 새 태그가 푸시될 때 발생합니다. |
| `token`                     | 문자열  | 아니요       | 수신한 페이로드를 검증하는 시크릿 토큰입니다. 응답에서 반환되지 않습니다. |
| `url`                       | 문자열  | 아니요       | 훅 URL입니다. |

## 시스템 훅 테스트 {#test-system-hook}

모의 데이터로 시스템 훅을 실행합니다.

```plaintext
POST /hooks/:id
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 훅의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

응답은 항상 모의 데이터입니다:

```json
{
   "project_id" : 1,
   "owner_email" : "example@gitlabhq.com",
   "owner_name" : "Someone",
   "name" : "Ruby",
   "path" : "ruby",
   "event_name" : "project_create"
}
```

## 시스템 훅 삭제 {#delete-system-hook}

시스템 훅을 삭제합니다.

```plaintext
DELETE /hooks/:id
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 정수 | 예      | 훅의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/2"
```

## URL 변수 설정 {#set-a-url-variable}

```plaintext
PUT /hooks/:hook_id/url_variables/:key
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `hook_id` | 정수 | 예      | 시스템 훅의 ID입니다. |
| `key`     | 문자열  | 예      | URL 변수의 키입니다. |
| `value`   | 문자열  | 예      | URL 변수의 값입니다. |

성공하면 이 엔드포인트는 응답 코드 `204 No Content`를 반환합니다.

## URL 변수 삭제 {#delete-a-url-variable}

```plaintext
DELETE /hooks/:hook_id/url_variables/:key
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 정수           | 예      | 시스템 훅의 ID입니다. |
| `key`     | 문자열            | 예      | URL 변수의 키입니다. |

성공하면 이 엔드포인트는 응답 코드 `204 No Content`를 반환합니다.
