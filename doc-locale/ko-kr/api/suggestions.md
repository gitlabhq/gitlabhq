---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 변경 사항 제안 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [코드 제안](../user/project/merge_requests/reviews/suggestions.md)을 관리합니다.

제안은 코드에 직접 적용할 수 있는 특정 변경 사항을 제안하는 방법을 제공합니다. 이 API를 사용하여 머지 리퀘스트 토론에서 프로그래밍 방식으로 코드 제안을 생성하고 적용할 수 있습니다. 제안에 대한 모든 API 호출은 인증되어야 합니다.

## 제안 생성 {#create-a-suggestion}

API를 통해 제안을 생성하려면 Discussions API를 사용하여 [머지 리퀘스트 diff에서 새 스레드를 생성](discussions.md#create-a-merge-request-thread)합니다. 제안의 형식은 다음과 같습니다:

````markdown
```suggestion:-3+0
example text
```
````

## 제안 적용 {#apply-a-suggestion}

머지 리퀘스트에서 제안된 패치를 적용합니다.

전제 조건:

- 사용자는 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PUT /suggestions/:id/apply
```

지원되는 속성:

| 속성        | 유형    | 필수 | 설명 |
|------------------|---------|----------|-------------|
| `id`             | 정수 | 예      | 제안의 ID입니다. |
| `commit_message` | 문자열  | 아니요       | 기본 생성된 메시지 또는 프로젝트의 기본 메시지 대신 사용할 사용자 지정 커밋 메시지입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)과 다음 응답 속성을 반환합니다:

| 속성      | 유형    | 설명 |
|----------------|---------|-------------|
| `applicable`   | 부울 | `true`인 경우 제안을 적용할 수 있습니다. |
| `applied`      | 부울 | `true`인 경우 제안이 적용되었습니다. |
| `from_content` | 문자열  | 제안 전의 원본 콘텐츠입니다. |
| `from_line`    | 정수 | 제안의 시작 줄 번호입니다. |
| `id`           | 정수 | 제안의 ID입니다. |
| `to_content`   | 문자열  | 원본을 대체할 제안된 콘텐츠입니다. |
| `to_line`      | 정수 | 제안의 끝 줄 번호입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/suggestions/5/apply"
```

예시 응답:

```json
{
  "id": 5,
  "from_line": 10,
  "to_line": 10,
  "applicable": true,
  "applied": false,
  "from_content": "This is an example\n",
  "to_content": "This is an example\n"
}
```

## 여러 제안 적용 {#apply-multiple-suggestions}

머지 리퀘스트에서 제안된 여러 패치를 적용합니다.

전제 조건:

- 사용자는 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PUT /suggestions/batch_apply
```

지원되는 속성:

| 속성        | 유형          | 필수 | 설명 |
|------------------|---------------|----------|-------------|
| `ids`            | 정수 배열 | 예      | 적용할 제안의 ID입니다. |
| `commit_message` | 문자열        | 아니요       | 기본 생성된 메시지 또는 프로젝트의 기본 메시지 대신 사용할 사용자 지정 커밋 메시지입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)과 다음 응답 속성을 포함하는 제안 객체의 배열을 반환합니다:

| 속성      | 유형    | 설명 |
|----------------|---------|-------------|
| `applicable`   | 부울 | `true`인 경우 제안을 적용할 수 있습니다. |
| `applied`      | 부울 | `true`인 경우 제안이 적용되었습니다. |
| `from_content` | 문자열  | 제안 전의 원본 콘텐츠입니다. |
| `from_line`    | 정수 | 제안의 시작 줄 번호입니다. |
| `id`           | 정수 | 제안의 ID입니다. |
| `to_content`   | 문자열  | 원본을 대체할 제안된 콘텐츠입니다. |
| `to_line`      | 정수 | 제안의 끝 줄 번호입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"ids": [5, 6]}' \
  --url "https://gitlab.example.com/api/v4/suggestions/batch_apply"
```

예시 응답:

```json
[
  {
    "id": 5,
    "from_line": 10,
    "to_line": 10,
    "applicable": true,
    "applied": false,
    "from_content": "This is an example\n",
    "to_content": "This is an example\n"
  },
  {
    "id": 6,
    "from_line": 19,
    "to_line": 19,
    "applicable": true,
    "applied": false,
    "from_content": "This is another example\n",
    "to_content": "This is another example\n"
  }
]
```
