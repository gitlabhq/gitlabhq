---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 스니펫
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [프로젝트 스니펫](../user/snippets.md)을 관리합니다. [개인 스니펫](snippets.md) 및 [스니펫을 저장소 간에 이동](snippet_repository_storage_moves.md)하기 위한 관련 API가 있습니다.

## 프로젝트의 모든 스니펫 나열 {#list-all-snippets-for-a-project}

지정된 프로젝트의 모든 스니펫을 나열합니다.

```plaintext
GET /projects/:id/snippets
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `author.created_at` | 문자열  | 작성자 계정이 생성된 날짜와 시간입니다. |
| `author.email`      | 문자열  | 스니펫 작성자의 이메일 주소입니다. |
| `author.id`         | 정수 | 스니펫 작성자의 ID입니다. |
| `author.name`       | 문자열  | 스니펫 작성자의 표시 이름입니다. |
| `author.state`      | 문자열  | 작성자 계정의 상태입니다. |
| `author.username`   | 문자열  | 스니펫 작성자의 사용자 이름입니다. |
| `created_at`        | 문자열  | 스니펫이 생성된 날짜와 시간(ISO 8601 형식)입니다. |
| `description`       | 문자열  | 스니펫의 설명입니다. |
| `file_name`         | 문자열  | 스니펫 파일의 이름입니다. |
| `id`                | 정수 | 스니펫의 ID입니다. |
| `imported`          | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`     | 문자열  | 스니펫을 가져온 경우 가져오기의 원본입니다. |
| `project_id`        | 정수 | 스니펫을 포함하는 프로젝트의 ID입니다. |
| `raw_url`           | 문자열  | 원본 스니펫 콘텐츠의 직접 URL입니다. |
| `title`             | 문자열  | 스니펫의 제목입니다. |
| `updated_at`        | 문자열  | 스니펫이 마지막으로 업데이트된 날짜와 시간(ISO 8601 형식)입니다. |
| `web_url`           | 문자열  | GitLab 웹 인터페이스에서 스니펫을 보는 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": "test",
    "file_name": "add.rb",
    "description": "Ruby test snippet",
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "state": "active",
      "created_at": "2012-05-23T08:00:58Z"
    },
    "updated_at": "2012-06-28T10:52:04Z",
    "created_at": "2012-06-28T10:52:04Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/1",
    "raw_url": "http://example.com/example/example/snippets/1/raw"
  },
  {
    "id": 3,
    "title": "Configuration helper",
    "file_name": "config.yml",
    "description": "YAML configuration snippet",
    "author": {
      "id": 2,
      "username": "jane_doe",
      "email": "jane@example.com",
      "name": "Jane Doe",
      "state": "active",
      "created_at": "2013-02-15T10:30:20Z"
    },
    "updated_at": "2013-03-10T14:15:30Z",
    "created_at": "2013-03-01T09:45:12Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/3",
    "raw_url": "http://example.com/example/example/snippets/3/raw"
  }
]
```

## 스니펫 검색 {#retrieve-a-snippet}

지정된 프로젝트 스니펫을 검색합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `snippet_id` | 정수           | 예      | 프로젝트의 스니펫 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `author.created_at` | 문자열  | 작성자 계정이 생성된 날짜와 시간입니다. |
| `author.email`      | 문자열  | 스니펫 작성자의 이메일 주소입니다. |
| `author.id`         | 정수 | 스니펫 작성자의 ID입니다. |
| `author.name`       | 문자열  | 스니펫 작성자의 표시 이름입니다. |
| `author.state`      | 문자열  | 작성자 계정의 상태입니다. |
| `author.username`   | 문자열  | 스니펫 작성자의 사용자 이름입니다. |
| `created_at`        | 문자열  | 스니펫이 생성된 날짜와 시간(ISO 8601 형식)입니다. |
| `description`       | 문자열  | 스니펫의 설명입니다. |
| `file_name`         | 문자열  | 스니펫 파일의 이름입니다. |
| `id`                | 정수 | 스니펫의 ID입니다. |
| `imported`          | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`     | 문자열  | 스니펫을 가져온 경우 가져오기의 원본입니다. |
| `project_id`        | 정수 | 스니펫을 포함하는 프로젝트의 ID입니다. |
| `raw_url`           | 문자열  | 원본 스니펫 콘텐츠의 직접 URL입니다. |
| `title`             | 문자열  | 스니펫의 제목입니다. |
| `updated_at`        | 문자열  | 스니펫이 마지막으로 업데이트된 날짜와 시간(ISO 8601 형식)입니다. |
| `web_url`           | 문자열  | GitLab 웹 인터페이스에서 스니펫을 보는 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

응답 예시:

```json
{
  "id": 2,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## 스니펫 생성 {#create-a-snippet}

프로젝트 스니펫을 생성합니다. 사용자는 스니펫을 생성할 수 있는 권한이 있어야 합니다.

```plaintext
POST /projects/:id/snippets
```

지원되는 속성:

| 속성         | 유형              | 필수 | 설명 |
|-------------------|-------------------|----------|-------------|
| `files`           | 해시 배열   | 예      | 스니펫 파일의 배열입니다. |
| `files:content`   | 문자열            | 예      | 스니펫 파일의 콘텐츠입니다. |
| `files:file_path` | 문자열            | 예      | 스니펫 파일의 파일 경로입니다. |
| `id`              | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `title`           | 문자열            | 예      | 스니펫의 제목입니다. |
| `content`         | 문자열            | 아니요       | 지원 중단됨:  `files` 대신 사용합니다. 스니펫의 콘텐츠입니다. |
| `description`     | 문자열            | 아니요       | 스니펫의 설명입니다. |
| `file_name`       | 문자열            | 아니요       | 지원 중단됨:  `files` 대신 사용합니다. 스니펫 파일의 이름입니다. |
| `visibility`      | 문자열            | 아니요       | 스니펫의 가시성 수준입니다. 가능한 값: `public`, `private` 및 `internal`입니다. GitLab.com에서는 `internal` 값을 사용할 수 없습니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `author.created_at` | 문자열  | 작성자 계정이 생성된 날짜와 시간입니다. |
| `author.email`      | 문자열  | 스니펫 작성자의 이메일 주소입니다. |
| `author.id`         | 정수 | 스니펫 작성자의 ID입니다. |
| `author.name`       | 문자열  | 스니펫 작성자의 표시 이름입니다. |
| `author.state`      | 문자열  | 작성자 계정의 상태입니다. |
| `author.username`   | 문자열  | 스니펫 작성자의 사용자 이름입니다. |
| `created_at`        | 문자열  | 스니펫이 생성된 날짜와 시간(ISO 8601 형식)입니다. |
| `description`       | 문자열  | 스니펫의 설명입니다. |
| `file_name`         | 문자열  | 스니펫 파일의 이름입니다. |
| `id`                | 정수 | 스니펫의 ID입니다. |
| `imported`          | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`     | 문자열  | 스니펫을 가져온 경우 가져오기의 원본입니다. |
| `project_id`        | 정수 | 스니펫을 포함하는 프로젝트의 ID입니다. |
| `raw_url`           | 문자열  | 원본 스니펫 콘텐츠의 직접 URL입니다. |
| `title`             | 문자열  | 스니펫의 제목입니다. |
| `updated_at`        | 문자열  | 스니펫이 마지막으로 업데이트된 날짜와 시간(ISO 8601 형식)입니다. |
| `web_url`           | 문자열  | GitLab 웹 인터페이스에서 스니펫을 보는 URL입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Example Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"file_path": "example.txt", "content": "source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Example Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/1",
  "raw_url": "http://example.com/example/example/snippets/1/raw"
}
```

## 스니펫 업데이트 {#update-a-snippet}

지정된 프로젝트 스니펫을 업데이트합니다. 사용자는 기존 스니펫을 변경할 수 있는 권한이 있어야 합니다.

여러 파일을 포함하는 스니펫의 업데이트는 `files` 속성을 사용해야 합니다.

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

지원되는 속성:

| 속성             | 유형              | 필수      | 설명 |
| --------------------- | ----------------- | ------------- | ----------- |
| `id`                  | 정수 또는 문자열 | 예           | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `snippet_id`          | 정수           | 예           | 프로젝트의 스니펫 ID입니다. |
| `files:action`        | 문자열            | 조건부 | 파일에서 수행할 작업의 유형입니다. 다음 중 하나: `create`, `update`, `delete`, `move`입니다. `files` 속성을 사용할 때 필수입니다. |
| `content`             | 문자열            | 아니요            | 지원 중단됨:  `files` 대신 사용합니다. 스니펫의 콘텐츠입니다. |
| `description`         | 문자열            | 아니요            | 스니펫의 설명입니다. |
| `file_name`           | 문자열            | 아니요            | 지원 중단됨:  `files` 대신 사용합니다. 스니펫 파일의 이름입니다. |
| `files`               | 해시 배열   | 아니요            | 스니펫 파일의 배열입니다. |
| `files:content`       | 문자열            | 아니요            | 스니펫 파일의 콘텐츠입니다. |
| `files:file_path`     | 문자열            | 아니요            | 스니펫 파일의 파일 경로입니다. |
| `files:previous_path` | 문자열            | 아니요            | 스니펫 파일의 이전 경로입니다. |
| `title`               | 문자열            | 아니요            | 스니펫의 제목입니다. |
| `visibility`      | 문자열            | 아니요       | 스니펫의 가시성 수준입니다. 가능한 값: `public`, `private` 및 `internal`입니다. GitLab.com에서는 `internal` 값을 사용할 수 없습니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `author.created_at` | 문자열  | 작성자 계정이 생성된 날짜와 시간입니다. |
| `author.email`      | 문자열  | 스니펫 작성자의 이메일 주소입니다. |
| `author.id`         | 정수 | 스니펫 작성자의 ID입니다. |
| `author.name`       | 문자열  | 스니펫 작성자의 표시 이름입니다. |
| `author.state`      | 문자열  | 작성자 계정의 상태입니다. |
| `author.username`   | 문자열  | 스니펫 작성자의 사용자 이름입니다. |
| `created_at`        | 문자열  | 스니펫이 생성된 날짜와 시간(ISO 8601 형식)입니다. |
| `description`       | 문자열  | 스니펫의 설명입니다. |
| `file_name`         | 문자열  | 스니펫 파일의 이름입니다. |
| `id`                | 정수 | 스니펫의 ID입니다. |
| `imported`          | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`     | 문자열  | 스니펫을 가져온 경우 가져오기의 원본입니다. |
| `project_id`        | 정수 | 스니펫을 포함하는 프로젝트의 ID입니다. |
| `raw_url`           | 문자열  | 원본 스니펫 콘텐츠의 직접 URL입니다. |
| `title`             | 문자열  | 스니펫의 제목입니다. |
| `updated_at`        | 문자열  | 스니펫이 마지막으로 업데이트된 날짜와 시간(ISO 8601 형식)입니다. |
| `web_url`           | 문자열  | GitLab 웹 인터페이스에서 스니펫을 보는 URL입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Updated Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"action": "update", "file_path": "example.txt", "content": "updated source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

응답 예시:

```json
{
  "id": 2,
  "title": "Updated Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## 스니펫 삭제 {#delete-a-snippet}

지정된 프로젝트 스니펫을 삭제합니다. 작업이 성공하면 `204 No Content` 상태 코드를 반환하거나 리소스를 찾을 수 없으면 `404`을 반환합니다.

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `snippet_id` | 정수           | 예      | 프로젝트의 스니펫 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

## 스니펫 콘텐츠 검색 {#retrieve-snippet-content}

원본 프로젝트 스니펫을 일반 텍스트로 검색합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `snippet_id` | 정수           | 예      | 프로젝트의 스니펫 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/raw"
```

## 스니펫 리포지토리 파일 콘텐츠 검색 {#retrieve-snippet-repository-file-content}

원본 파일 콘텐츠를 일반 텍스트로 검색합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `file_path`  | 문자열            | 예      | 파일에 대한 URL 인코딩된 경로입니다(예: `snippet%2Erb`). |
| `ref`        | 문자열            | 예      | 브랜치, 태그 또는 커밋의 이름입니다(예: `main`). |
| `snippet_id` | 정수           | 예      | 프로젝트의 스니펫 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw"
```

## 사용자 에이전트 세부 정보 검색 {#retrieve-user-agent-details}

지정된 스니펫에 대한 사용자 에이전트 세부 정보를 검색합니다. 관리자 액세스 권한이 있는 사용자만 사용할 수 있습니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `snippet_id` | 정수           | 예      | 스니펫의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `akismet_submitted` | 부울 | `true`이면 스니펫이 스팸 감지를 위해 Akismet에 제출되었습니다. |
| `ip_address`        | 문자열  | 스니펫을 생성한 사용자의 IP 주소입니다. |
| `user_agent`        | 문자열  | 스니펫을 생성하기 위해 사용된 브라우저의 사용자 에이전트 문자열입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail"
```

응답 예시:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
