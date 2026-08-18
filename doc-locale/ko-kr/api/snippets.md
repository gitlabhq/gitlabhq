---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스니펫 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [스니펫](../user/snippets.md)을 관리합니다. [프로젝트 스니펫](project_snippets.md) 및 [스토리지 간 스니펫 이동](snippet_repository_storage_moves.md)에 대한 관련 API가 있습니다.

## 현재 사용자의 모든 스니펫 나열 {#list-all-snippets-for-current-user}

현재 사용자의 스니펫 목록을 가져옵니다.

```plaintext
GET /snippets
```

지원되는 속성:

| 속성        | 유형     | 필수 | 설명 |
|------------------|----------|----------|-------------|
| `created_after`  | 날짜/시간 | 아니요       | 주어진 시간 이후에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before` | 날짜/시간 | 아니요       | 주어진 시간 이전에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `page`           | 정수  | 아니요       | 검색할 페이지입니다. |
| `per_page`       | 정수  | 아니요       | 페이지당 반환할 스니펫의 수입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성       | 유형    | 설명 |
|-----------------|---------|-------------|
| `author`        | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`    | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description`   | 문자열  | 스니펫의 설명입니다. |
| `file_name`     | 문자열  | 스니펫 파일의 이름입니다. |
| `id`            | 정수 | 스니펫의 ID입니다. |
| `imported`      | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from` | 문자열  | 가져온 출처입니다. |
| `project_id`    | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`       | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `title`         | 문자열  | 스니펫의 제목입니다. |
| `updated_at`    | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`    | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`       | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets"
```

응답 예시:

```json
[
    {
        "id": 42,
        "title": "Voluptatem iure ut qui aut et consequatur quaerat.",
        "file_name": "mclaughlin.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.383Z",
        "created_at": "2018-09-18T01:12:26.383Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/42",
        "raw_url": "http://example.com/snippets/42/raw"
    },
    {
        "id": 41,
        "title": "Ut praesentium non et atque.",
        "file_name": "ondrickaemard.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.360Z",
        "created_at": "2018-09-18T01:12:26.360Z",
        "project_id": 1,
        "web_url": "http://example.com/gitlab-org/gitlab-test/snippets/41",
        "raw_url": "http://example.com/gitlab-org/gitlab-test/snippets/41/raw"
    }
]
```

## 스니펫 검색 {#retrieve-a-snippet}

지정된 스니펫을 검색합니다.

```plaintext
GET /snippets/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                |
|-----------|---------|----------|----------------------------|
| `id`      | 정수 | 예      | 검색할 스니펫의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형    | 설명 |
|--------------------|---------|-------------|
| `author`           | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`       | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description`      | 문자열  | 스니펫의 설명입니다. |
| `expires_at`       | 문자열  | 스니펫이 만료되는 날짜 및 시간입니다. |
| `file_name`        | 문자열  | 스니펫 파일의 이름입니다. |
| `http_url_to_repo` | 문자열  | 스니펫 리포지토리로의 HTTP URL입니다. |
| `id`               | 정수 | 스니펫의 ID입니다. |
| `imported`         | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`    | 문자열  | 가져온 출처입니다. |
| `project_id`       | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`          | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `ssh_url_to_repo`  | 문자열  | 스니펫 리포지토리로의 SSH URL입니다. |
| `title`            | 문자열  | 스니펫의 제목입니다. |
| `updated_at`       | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`       | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`          | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "visibility": "private",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw"
}
```

## 단일 스니펫 콘텐츠 {#single-snippet-contents}

단일 스니펫의 원본 콘텐츠를 가져옵니다.

```plaintext
GET /snippets/:id/raw
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                |
|-----------|---------|----------|----------------------------|
| `id`      | 정수 | 예      | 검색할 스니펫의 ID입니다. |

성공한 경우 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 스니펫의 원본 콘텐츠를 제공합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/raw"
```

응답 예시:

```plaintext
Hello World snippet
```

## 스니펫 리포지토리 파일 콘텐츠 {#snippet-repository-file-content}

원본 파일 콘텐츠를 일반 텍스트로 반환합니다.

```plaintext
GET /snippets/:id/files/:ref/:file_path/raw
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명 |
|-------------|---------|----------|-------------|
| `file_path` | 문자열  | 예      | URL로 인코딩된 파일 경로입니다. |
| `id`        | 정수 | 예      | 검색할 스니펫의 ID입니다. |
| `ref`       | 문자열  | 예      | 태그, 브랜치 또는 커밋에 대한 참조입니다. |

성공한 경우 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 원본 파일 콘텐츠를 제공합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/files/main/snippet%2Erb/raw"
```

응답 예시:

```plaintext
Hello World snippet
```

## 스니펫 생성 {#create-a-snippet}

새 스니펫을 생성합니다.

> [!note]
> 사용자는 새 스니펫을 생성할 수 있는 권한이 있어야 합니다.

```plaintext
POST /snippets
```

지원되는 속성:

| 속성         | 유형            | 필수 | 설명 |
| ----------------- | --------------- | -------- | ----------- |
| `files:content`   | 문자열          | 예      | 스니펫 파일의 콘텐츠입니다. |
| `files:file_path` | 문자열          | 예      | 스니펫 파일의 파일 경로입니다. |
| `title`           | 문자열          | 예      | 스니펫의 제목입니다. |
| `content`         | 문자열          | 아니요       | 지원 중단됨:  `files` 대신 사용합니다. 스니펫의 콘텐츠입니다. |
| `description`     | 문자열          | 아니요       | 스니펫의 설명입니다. |
| `file_name`       | 문자열          | 아니요       | 지원 중단됨:  `files` 대신 사용합니다. 스니펫 파일의 이름입니다. |
| `files`           | 해시 배열 | 아니요       | 스니펫 파일의 배열입니다. |
| `visibility`      | 문자열          | 아니요       | 스니펫의 가시성 수준입니다. 가능한 값: `public`, `private` 및 `internal`입니다. GitLab.com에서는 `internal` 값을 사용할 수 없습니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형    | 설명 |
|--------------------|---------|-------------|
| `author`           | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`       | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description`      | 문자열  | 스니펫의 설명입니다. |
| `expires_at`       | 문자열  | 스니펫이 만료되는 날짜 및 시간입니다. |
| `file_name`        | 문자열  | 스니펫 파일의 이름입니다. |
| `files`            | 배열   | 스니펫 파일의 배열입니다. |
| `http_url_to_repo` | 문자열  | 스니펫 리포지토리로의 HTTP URL입니다. |
| `id`               | 정수 | 스니펫의 ID입니다. |
| `imported`         | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`    | 문자열  | 가져온 출처입니다. |
| `project_id`       | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`          | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `ssh_url_to_repo`  | 문자열  | 스니펫 리포지토리로의 SSH URL입니다. |
| `title`            | 문자열  | 스니펫의 제목입니다. |
| `updated_at`       | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`       | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`          | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --request POST "https://gitlab.example.com/api/v4/snippets" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json`은 이전 예시 요청에서 사용됩니다:

```json
{
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "files": [
    {
      "content": "Hello world",
      "file_path": "test.txt"
    }
  ]
}
```

응답 예시:

```json
{
  "id": 1,
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "test.txt",
  "files": [
    {
      "path": "text.txt",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## 스니펫 업데이트 {#update-snippet}

기존 스니펫을 업데이트합니다.

> [!note]
> 사용자는 기존 스니펫을 변경할 수 있는 권한이 있어야 합니다.

```plaintext
PUT /snippets/:id
```

지원되는 속성:

| 속성             | 유형            | 필수      | 설명 |
| --------------------- | --------------- | ------------- | ----------- |
| `id`                  | 정수         | 예           | 업데이트할 스니펫의 ID입니다. |
| `files:action`        | 문자열          | 예           | 파일에 수행할 작업의 유형입니다. 하나는 `create`, `update`, `delete`, `move`입니다. |
| `content`             | 문자열          | 아니요            | 지원 중단됨:  `files` 대신 사용합니다. 스니펫의 콘텐츠입니다. |
| `description`         | 문자열          | 아니요            | 스니펫의 설명입니다. |
| `file_name`           | 문자열          | 아니요            | 지원 중단됨:  `files` 대신 사용합니다. 스니펫 파일의 이름입니다. |
| `files`               | 해시 배열 | 조건부 | 스니펫 파일의 배열입니다. 여러 파일을 포함한 스니펫을 업데이트할 때 필수입니다. |
| `files:content`       | 문자열          | 아니요            | 스니펫 파일의 콘텐츠입니다. |
| `files:file_path`     | 문자열          | 아니요            | 스니펫 파일의 파일 경로입니다. |
| `files:previous_path` | 문자열          | 아니요            | 스니펫 파일의 이전 경로입니다. |
| `title`               | 문자열          | 아니요            | 스니펫의 제목입니다. |
| `visibility`          | 문자열          | 아니요            | 스니펫의 가시성 수준입니다. 가능한 값: `public`, `private` 및 `internal`입니다. GitLab.com에서는 `internal` 값을 사용할 수 없습니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형    | 설명 |
|--------------------|---------|-------------|
| `author`           | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`       | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description`      | 문자열  | 스니펫의 설명입니다. |
| `expires_at`       | 문자열  | 스니펫이 만료되는 날짜 및 시간입니다. |
| `file_name`        | 문자열  | 스니펫 파일의 이름입니다. |
| `files`            | 배열   | 스니펫 파일의 배열입니다. |
| `http_url_to_repo` | 문자열  | 스니펫 리포지토리로의 HTTP URL입니다. |
| `id`               | 정수 | 스니펫의 ID입니다. |
| `imported`         | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`    | 문자열  | 가져온 출처입니다. |
| `project_id`       | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`          | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `ssh_url_to_repo`  | 문자열  | 스니펫 리포지토리로의 SSH URL입니다. |
| `title`            | 문자열  | 스니펫의 제목입니다. |
| `updated_at`       | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`       | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`          | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --request PUT "https://gitlab.example.com/api/v4/snippets/1" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json`은 이전 예시 요청에서 사용됩니다:

```json
{
  "title": "foo",
  "files": [
    {
      "action": "move",
      "previous_path": "test.txt",
      "file_path": "renamed.md"
    }
  ]
}
```

응답 예시:

```json
{
  "id": 1,
  "title": "test",
  "description": "description of snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "renamed.md",
  "files": [
    {
      "path": "renamed.md",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## 스니펫 삭제 {#delete-snippet}

기존 스니펫을 삭제합니다.

```plaintext
DELETE /snippets/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명              |
|-----------|---------|----------|--------------------------|
| `id`      | 정수 | 예      | 삭제할 스니펫의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

가능한 반환 코드는 다음과 같습니다:

| 코드  | 설명 |
|-------|-------------|
| `204` | 삭제가 성공했습니다. 반환되는 데이터가 없습니다. |
| `404` | 스니펫을 찾을 수 없습니다. |

## 모든 공개 스니펫 나열 {#list-all-public-snippets}

모든 공개 스니펫을 나열합니다.

```plaintext
GET /snippets/public
```

지원되는 속성:

| 속성        | 유형     | 필수 | 설명 |
|------------------|----------|----------|-------------|
| `created_after`  | 날짜/시간 | 아니요       | 주어진 시간 이후에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before` | 날짜/시간 | 아니요       | 주어진 시간 이전에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `page`           | 정수  | 아니요       | 검색할 페이지입니다. |
| `per_page`       | 정수  | 아니요       | 페이지당 반환할 스니펫의 수입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성     | 유형    | 설명 |
|---------------|---------|-------------|
| `author`      | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`  | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description` | 문자열  | 스니펫의 설명입니다. |
| `file_name`   | 문자열  | 스니펫 파일의 이름입니다. |
| `id`          | 정수 | 스니펫의 ID입니다. |
| `project_id`  | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`     | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `title`       | 문자열  | 스니펫의 제목입니다. |
| `updated_at`  | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`  | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`     | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/public?per_page=2&page=1"
```

응답 예시:

```json
[
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
            "id": 12,
            "name": "Libby Rolfson",
            "state": "active",
            "username": "elton_wehner",
            "web_url": "http://example.com/elton_wehner"
        },
        "created_at": "2016-11-25T16:53:34.504Z",
        "file_name": "oconnerrice.rb",
        "id": 49,
        "title": "Ratione cupiditate et laborum temporibus.",
        "updated_at": "2016-11-25T16:53:34.504Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/49",
        "raw_url": "http://example.com/snippets/49/raw"
    },
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/36583b28626de71061e6e5a77972c3bd?s=80&d=identicon",
            "id": 16,
            "name": "Llewellyn Flatley",
            "state": "active",
            "username": "adaline",
            "web_url": "http://example.com/adaline"
        },
        "created_at": "2016-11-25T16:53:34.479Z",
        "file_name": "muellershields.rb",
        "id": 48,
        "title": "Minus similique nesciunt vel fugiat qui ullam sunt.",
        "updated_at": "2016-11-25T16:53:34.479Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/48",
        "raw_url": "http://example.com/snippets/49/raw",
        "visibility": "public"
    }
]
```

## 모든 스니펫 나열 {#list-all-snippets}

{{< history >}}

- [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419640)됨.

{{< /history >}}

현재 사용자가 액세스할 수 있는 모든 스니펫을 나열합니다. 관리자 또는 감사자 액세스 수준을 가진 사용자는 모든 스니펫(개인 및 프로젝트)을 볼 수 있습니다.

```plaintext
GET /snippets/all
```

지원되는 속성:

| 속성            | 유형     | 필수 | 설명 |
|----------------------|----------|----------|-------------|
| `created_after`      | 날짜/시간 | 아니요       | 주어진 시간 이후에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `created_before`     | 날짜/시간 | 아니요       | 주어진 시간 이전에 생성된 스니펫을 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `page`               | 정수  | 아니요       | 검색할 페이지입니다. |
| `per_page`           | 정수  | 아니요       | 페이지당 반환할 스니펫의 수입니다. |
| `repository_storage` | 문자열   | 아니요       | 스니펫에서 사용하는 리포지토리 저장소로 필터링합니다 _(관리자만)_. [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419640)됨. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성            | 유형    | 설명 |
|----------------------|---------|-------------|
| `author`             | 객체  | 스니펫 작성자를 나타내는 사용자 객체입니다. |
| `created_at`         | 문자열  | 스니펫이 생성된 날짜 및 시간입니다. |
| `description`        | 문자열  | 스니펫의 설명입니다. |
| `file_name`          | 문자열  | 스니펫 파일의 이름입니다. |
| `files`              | 배열   | 스니펫 파일의 배열입니다. |
| `id`                 | 정수 | 스니펫의 ID입니다. |
| `imported`           | 부울 | `true`이면 스니펫을 가져왔습니다. |
| `imported_from`      | 문자열  | 가져온 출처입니다. |
| `project_id`         | 정수 | 연결된 프로젝트의 ID입니다. 개인 스니펫의 경우 `null`입니다. |
| `raw_url`            | 문자열  | 원본 스니펫 콘텐츠로의 URL입니다. |
| `repository_storage` | 문자열  | 스니펫에서 사용하는 리포지토리 저장소입니다. |
| `title`              | 문자열  | 스니펫의 제목입니다. |
| `updated_at`         | 문자열  | 스니펫이 마지막으로 업데이트된 날짜 및 시간입니다. |
| `visibility`         | 문자열  | 스니펫의 가시성 수준입니다. |
| `web_url`            | 문자열  | GitLab UI의 스니펫에 대한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/all?per_page=2&page=1"
```

응답 예시:

```json
[
  {
    "id": 113,
    "title": "Internal Project Snippet",
    "description": null,
    "visibility": "internal",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:02.480Z",
    "updated_at": "2023-08-03T10:21:02.480Z",
    "project_id": 35,
    "web_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113",
    "raw_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 112,
    "title": "Private Personal Snippet",
    "description": null,
    "visibility": "private",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "created_at": "2023-08-03T10:20:59.994Z",
    "updated_at": "2023-08-03T10:20:59.994Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/112",
    "raw_url": "http://example.com/-/snippets/112/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 111,
    "title": "Public Personal Snippet",
    "description": null,
    "visibility": "public",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:01.312Z",
    "updated_at": "2023-08-03T10:21:01.312Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/111",
    "raw_url": "http://example.com/-/snippets/111/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  }
]
```

## 사용자 에이전트 세부 정보 가져오기 {#get-user-agent-details}

> [!note]
> 관리자만 사용할 수 있습니다.

```plaintext
GET /snippets/:id/user_agent_detail
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명    |
|-----------|---------|----------|----------------|
| `id`      | 정수 | 예      | 스니펫의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `akismet_submitted` | 부울 | `true`인 경우 세부 정보를 Akismet에 제출했습니다. |
| `ip_address`        | 문자열  | 스니펫을 생성하는 데 사용된 IP 주소입니다. |
| `user_agent`        | 문자열  | 스니펫을 생성하는 데 사용된 사용자 에이전트 문자열입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/user_agent_detail"
```

응답 예시:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
