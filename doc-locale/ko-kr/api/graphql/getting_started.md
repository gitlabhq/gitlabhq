---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL API 쿼리 및 뮤테이션 실행
description: "예제를 포함한 GraphQL 쿼리 및 뮤테이션 실행 가이드입니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 가이드는 GitLab GraphQL API의 기본 사용 방법을 보여줍니다.

## 실행 예제 {#running-examples}

여기에 설명된 예제는 다음 방법으로 실행할 수 있습니다:

- [GraphiQL](#graphiql).
- [명령 줄](#command-line).
- [Rails 콘솔](#rails-console).

### GraphiQL {#graphiql}

GraphiQL('그래피컬'로 발음됨)은 API에 대해 실제 GraphQL 쿼리를 대화형으로 실행할 수 있게 해줍니다. 구문 강조 및 자동 완성 기능이 있는 UI를 제공하여 스키마 탐색을 더 쉽게 만듭니다.

대부분의 사용자에게 GraphiQL을 사용하는 것이 GitLab GraphQL API를 탐색하는 가장 쉬운 방법입니다.

GraphiQL은 다음 방법으로 사용할 수 있습니다:

- [GitLab.com](https://gitlab.com/-/graphql-explorer)에서.
- GitLab Self-Managed에서 `https://<your-gitlab-site.com>/-/graphql-explorer`.

GitLab 계정으로 요청을 인증하려면 먼저 GitLab에 로그인하세요.

시작하려면 [예제 쿼리 및 뮤테이션](#queries-and-mutations)을 참조하세요.

### 명령 줄 {#command-line}

로컬 컴퓨터의 명령 줄에서 `curl` 요청으로 GraphQL 쿼리를 실행할 수 있습니다. 요청은 쿼리를 페이로드로 사용하여 `POST`에서 `/api/graphql`로 전송됩니다. [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을 생성하여 베어러 토큰으로 사용하여 요청에 권한을 부여할 수 있습니다. [GraphQL 인증](_index.md#authentication)에 대해 더 자세히 알아보세요.

예: 

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

쿼리 문자열에 문자열을 중첩하려면 데이터를 단일 따옴표로 묶거나 문자열을 ` \\ `로 이스케이프하세요:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"query": "query {project(fullPath: \"<group>/<subgroup>/<project>\") {jobs {nodes {id duration}}}}"}'
  # or "{\"query\": \"query {project(fullPath: \\\"<group>/<subgroup>/<project>\\\") {jobs {nodes {id duration}}}}\"}"
```

### Rails 콘솔 {#rails-console}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL 쿼리는 [Rails 콘솔 세션](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 실행할 수 있습니다. 예를 들어 프로젝트를 검색하려면 다음과 같이 합니다:

```ruby
current_user = User.find_by_id(1)
query = <<~EOQ
query securityGetProjects($search: String!) {
  projects(search: $search) {
    nodes {
      path
    }
  }
}
EOQ

variables = { "search": "gitlab" }

result = GitlabSchema.execute(query, variables: variables, context: { current_user: current_user })
result.to_h
```

## 쿼리 및 뮤테이션 {#queries-and-mutations}

GitLab GraphQL API는 다음을 수행하는 데 사용할 수 있습니다:

- 데이터 검색을 위한 쿼리입니다.
- 데이터를 생성, 업데이트 및 삭제하기 위한 [뮤테이션](#mutations)입니다.

> [!note]
> GitLab GraphQL API에서 `id`은 [Global ID](https://graphql.org/learn/global-object-identification/)를 의미하며, 이는 `"gid://gitlab/Issue/123"` 형식의 객체 식별자입니다. 자세한 내용은 [Global IDs](_index.md#global-ids)를 참조하세요.

[GitLab GraphQL 스키마](reference/_index.md)는 클라이언트가 쿼리할 수 있는 객체 및 필드와 해당 데이터 유형을 설명합니다.

예:  `gitlab-org` 그룹에서 현재 인증된 사용자가 액세스할 수 있는 모든 프로젝트의 이름만 가져옵니다(제한까지).

```graphql
query {
  group(fullPath: "gitlab-org") {
    id
    name
    projects {
      nodes {
        name
      }
    }
  }
}
```

예:  특정 프로젝트 및 이슈 #2의 제목을 가져옵니다.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issue(iid: "2") {
      title
    }
  }
}
```

### 그래프 순회 {#graph-traversal}

자식 노드를 검색할 때는 다음을 사용하세요:

- `edges { node { } }` 구문입니다.
- 짧은 형식의 `nodes { }` 구문입니다.

모든 것의 기초는 순회하는 그래프이며, GraphQL이라는 이름의 유래입니다.

예:  프로젝트의 이름과 모든 이슈의 제목을 가져옵니다.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues {
      nodes {
        title
        description
      }
    }
  }
}
```

쿼리에 대해 더 알아보기:  [GraphQL 설명서](https://graphql.org/learn/queries/)

### 인증 {#authorization}

GitLab에 로그인하고 [GraphiQL](#graphiql)을 사용하면 모든 쿼리는 인증된 사용자로서 수행됩니다. 자세한 내용은 [GraphQL 인증](_index.md#authentication)에 대해 알아보세요.

### 뮤테이션 {#mutations}

뮤테이션은 데이터를 변경합니다. 업데이트, 삭제 또는 새 레코드를 생성할 수 있습니다. 뮤테이션은 일반적으로 InputType 및 변수를 사용하며, 둘 다 여기에 나타나지 않습니다.

뮤테이션의 구성:

- 입력입니다. 예를 들어, 추가하려는 이모지 반응 및 추가할 객체와 같은 인수입니다.
- 반환 문입니다. 즉, 성공했을 때 되돌려받을 내용입니다.
- 오류입니다. 항상 무엇이 잘못되었는지 요청하세요. 만일에 대비해서입니다.

#### 생성 뮤테이션 {#creation-mutations}

예:  차를 좀 마시자 - 이슈에 `:tea:` 반응 이모지를 추가합니다.

```graphql
mutation {
  awardEmojiAdd(input: { awardableId: "gid://gitlab/Issue/27039960",
      name: "tea"
    }) {
    awardEmoji {
      name
      description
      unicode
      emoji
      unicodeVersion
      user {
        name
      }
    }
    errors
  }
}
```

예:  이슈에 댓글을 추가합니다. 이 예제는 `GitLab.com` 이슈의 ID를 사용합니다. 로컬 인스턴스를 사용하는 경우 쓰기 권한이 있는 이슈의 ID를 가져와야 합니다.

```graphql
mutation {
  createNote(input: { noteableId: "gid://gitlab/Issue/27039960",
      body: "*sips tea*"
    }) {
    note {
      id
      body
      discussion {
        id
      }
    }
    errors
  }
}
```

#### 업데이트 뮤테이션 {#update-mutations}

생성한 노트의 `id` 결과가 표시되면 기록해 둡니다. 더 빨리 마시도록 편집해 봅시다.

```graphql
mutation {
  updateNote(input: { id: "gid://gitlab/Note/<note ID>",
      body: "*SIPS TEA*"
    }) {
    note {
      id
      body
    }
    errors
  }
}
```

#### 삭제 뮤테이션 {#deletion-mutations}

우리의 차가 다 떨어졌으니까 댓글을 삭제합시다.

```graphql
mutation {
  destroyNote(input: { id: "gid://gitlab/Note/<note ID>" }) {
    note {
      id
      body
    }
    errors
  }
}
```

다음과 같은 출력을 받아야 합니다:

```json
{
  "data": {
    "destroyNote": {
      "errors": [],
      "note": null
    }
  }
}
```

요청한 노트가 더 이상 존재하지 않으므로 해당 필드에 대해 반환된 값은 `null`입니다.

뮤테이션에 대해 더 알아보기:  [GraphQL 설명서](https://graphql.org/learn/queries/#mutations).

### 프로젝트 설정 업데이트 {#update-project-settings}

단일 GraphQL 뮤테이션에서 여러 프로젝트 설정을 업데이트할 수 있습니다. 이 예제는 `CI_JOB_TOKEN` 범위 지정 동작에서 [주요 변경 사항](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)에 대한 해결 방법입니다.

```graphql
mutation DisableCI_JOB_TOKENscope {
  projectCiCdSettingsUpdate(input:{fullPath: "<namespace>/<project-name>", inboundJobTokenScopeEnabled: false}) {
    ciCdSettings {
      inboundJobTokenScopeEnabled
    }
    errors
  }
}
```

### 내부 검사 쿼리 {#introspection-queries}

클라이언트는 [내부 검사 쿼리](https://graphql.org/learn/introspection/)를 만들어 GraphQL 엔드포인트에서 스키마에 대한 정보를 쿼리할 수 있습니다. 이러한 쿼리는 발견 및 진단 도구로 사용하기 위한 것입니다.

- 개발 및 테스트 환경에서 내부 검사 쿼리는 실시간 스키마에 대해 실행됩니다.
- 프로덕션 환경에서 내부 검사 쿼리는 정적 스키마를 반환합니다.
  - 프로덕션 환경에서 내부 검사 쿼리를 사용하여 데이터를 가져오면 안 됩니다. 자세한 정보는 다음을 참조하세요:
    - [프로덕션의 GraphQL 내부 검사](https://graphql.org/learn/introspection/#introspection-in-production)
    - [프로덕션의 Apollo 내부 검사](https://www.apollographql.com/blog/why-you-should-disable-graphql-introspection-in-production#what-do-we-need-introspection-for)
  - 모든 내부 검사 쿼리는 요청 메서드나 매개변수에 관계없이 동일한 정적 응답을 반환합니다.
  - 정적 스키마는 현재 스키마와 일치하도록 자동으로 업데이트됩니다.
  - 내부 검사 쿼리는 다음 두 개의 정적 스키마 파일 중 하나를 반환합니다:
    - `public/-/graphql/introspection_result.json`:  사용되지 않는 필드를 포함한 전체 스키마입니다.
    - `public/-/graphql/introspection_result_no_deprecated.json`:  사용되지 않는 필드가 없는 스키마입니다.

스키마를 요청하려면 요청 본문에 다음을 보내세요:

```json
{
  "query": "{ __schema { types { name } } }"
}
```

사용되지 않는 필드 없이 스키마를 요청하려면 요청 본문에 `remove_deprecated: true`을 포함하세요:

```json
{
  "query": "{ __schema { types { name } } }",
  "remove_deprecated": true
}
```

#### GraphiQL 내부 검사 쿼리 {#graphiql-introspection-queries}

[GraphiQL 쿼리 탐색기](#graphiql)는 내부 검사 쿼리를 사용하여:

- GitLab GraphQL 스키마에 대한 지식을 얻습니다.
- 자동 완성을 수행합니다.
- 대화형 `Docs` 탭을 제공합니다.

내부 검사에 대해 더 알아보기:  [GraphQL 설명서](https://graphql.org/learn/introspection/)

### 쿼리 복잡성 {#query-complexity}

계산된 [복잡성 점수 및 제한](_index.md#maximum-query-complexity)은 `queryComplexity`을 쿼리하여 클라이언트에 표시할 수 있습니다.

```graphql
query {
  queryComplexity {
    score
    limit
  }

  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
  }
}
```

## 정렬 {#sorting}

일부 GitLab GraphQL 엔드포인트를 사용하면 객체 컬렉션을 정렬하는 방법을 지정할 수 있습니다. 스키마에서 허용하는 항목으로만 정렬할 수 있습니다.

예:  이슈는 생성 날짜로 정렬할 수 있습니다:

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
   name
    issues(sort: created_asc) {
      nodes {
        title
        createdAt
      }
    }
  }
}
```

## 페이지 매김 {#pagination}

페이지 매김은 처음 10개와 같이 레코드의 부분 집합만 요청하는 방법입니다. 더 많이 원하면 `give me the next ten records`과 같은 형식으로 서버에서 다음 10개에 대한 다른 요청을 만들 수 있습니다.

기본적으로 GitLab GraphQL API는 페이지당 100개의 레코드를 반환합니다. 이 동작을 변경하려면 `first` 또는 `last` 인수를 사용하세요. 두 인수 모두 값을 사용하므로 `first: 10`은 처음 10개의 레코드를 반환하고 `last: 10`는 마지막 10개의 레코드를 반환합니다. 페이지당 반환되는 레코드 수에는 제한이 있으며, 일반적으로 `100`입니다.

예:  처음 두 이슈만 검색합니다(슬라이싱). `cursor` 필드는 해당 위치를 기준으로 추가 레코드를 검색할 수 있는 위치를 제공합니다.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 2) {
      edges {
        node {
          title
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

예:  다음 3개를 검색합니다. (`eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0` 커서 값은 다를 수 있지만, 위에서 반환한 두 번째 이슈에 대해 반환된 `cursor` 값입니다.)

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 3, after: "eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0") {
      edges {
        node {
          title
        }
        cursor
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

페이지 매김 및 커서에 대해 더 알아보기:  [GraphQL 설명서](https://graphql.org/learn/pagination/)

## 파일 업로드 {#file-uploads}

일부 뮤테이션은 파일 업로드를 인수로 허용합니다. 이러한 뮤테이션은 [GraphQL 다중 부분 요청 사양](https://github.com/jaydenseric/graphql-multipart-request-spec)을 사용하며, 이를 통해 `multipart/form-data` 요청을 사용하여 GraphQL 작업과 함께 파일을 보낼 수 있습니다.

파일 업로드를 지원하는 뮤테이션에는 `Upload` 유형의 인수가 있습니다. `Upload` 스칼라 유형의 인수를 찾아 [GraphQL API 참조](reference/_index.md)에서 이러한 뮤테이션을 식별할 수 있습니다.

파일 업로드 뮤테이션은 [GraphiQL](#graphiql)을 통해 실행할 수 없습니다. `curl`과 같은 [명령 줄](#command-line) 도구 또는 호환되는 GraphQL 클라이언트 라이브러리를 사용해야 합니다.

다중 부분 업로드 요청에는 3가지 주요 부분이 있습니다:

- `operations`:  GraphQL 쿼리 및 변수를 포함하는 JSON 문자열이며, 파일 값은 `null`로 설정됩니다.
- `map`:  파일 키를 작업의 변수 경로로 매핑하는 JSON 객체입니다.
- `map`에서 사용하는 키로 참조되는 파일 필드 자체입니다.

`designManagementUpload` 뮤테이션을 사용하여 이슈에 디자인을 업로드하려면:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"]}' \
  --form '0=@/path/to/your/design.png'
```

`workItemsCsvImport` 뮤테이션을 사용하여 CSV 파일에서 작업 항목을 가져오려면:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($projectPath: ID!, $file: Upload!) { workItemsCsvImport(input: { projectPath: $projectPath, file: $file }) { message errors } }", "variables": {"projectPath": "<group>/<project>", "file": null}}' \
  --form 'map={"0": ["variables.file"]}' \
  --form '0=@/path/to/your/work-items.csv'
```

단일 요청에서 여러 파일을 업로드하려면 `map`과 양식 필드 모두에 추가 항목을 추가하세요:

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null, null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"], "1": ["variables.files.1"]}' \
  --form '0=@/path/to/first-design.png' \
  --form '1=@/path/to/second-design.png'
```

## 쿼리 URL 변경 {#changing-the-query-url}

경우에 따라 GraphQL 요청을 다른 URL로 보내야 합니다. 예를 들어 `GeoNode` 쿼리는 보조 Geo 사이트 URL에 대해서만 작동합니다.

GraphiQL 탐색기의 GraphQL 요청 URL을 변경하려면 GraphiQL의 헤더 영역(왼쪽 아래 영역, 변수가 있는 바로 옆)에서 사용자 지정 헤더를 설정하세요:

```json
{
  "REQUEST_PATH": "<the URL to make the graphQL request against>"
}
```
