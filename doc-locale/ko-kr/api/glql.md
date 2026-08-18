---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209517).

{{< /history >}}

이 API를 사용하여 [GitLab Query Language(GLQL)](../user/glql/_index.md) 쿼리를 프로그래밍 방식으로 실행합니다. GLQL은 [GitLab 리소스](../user/glql/_index.md#supported-areas)를 검색하고 필터링하기 위한 단순화된 쿼리 언어를 제공하며, 프로젝트와 그룹 전체에서 이슈, 머지 리퀘스트, 에픽 등을 처리합니다.

전제 조건:

- 그룹 또는 프로젝트가 해당 데이터에 대한 액세스를 허용해야 합니다.
- 비공개 그룹 및 프로젝트의 경우 적절한 권한이 있는 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 사용해야 합니다.

## GLQL 쿼리 실행 {#execute-a-glql-query}

GLQL 쿼리를 실행하여 GitLab 리소스를 검색하고 필터링합니다.

```plaintext
POST /glql
```

> [!note]
> 이 엔드포인트는 쿼리 SHA를 기반으로 쿼리의 속도를 제한합니다. 시간 초과되는 동일한 쿼리를 추적하며, 너무 자주 실행되는 경우 일시적으로 차단될 수 있습니다.

지원되는 속성:

| 속성   | 유형   | 필수 | 설명                                                                                                                           |
|-------------|--------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `glql_yaml` | 문자열 | 예      | 선택적 YAML 구성이 포함된 GLQL 쿼리입니다. 최대 크기:  10,000바이트(10KB). [쿼리 형식](#query-formats)을 참조하여 자세한 내용을 확인합니다. |
| `after`     | 문자열 | 아니요       | 페이지 조회용 커서입니다. 이전 쿼리의 `data.pageInfo.endCursor` 값을 사용하여 다음 결과 페이지를 가져옵니다.               |

### 쿼리 형식 {#query-formats}

`glql_yaml` 매개변수는 `query` 키를 사용하는 YAML 형식을 허용합니다:

```yaml
fields: id,title,author
group: my-group
limit: 10
sort: created desc
query: state = opened
```

### 구성 옵션 {#configuration-options}

다음 구성 옵션을 YAML에 포함할 수 있습니다:

| 옵션    | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `fields`  | 문자열  | 아니요       | 반환할 필드의 쉼표 구분 목록입니다. 기본값: `title`. [사용 가능한 필드](#available-fields)를 참조합니다. |
| `group`   | 문자열  | 아니요       | 쿼리를 특정 그룹으로 범위 제한합니다. `project`과 함께 사용할 수 없습니다. `group`도 쿼리에서 지정된 경우 쿼리 값이 우선합니다. |
| `limit`   | 정수 | 아니요       | 반환할 최대 결과 수입니다. 1~100 사이여야 합니다. 기본값: `100`. |
| `project` | 문자열  | 아니요       | 쿼리를 특정 프로젝트로 범위 제한합니다. 형식: `group/project`. `project`도 쿼리에서 지정된 경우 쿼리 값이 우선합니다. |
| `sort`    | 문자열  | 아니요       | 결과의 정렬 순서입니다. 형식: `field direction` (예: `created asc` 또는 `created desc`). |

### 사용 가능한 필드 {#available-fields}

`fields` 구성 옵션은 [GLQL의 사용 가능한 필드](../user/glql/fields.md)로 정의됩니다.

### GLQL 쿼리 구문 {#glql-query-syntax}

쿼리 구문은 [GLQL](../user/glql/_index.md#query-syntax)로 정의됩니다.

### 응답 속성 {#response-attributes}

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                       | 유형    | 설명 |
|---------------------------------|---------|-------------|
| `data`                          | 객체  | 쿼리 결과를 포함합니다. |
| `data.count`                    | 정수 | 일치하는 결과의 총 수입니다. |
| `data.nodes`                    | 배열   | 요청된 필드가 포함된 일치하는 리소스의 배열입니다. |
| `data.pageInfo`                 | 객체  | 페이지 조회 정보입니다. |
| `data.pageInfo.endCursor`       | 문자열  | 다음 결과 페이지를 가져오기 위한 커서입니다. |
| `data.pageInfo.hasNextPage`     | 부울 | 더 많은 결과를 사용할 수 있는지 나타냅니다. |
| `data.pageInfo.hasPreviousPage` | 부울 | 이전 결과를 사용할 수 있는지 나타냅니다. |
| `data.pageInfo.startCursor`     | 문자열  | 이전 결과 페이지를 가져오기 위한 커서입니다. |
| `error`                         | 문자열  | 쿼리가 실패한 경우의 오류 메시지입니다. |
| `fields`                        | 배열   | 필드 정의의 배열입니다. |
| `fields[].key`                  | 문자열  | 고유한 필드 식별자입니다. |
| `fields[].label`                | 문자열  | 사람이 읽을 수 있는 필드 이름입니다. |
| `fields[].name`                 | 문자열  | 유사한 필드를 통합하는 일반적인 필드 이름입니다. 예를 들어 `created` 및 `createdAt` 키는 `createdAt` 이름을 갖습니다. |
| `success`                       | 부울 | 쿼리가 성공했는지 나타냅니다. |

### 예:  기본 쿼리 {#example-basic-query}

그룹에서 열린 이슈 검색:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

응답 예시:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

### 예:  정면 구성이 있는 쿼리 {#example-query-with-front-matter-configuration}

사용자 지정 필드 및 정렬을 사용하여 검색:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,author,state\ngroup: my-group\nlimit: 5\nsort: created desc\nquery: state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

응답 예시:

```json
{
  "data": {
    "count": 2,
    "nodes": [
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/123",
          "name": "John Doe",
          "username": "johndoe",
          "webUrl": "https://gitlab.example.com/johndoe"
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      },
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/122",
          "name": "Jane Doe",
          "username": "janedoe",
          "webUrl": "https://gitlab.example.com/janedoe"
        },
        "id": "gid://gitlab/Issue/122",
        "iid": "122",
        "reference": "#122",
        "state": "OPEN",
        "title": "HTTP server examples for all programming languages",
        "webUrl": "https://gitlab.example.com/groups/my-group/-/issues/122",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "author",
      "label": "Author",
      "name": "author"
    },
    {
      "key": "state",
      "label": "State",
      "name": "state"
    }
  ],
  "success": true
}
```

### 예:  프로젝트 범위가 있는 쿼리 {#example-query-with-project-scope}

특정 프로젝트에서 검색:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: project = \"my-group/my-project\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

### 예:  `currentUser()` 함수가 있는 쿼리 {#example-query-with-currentuser-function}

현재 사용자에게 할당된 이슈 검색:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,assignees\nquery: group = \"my-group\" AND assignee = currentUser()"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

응답 예시:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "assignees": {
          "nodes": [
            {
              "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
              "id": "gid://gitlab/User/123",
              "name": "John Doe",
              "username": "johndoe",
              "webUrl": "https://gitlab.example.com/johndoe"
            }
          ]
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees"
    }
  ],
  "success": true
}
```

### 예:  제한 및 페이지 조회가 있는 쿼리 {#example-query-with-limit-and-pagination}

제한된 수의 결과를 검색하고 페이지를 통해 조회합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

응답 예시:

```json
{
  "data": {
    "count": 68,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/321",
        "iid": "321",
        "reference": "#321",
        "state": "OPEN",
        "title": "Corrupti consectetur impedit non blanditiis hic vitae minus.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/321",
        "widgets": null
      },
      {
        "id": "gid://gitlab/WorkItem/322",
        "iid": "322",
        "reference": "#322",
        "state": "OPEN",
        "title": "Ipsa cupiditate corrupti vel maxime quasi at assumenda repellat quod.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/322",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjIifQ==",
      "hasNextPage": true,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

다음 페이지를 가져오려면 이전 응답의 `endCursor` 값을 사용하세요:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened",
    "after": "eyJpZCI6IjIifQ=="
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

## 속도 제한 {#rate-limiting}

GLQL API는 쿼리의 SHA-256 해시를 기반으로 하는 속도 제한을 구현합니다. 시간 초과되는 쿼리를 추적합니다. 특정 쿼리가 시간 초과되고 너무 자주 실행되면 일시적으로 차단됩니다.

속도 제한이 적용되면 API는 `429 Too Many Requests` 상태 코드와 오류 메시지를 반환합니다:

```json
{
  "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
}
```

## 오류 처리 {#error-handling}

API는 다음 HTTP 상태 코드를 반환합니다:

| 상태 코드                 | 설명 |
|-----------------------------|-------------|
| `200 Success`               | 쿼리가 성공적으로 실행되었습니다. |
| `400 Bad Request`           | 잘못된 쿼리 구문, 필수 매개변수 누락 또는 입력이 크기 제한을 초과합니다. |
| `401 Unauthorized`          | 인증이 필요하거나 자격 증명이 잘못되었습니다. |
| `403 Forbidden`             | 권한이 부족하거나 필수 OAuth 범위가 누락되었습니다. |
| `429 Too Many Requests`     | 쿼리 속도 제한을 초과했습니다. |
| `500 Internal Server Error` | 쿼리 실행 중 서버 오류입니다. |

### 오류 응답 예시 {#error-response-examples}

- 필수 매개변수 누락:

  ```json
  {
    "error": "glql_yaml is missing, glql_yaml is empty"
  }
  ```

- 잘못된 GLQL 구문:

  ```json
  {
    "error": "400 Bad request - Error: Unexpected `invalid syntax @@@ ###`, expected operator (one of IN, =, !=, >, or <)"
  }
  ```

- 입력 크기 초과:

  ```json
  {
    "error": "400 Bad request - Input exceeds maximum size"
  }
  ```

- 존재하지 않는 프로젝트:

  ```json
  {
    "error": "400 Bad request - Error: Project does not exist or you do not have access to it"
  }
  ```

- 존재하지 않는 그룹:

  ```json
  {
    "error": "400 Bad request - Error: Group does not exist or you do not have access to it"
  }
  ```

- 속도 제한 초과:

  ```json
  {
    "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
  }
  ```

- 잘못된 필드

  ```json
  {
    "error": "Field 'title' doesn't exist on type 'WorkItem' (Did you mean `title`?)"
  }
  ```

> [!note]
> GraphQL 잘못된 요청 오류는 해당할 때 `400` 오류 코드와 함께 API `error` 필드로 전달됩니다.

## 제한 및 제약 조건 {#limits-and-constraints}

GLQL API에는 다음 제한이 있습니다:

- 최대 입력 크기:  `glql_yaml` 매개변수의 경우 10,000바이트(10KB)입니다.
- 최대 쿼리 제한:  요청당 100개의 결과입니다.
- 기본 제한:  지정되지 않은 경우 100개의 결과입니다.
- 페이지 조회:  `after` 속성과 이전 응답의 `endCursor` 값을 사용하는 정방향 페이지 조회만 지원됩니다.
- 속도 제한:  쿼리는 쿼리 SHA-256 해시를 기반으로 속도 제한됩니다.

## 관련 항목 {#related-topics}

- [GLQL 쿼리 언어 설명서](../user/glql/_index.md)
- [REST API 인증](rest/authentication.md)
- [OAuth 2.0 인증](oauth2.md)
