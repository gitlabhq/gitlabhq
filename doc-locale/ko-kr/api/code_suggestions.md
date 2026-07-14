---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Code Suggestions를 위한 REST API 설명서입니다.
title: Code Suggestions API
---

이 API를 사용하여 GitLab Duo Code Suggestions에 액세스합니다.

## 코드 완성 생성 {#generate-code-completions}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 16.2에서 [기능 플래그](../administration/feature_flags/_index.md)와 함께 도입되었으며 `code_suggestions_completion_api`로 명명됩니다. 기본적으로 비활성화됨. 이 기능은 실험입니다.
- 이 엔드포인트를 호출하기 전에 JWT를 생성해야 한다는 요구사항은 GitLab 16.3에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863)되었습니다.
- GitLab 16.8에서 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/416371)됩니다. [기능 플래그 `code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174)가 제거되었습니다.
- `context` 및 `user_instruction` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) 되었으며 [기능 플래그](../administration/feature_flags/_index.md)와 함께 `code_suggestions_context`로 명명됩니다. 기본적으로 비활성화됨.
- `context` 및 `user_instruction` 속성이 GitLab 18.6에서 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)됩니다. 기능 플래그 `code_suggestions_context` 제거됨.

{{< /history >}}

```plaintext
POST /code_suggestions/completions
```

> [!note]
> 이 엔드포인트는 각 사용자를 1분 윈도우당 60개 요청으로 속도 제한합니다.

AI 추상화 계층을 사용하여 코드 완성을 생성합니다.

이 엔드포인트에 대한 요청은 [AI 게이트웨이](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)로 프록시됩니다.

매개변수:

| 속성          | 유형    | 필수 | 설명 |
|--------------------|---------|----------|-------------|
| `current_file`     | 해시    | 예      | 제안이 생성되는 파일의 속성입니다. [파일 속성](#file-attributes)을 참조하여 이 속성이 허용하는 문자열 목록을 확인합니다. |
| `intent`           | 문자열  | 아니요       | 완성 요청의 의도입니다. 이는 `completion` 또는 `generation`일 수 있습니다. |
| `stream`           | 부울 | 아니요       | 응답을 준비된 더 작은 청크로 스트리밍할지 여부입니다(해당하는 경우). 기본값: `false`. |
| `project_path`     | 문자열  | 아니요       | 프로젝트의 경로입니다. |
| `generation_type`  | 문자열  | 아니요       | 생성 요청에 대한 이벤트 유형입니다. 이는 `comment`, `empty_function`, 또는 `small_file`일 수 있습니다. |
| `context`          | 배열   | 아니요       | 코드 제안에 사용할 추가 컨텍스트입니다. [컨텍스트 속성](#context-attributes)을 참조하여 이 속성이 허용하는 매개변수 목록을 확인합니다. |
| `user_instruction` | 문자열  | 아니요       | 코드 제안을 위한 사용자의 지시사항입니다. |

### 파일 속성 {#file-attributes}

`current_file` 속성은 다음 문자열을 허용합니다:

- `file_name` - 파일의 이름입니다. 필수입니다.
- `content_above_cursor` - 현재 커서 위치 위의 파일 내용입니다. 필수입니다.
- `content_below_cursor` - 현재 커서 위치 아래의 파일 내용입니다. 선택사항.

### 컨텍스트 속성 {#context-attributes}

`context` 속성은 다음 속성을 가진 요소 목록을 허용합니다:

- `type` - 컨텍스트 요소의 유형입니다. 이는 `file` 또는 `snippet`일 수 있습니다.
- `name` - 컨텍스트 요소의 이름입니다. 파일 또는 코드 스니펫의 이름입니다.
- `content` - 컨텍스트 요소의 내용입니다. 파일의 본문 또는 함수입니다.

요청 예시:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --data '{
      "current_file": {
        "file_name": "car.py",
        "content_above_cursor": "class Car:\n    def __init__(self):\n        self.is_running = False\n        self.speed = 0\n    def increase_speed(self, increment):",
        "content_below_cursor": ""
      },
      "intent": "completion"
    }' \
  --url "https://gitlab.example.com/api/v4/code_suggestions/completions"
```

응답 예시:

```json
{
  "id": "id",
  "model": {
    "engine": "vertex-ai",
    "name": "code-gecko"
  },
  "object": "text_completion",
  "created": 1688557841,
  "choices": [
    {
      "text": "\n        if self.is_running:\n            self.speed += increment\n            print(\"The car's speed is now",
      "index": 0,
      "finish_reason": "length"
    }
  ]
}
```

## 코드 제안이 활성화되었는지 검증 {#validate-that-code-suggestions-is-enabled}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138814)되었습니다.

{{< /history >}}

이 엔드포인트를 사용하여 다음 중 하나를 검증합니다:

- 프로젝트에 `code_suggestions`이 활성화되어 있습니다.
- 프로젝트의 그룹에 네임스페이스 설정에서 `code_suggestions`이 활성화되어 있습니다.

```plaintext
POST code_suggestions/enabled
```

지원되는 속성:

| 속성         | 유형    | 필수 | 설명 |
| ----------------- | ------- | -------- | ----------- |
| `project_path`    | 문자열  | 예      | 검증할 프로젝트의 경로입니다. |

성공한 경우 반환값:

- 기능이 활성화된 경우 [`200`](rest/troubleshooting.md#status-codes)입니다.
- 기능이 비활성화된 경우 [`403`](rest/troubleshooting.md#status-codes)입니다.

또한 경로가 비어 있거나 프로젝트가 없는 경우 [`404`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/code_suggestions/enabled" \
  --header "PRIVATE-TOKEN: <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "project_path": "group/project_name"
    }'
```

## AI 게이트웨이에 대한 직접 연결 세부 정보 가져오기 {#fetch-direct-connection-details-for-the-ai-gateway}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/452044) 되었으며 [기능 플래그](../administration/feature_flags/_index.md)와 함께 `code_suggestions_direct_completions`로 명명됩니다. 기본적으로 비활성화됨.
- GitLab 17.2에서 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/456443)됩니다. 기능 플래그 `code_suggestions_direct_completions` 제거됨.

{{< /history >}}

```plaintext
POST /code_suggestions/direct_access
```

> [!note]
> 이 엔드포인트는 각 사용자를 5분 윈도우당 10개 요청으로 속도 제한합니다.

IDE/클라이언트에서 `completion` 요청을 AI 게이트웨이로 직접 보내는 데 사용할 수 있는 사용자 특정 연결 세부 정보를 반환하며, AI 게이트웨이로 프록시되어야 하는 헤더와 필수 인증 토큰을 포함합니다.

요청 예시:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/direct_access"
```

응답 예시:

```json
{
  "base_url": "http://0.0.0.0:5052",
  "token": "a valid token",
  "expires_at": 1713343569,
  "headers": {
    "X-Gitlab-Instance-Id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
    "X-Gitlab-Realm": "saas",
    "X-Gitlab-Global-User-Id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
    "X-Gitlab-Host-Name": "gitlab.example.com"
  }
}
```

## 연결 세부 정보 가져오기 {#fetch-connection-details}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/555060)되었습니다.

{{< /history >}}

```plaintext
POST /code_suggestions/connection_details
```

> [!note]
> 이 엔드포인트는 각 사용자를 1분 윈도우당 10개 요청으로 속도 제한합니다.

사용자가 연결된 GitLab 인스턴스에 대한 메타데이터를 포함하여 원격 분석에 사용할 수 있는 사용자 특정 연결 세부 정보를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/connection_details"
```

응답 예시:

```json
{
  "instance_id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
  "instance_version": "18.2",
  "realm": "saas",
  "global_user_id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
  "host_name": "gitlab.example.com",
  "feature_enablement_type": "duo_pro",
  "saas_duo_pro_namespace_ids": "1000000"
}
```
