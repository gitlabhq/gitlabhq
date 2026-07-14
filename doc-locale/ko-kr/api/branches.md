---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 Git 브랜치를 위한 REST API 문서입니다.
title: 브랜치 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Git 브랜치](../user/project/repository/branches/_index.md)를 관리합니다.

프로젝트에 구성된 [브랜치 보호 API](protected_branches.md)를 변경하려면 해당 API를 사용합니다.

## 모든 리포지토리 브랜치 나열 {#list-all-repository-branches}

프로젝트의 모든 리포지토리 브랜치를 알파벳 순서로 정렬하여 나열합니다. 이름으로 검색하거나 정규 표현식을 사용하여 특정 브랜치 패턴을 찾습니다. 보호 상태, 병합 상태, 커밋 세부 정보를 포함한 브랜치에 대한 상세 정보를 반환합니다.

> [!note]
> 리포지토리가 공개적으로 접근 가능한 경우 인증 없이 이 엔드포인트에 접근할 수 있습니다.

```plaintext
GET /projects/:id/repository/branches
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `regex`   | 문자열            | 아니요       | [re2](https://github.com/google/re2/wiki/Syntax) 정규 표현식과 일치하는 이름의 브랜치 목록을 반환합니다. `search`과 함께 사용할 수 없습니다. |
| `search`  | 문자열            | 아니요       | 검색 문자열을 포함하는 브랜치 목록을 반환합니다. `^term`를 사용하여 `term`로 시작하는 브랜치를 찾을 수 있고, `term$`을 사용하여 `term`로 끝나는 브랜치를 찾을 수 있습니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성                  | 유형                | 설명 |
|----------------------------|---------------------|-------------|
| `can_push`                 | 부울             | `true`인 경우 인증된 사용자가 이 브랜치에 푸시할 수 있습니다. |
| `commit`                   | 객체              | 브랜치의 가장 최근 커밋에 대한 세부 정보입니다. |
| `commit.author_email`      | 문자열              | 변경 사항을 작성한 사용자의 이메일 주소입니다. |
| `commit.author_name`       | 문자열              | 변경 사항을 작성한 사용자의 이름입니다. |
| `commit.authored_date`     | 날짜/시간(ISO 8601) | 커밋이 작성된 시점입니다. |
| `commit.committed_date`    | 날짜/시간(ISO 8601) | 커밋이 커밋된 시점입니다. |
| `commit.committer_email`   | 문자열              | 변경 사항을 커밋한 사용자의 이메일 주소입니다. |
| `commit.committer_name`    | 문자열              | 변경 사항을 커밋한 사용자의 이름입니다. |
| `commit.created_at`        | 날짜/시간(ISO 8601) | 커밋이 생성된 시점입니다. |
| `commit.extended_trailers` | 객체              | 커밋 메시지에서 분석된 확장 Git 트레일러입니다. |
| `commit.id`                | 문자열              | 커밋의 전체 SHA입니다. |
| `commit.message`           | 문자열              | 전체 커밋 메시지입니다. |
| `commit.parent_ids`        | 배열               | 상위 커밋 SHA의 배열입니다. |
| `commit.short_id`          | 문자열              | 커밋의 약식 SHA입니다. |
| `commit.title`             | 문자열              | 커밋 메시지의 제목입니다. |
| `commit.trailers`          | 객체              | 커밋 메시지에서 분석된 Git 트레일러입니다. |
| `commit.web_url`           | 문자열              | GitLab UI에서 커밋을 보기 위한 URL입니다. |
| `default`                  | 부울             | `true`인 경우 이 브랜치는 프로젝트의 기본 브랜치입니다. |
| `developers_can_merge`     | 부울             | `true`인 경우 Developer, Maintainer 또는 Owner 역할을 가진 사용자가 이 브랜치에 병합할 수 있습니다. |
| `developers_can_push`      | 부울             | `true`인 경우 Developer, Maintainer 또는 Owner 역할을 가진 사용자가 이 브랜치에 푸시할 수 있습니다. |
| `merged`                   | 부울             | `true`인 경우 이 브랜치는 기본 브랜치로 병합되었습니다. |
| `name`                     | 문자열              | 브랜치의 이름입니다. |
| `protected`                | 부울             | `true`인 경우 이 브랜치는 강제 푸시 및 삭제로부터 보호됩니다. |
| `web_url`                  | 문자열              | GitLab UI에서 브랜치를 보기 위한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

응답 예시:

```json
[
  {
    "name": "main",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "created_at": "2024-06-28T03:44:20-07:00",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ],
      "title": "add projects API",
      "message": "add projects API",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2024-06-27T05:51:39-07:00",
      "committer_name": "John Smith",
      "committer_email": "john@example.com",
      "committed_date": "2024-06-28T03:44:20-07:00",
      "trailers": {},
      "extended_trailers": {},
      "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
    }
  },
  ...
]
```

## 리포지토리 브랜치 검색 {#retrieve-a-repository-branch}

지정된 프로젝트 리포지토리 브랜치를 검색합니다.

> [!note]
> 리포지토리가 공개적으로 접근 가능한 경우 인증 없이 이 엔드포인트에 접근할 수 있습니다.

```plaintext
GET /projects/:id/repository/branches/:branch
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `branch`  | 문자열            | 예      | 브랜치의 [URL 인코딩된 이름](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성                | 유형    | 설명 |
|--------------------------|---------|-------------|
| `can_push`               | 부울 | 인증된 사용자가 이 브랜치에 푸시할 수 있는지 여부입니다. |
| `commit`                 | 객체  | 브랜치의 최신 커밋에 대한 세부 정보입니다. |
| `commit.author_email`    | 문자열  | 커밋 작성자의 이메일 주소입니다. |
| `commit.author_name`     | 문자열  | 커밋 작성자의 이름입니다. |
| `commit.authored_date`   | 문자열  | 커밋이 작성된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.committer_email` | 문자열  | 변경 사항을 커밋한 사용자의 이메일 주소입니다. |
| `commit.committer_name`  | 문자열  | 변경 사항을 커밋한 사용자의 이름입니다. |
| `commit.committed_date`  | 문자열  | 커밋이 커밋된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.created_at`      | 문자열  | 커밋이 생성된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.extended_trailers` | 객체  | 커밋 메시지에서 분석된 확장 Git 트레일러입니다. |
| `commit.id`              | 문자열  | 커밋의 전체 SHA입니다. |
| `commit.message`         | 문자열  | 전체 커밋 메시지입니다. |
| `commit.parent_ids`      | 배열   | 상위 커밋 SHA의 배열입니다. |
| `commit.short_id`        | 문자열  | 커밋의 약식 SHA입니다. |
| `commit.title`           | 문자열  | 커밋 메시지의 제목입니다. |
| `commit.trailers`        | 객체  | 커밋 메시지에서 분석된 Git 트레일러입니다. |
| `commit.web_url`         | 문자열  | GitLab UI에서 커밋을 보기 위한 URL입니다. |
| `default`                | 부울 | 이것이 프로젝트의 기본 브랜치인지 여부입니다. |
| `developers_can_merge`   | 부울 | Developer 역할을 가진 사용자가 이 브랜치에 병합할 수 있는지 여부입니다. |
| `developers_can_push`    | 부울 | Developer 역할을 가진 사용자가 이 브랜치에 푸시할 수 있는지 여부입니다. |
| `merged`                 | 부울 | 이 브랜치가 기본 브랜치로 병합되었는지 여부입니다. |
| `name`                   | 문자열  | 브랜치의 이름입니다. |
| `protected`              | 부울 | 이 브랜치가 강제 푸시 및 삭제로부터 보호되는지 여부입니다. |
| `web_url`                | 문자열  | GitLab UI에서 브랜치를 보기 위한 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

응답 예시:

```json
{
  "name": "main",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  }
}
```

## 리포지토리 브랜치 보호 {#protect-repository-branch}

리포지토리 브랜치 보호에 대한 정보는 [`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches)를 참조하세요.

## 리포지토리 브랜치 보호 해제 {#unprotect-repository-branch}

리포지토리 브랜치 보호 해제에 대한 정보는 [`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches)를 참조하세요.

## 리포지토리 브랜치 생성 {#create-repository-branch}

리포지토리에 새 브랜치를 생성합니다.

```plaintext
POST /projects/:id/repository/branches
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `branch`  | 문자열            | 예      | 브랜치의 이름입니다. 공백이나 특수 문자(하이픈 및 언더스코어 제외)를 포함할 수 없습니다. |
| `ref`     | 문자열            | 예      | 브랜치를 생성할 브랜치 이름 또는 커밋 SHA입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성                  | 유형    | 설명 |
|----------------------------|---------|-------------|
| `can_push`                 | 부울 | `true`인 경우 인증된 사용자가 이 브랜치에 푸시할 수 있습니다. |
| `commit`                   | 객체  | 브랜치의 최신 커밋에 대한 세부 정보입니다. |
| `commit.author_email`      | 문자열  | 커밋 작성자의 이메일 주소입니다. |
| `commit.author_name`       | 문자열  | 커밋 작성자의 이름입니다. |
| `commit.authored_date`     | 문자열  | 커밋이 작성된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.committed_date`    | 문자열  | 커밋이 커밋된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.committer_email`   | 문자열  | 변경 사항을 커밋한 사용자의 이메일 주소입니다. |
| `commit.committer_name`    | 문자열  | 변경 사항을 커밋한 사용자의 이름입니다. |
| `commit.created_at`        | 문자열  | 커밋이 생성된 날짜 및 시간(ISO 8601 형식)입니다. |
| `commit.extended_trailers` | 객체  | 커밋 메시지에서 분석된 확장 Git 트레일러입니다. |
| `commit.id`                | 문자열  | 커밋의 전체 SHA입니다. |
| `commit.message`           | 문자열  | 전체 커밋 메시지입니다. |
| `commit.parent_ids`        | 배열   | 상위 커밋 SHA의 배열입니다. |
| `commit.short_id`          | 문자열  | 커밋의 약식 SHA입니다. |
| `commit.title`             | 문자열  | 커밋 메시지의 제목입니다. |
| `commit.trailers`          | 객체  | 커밋 메시지에서 분석된 Git 트레일러입니다. |
| `commit.web_url`           | 문자열  | GitLab UI에서 커밋을 보기 위한 URL입니다. |
| `default`                  | 부울 | `true`인 경우 이 브랜치를 프로젝트의 기본 브랜치로 설정합니다. |
| `developers_can_merge`     | 부울 | `true`인 경우 Developer 역할을 가진 사용자가 이 브랜치에 병합할 수 있습니다. |
| `developers_can_push`      | 부울 | `true`인 경우 Developer 역할을 가진 사용자가 이 브랜치에 푸시할 수 있습니다. |
| `merged`                   | 부울 | `true`인 경우 이 브랜치는 기본 브랜치로 병합됩니다. |
| `name`                     | 문자열  | 브랜치의 이름입니다. |
| `protected`                | 부울 | `true`인 경우 이 브랜치는 강제 푸시 및 삭제로부터 보호됩니다. |
| `web_url`                  | 문자열  | GitLab UI에서 브랜치를 보기 위한 URL입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

응답 예시:

```json
{
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/newbranch"
}
```

## 리포지토리 브랜치 삭제 {#delete-repository-branch}

리포지토리에서 지정된 브랜치를 삭제합니다.

> [!note]
> 오류 발생 시 설명 메시지가 제공됩니다.

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `branch`  | 문자열            | 예      | 브랜치의 [URL 인코딩된 이름](rest/_index.md#namespaced-paths)입니다. 기본 브랜치 또는 보호된 브랜치는 삭제할 수 없습니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

> [!note]
> 브랜치 삭제가 관련된 모든 데이터를 완전히 삭제하지는 않습니다. 프로젝트 기록을 유지하고 복구 프로세스를 지원하기 위해 일부 정보가 계속 유지됩니다. 자세한 내용은 [민감한 정보 처리](../topics/git/undo.md#handle-sensitive-information)를 참조하세요.

## 병합된 모든 브랜치 삭제 {#delete-all-merged-branches}

프로젝트의 기본 브랜치로 병합된 모든 브랜치를 삭제합니다.

> [!note]
> [보호된 브랜치](../user/project/repository/branches/protected.md)는 이 작업의 일부로 삭제되지 않습니다.

```plaintext
DELETE /projects/:id/repository/merged_branches
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |

성공하면 [`202 Accepted`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## 관련 항목 {#related-topics}

- [브랜치](../user/project/repository/branches/_index.md)
- [보호된 브랜치](../user/project/repository/branches/protected.md)
- [보호된 브랜치 API](protected_branches.md)
