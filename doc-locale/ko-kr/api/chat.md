---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API를 사용한 GitLab Duo Chat 설명서입니다.
title: GitLab Duo Chat 완성 API
---

이 API는 [GitLab Duo Chat](../user/gitlab_duo_chat/_index.md)에 대한 응답을 생성하는 데 사용됩니다:

- GitLab.com에서 이 API는 내부 전용입니다.
- GitLab Self-Managed에서는 [기능 플래그](../administration/feature_flags/_index.md)를 사용하여 이 API를 활성화할 수 있으며, 기능 플래그의 이름은 `access_rest_chat`입니다.

전제 조건:

- [GitLab 팀 구성원](https://gitlab.com/groups/gitlab-com/-/group_members)이어야 합니다.

## Chat 응답 생성 {#generate-a-chat-response}

GitLab Duo Chat 질문에 대한 응답을 생성합니다.

{{< history >}}

- GitLab 16.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133015) [기능 플래그](../administration/feature_flags/_index.md) `access_rest_chat`로 이름 지정됨 기본적으로 비활성화됨. 이 기능은 내부 전용입니다.
- `additional_context` 매개변수는 GitLab 17.4에 [추가되었으며](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162650) [기능 플래그](../administration/feature_flags/_index.md)의 이름은 `duo_additional_context`입니다. 기본적으로 비활성화됨. 이 기능은 내부 전용입니다.
- `additional_context` 매개변수는 GitLab 17.9에서 [GitLab.com 및 GitLab Self-Managed에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181305).
- `additional_context` 매개변수는 GitLab 18.0에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/514559). 기능 플래그 `duo_additional_context` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

```plaintext
POST /chat/completions
```

> [!note]
> 이 엔드포인트에 대한 요청은 [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)로 프록시됩니다.

지원되는 속성:

| 속성                | 유형            | 필수 | 설명                                                             |
|--------------------------|-----------------|----------|-------------------------------------------------------------------------|
| `content`                | 문자열          | 예      | Chat으로 전송된 질문입니다.                                                  |
| `resource_type`          | 문자열          | 아니요       | Chat 질문과 함께 전송되는 리소스의 유형입니다.                       |
| `resource_id`            | 문자열, 정수 | 아니요       | 리소스의 ID입니다. 리소스 ID(정수) 또는 커밋 해시(문자열)일 수 있습니다. |
| `referer_url`            | 문자열          | 아니요       | 참조 URL입니다.                                                            |
| `client_subscription_id` | 문자열          | 아니요       | 클라이언트 구독 ID입니다.                                                 |
| `with_clean_history`     | 부울         | 아니요       | 요청 전후에 기록을 재설정해야 하는지 나타냅니다. |
| `project_id`             | 정수         | 아니요       | 프로젝트 ID입니다. `resource_type`이 커밋인 경우 필수입니다.                    |
| `additional_context`     | 배열           | 아니요       | 이 chat 요청에 대한 추가 컨텍스트 항목의 배열입니다. [컨텍스트 속성](#context-attributes)을 참조하여 이 속성이 허용하는 매개변수 목록을 확인합니다. |

### 컨텍스트 속성 {#context-attributes}

`context` 속성은 다음 속성을 가진 요소 목록을 허용합니다:

- `category` - 컨텍스트 요소의 카테고리입니다. 유효한 값은 `file`, `merge_request`, `issue` 또는 `snippet`입니다.
- `id` - 컨텍스트 요소의 ID입니다.
- `content` - 컨텍스트 요소의 내용입니다. 값은 컨텍스트 요소의 카테고리에 따라 달라집니다.
- `metadata` - 이 컨텍스트 요소의 선택적 추가 메타데이터입니다. 값은 컨텍스트 요소의 카테고리에 따라 달라집니다.

요청 예시:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "content": "how to define class in ruby",
      "additional_context": [
        {
          "category": "file",
          "id": "main.rb",
          "content": "class Foo\nend"
        }
      ]
    }' \
  --url "https://gitlab.example.com/api/v4/chat/completions"
```

응답 예시:

```json
"To define class in ruby..."
```
