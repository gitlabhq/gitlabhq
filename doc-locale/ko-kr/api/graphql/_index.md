---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab과의 프로그래밍 방식의 상호작용입니다.
title: GraphQL API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GraphQL](https://graphql.org/)은 API를 위한 쿼리 언어입니다. 필요한 정확한 데이터를 요청할 수 있으므로 필요한 요청 수를 제한할 수 있습니다.

GraphQL 데이터는 유형으로 정렬되므로 클라이언트는 [클라이언트 측 GraphQL 라이브러리](https://graphql.org/community/tools-and-libraries/)를 사용하여 API를 사용하고 수동 구문 분석을 피할 수 있습니다.

GraphQL API는 [버전이 없습니다](https://graphql.org/learn/schema-design/#versioning).

## 시작하기 {#getting-started}

GitLab GraphQL API를 처음 사용하는 경우 [GitLab GraphQL API 시작하기](getting_started.md)를 참조하세요.

[GraphQL API 참조](reference/_index.md)에서 사용 가능한 리소스를 볼 수 있습니다.

GitLab GraphQL API 엔드포인트는 `/api/graphql`에 위치합니다.

### 대화형 GraphQL 탐색기 {#interactive-graphql-explorer}

대화형 GraphQL 탐색기를 사용하여 GraphQL API를 탐색하세요:

- [GitLab.com](https://gitlab.com/-/graphql-explorer).
- GitLab Self-Managed의 경우 `https://<your-gitlab-site.com>/-/graphql-explorer`.

자세한 정보는 [GraphiQL](getting_started.md#graphiql)을 참조하세요.

### GraphQL 예제 보기 {#view-graphql-examples}

GitLab.com의 공개 프로젝트에서 데이터를 가져오는 샘플 쿼리로 작업할 수 있습니다:

- [감사 보고서 생성](audit_report.md)
- [이슈 보드 식별](sample_issue_boards.md)
- [사용자 쿼리](users_example.md)
- [사용자 정의 이모지 사용](custom_emoji.md)

[시작하기](getting_started.md) 페이지에는 GraphQL 쿼리를 사용자 정의하는 다양한 방법이 포함되어 있습니다.

### 인증 {#authentication}

인증 없이 일부 쿼리에 액세스할 수 있지만 다른 쿼리는 인증이 필요합니다. 변형(Mutation)은 항상 인증이 필요합니다.

다음 중 하나를 사용하여 인증할 수 있습니다:

- [토큰](#token-authentication)
- [세션 쿠키](#session-cookie-authentication)

인증 정보가 유효하지 않으면 GitLab은 상태 코드 `401`인 오류 메시지를 반환합니다:

```json
{"errors":[{"message":"Invalid token"}]}
```

#### 토큰 인증 {#token-authentication}

GraphQL API로 인증하려면 다음 토큰 중 하나를 사용하세요:

- [OAuth 2.0 토큰](../oauth2.md)
- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)
- [그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)

[요청 헤더](#header-authentication) 또는 [매개변수](#parameter-authentication)를 통해 토큰을 전달하여 인증합니다.

토큰에는 올바른 [범위](#token-scopes)가 필요합니다.

##### 헤더 인증 {#header-authentication}

`Authorization: Bearer <token>` 요청 헤더를 사용하는 토큰 인증의 예:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer <token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### 매개변수 인증 {#parameter-authentication}

`access_token` 매개변수에서 OAuth 2.0 토큰을 사용하는 예:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?access_token=<oauth_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

`private_token` 매개변수를 사용하여 개인, 프로젝트 또는 그룹 액세스 토큰을 전달할 수 있습니다:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?private_token=<access_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### 토큰 범위 {#token-scopes}

토큰은 GraphQL API에 액세스하기 위해 올바른 범위를 가져야 합니다:

| 범위      | 액세스 |
|------------|--------|
| `read_api` | API에 대한 읽기 액세스 권한을 부여합니다. 쿼리에 충분합니다. |
| `api`      | API에 대한 읽기 및 쓰기 액세스 권한을 부여합니다. 변형(Mutation)에 필요합니다. |

#### 세션 쿠키 인증 {#session-cookie-authentication}

GitLab 주 애플리케이션에 로그인하면 `_gitlab_session` 세션 쿠키가 설정됩니다.

[대화형 GraphQL 탐색기](#interactive-graphql-explorer)와 GitLab 웹 프론트엔드는 이 인증 방법을 사용합니다.

### 인가 {#authorization}

인증 후 GraphQL API는 요청한 각 리소스에 대한 권한을 확인합니다. API가 인가 실패를 보고하는 방식은 작업 유형에 따라 다릅니다.

#### 쿼리 필드 {#query-fields}

리소스에 액세스할 권한이 없으면 쿼리 필드는 `null`를 반환합니다. 응답에는 오류 메시지가 포함되지 않습니다.

이 동작은 의도적입니다. API는 승인되지 않은 리소스와 존재하지 않는 리소스에 대해 동일한 `null` 응답을 반환하므로 클라이언트가 서버에 어떤 리소스가 있는지 열거할 수 없습니다.

예를 들어 있지 않은 역할이나 추가 기능이 필요한 필드를 쿼리하면 `errors` 배열에 항목이 표시되지 않습니다:

```json
{
  "data": {
    "group": {
      "fieldRequiringPermission": null
    }
  }
}
```

Relay 페이지 매김 패턴을 사용하는 [연결 필드](getting_started.md#pagination)의 경우 인가 실패와 빈 결과를 구별할 수 있습니다:

- `"field": null`는 이 리소스에 액세스할 권한이 없음을 의미합니다.
- `"field": { "nodes": [] }`는 권한이 있지만 쿼리와 일치하는 데이터가 없음을 의미합니다.

예상치 못한 `null`를 받으면 다음을 확인하세요:

- 토큰에 필요한 [범위](#token-scopes)가 있습니다.
- 역할이 [GraphQL API 참조](reference/_index.md)에 명시된 최소 액세스 수준을 충족합니다.
- 인스턴스에 필요한 구독 계층, 기능 또는 추가 기능이 활성화되어 있습니다.

#### 변형(Mutation) {#mutations}

인가 실패 시 변형(Mutation)은 오류 메시지를 반환합니다. 오류는 최상위 `errors` 배열에 `null` 데이터 필드와 함께 나타납니다:

```json
{
  "data": {
    "mutationName": null
  },
  "errors": [
    {
      "message": "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["mutationName"]
    }
  ]
}
```

오류 메시지는 리소스 유형에 따라 다를 수 있습니다.

## 객체 식별자 {#object-identifiers}

GitLab GraphQL API는 식별자를 혼합하여 사용합니다.

[글로벌 ID](#global-ids), 전체 경로 및 내부 ID(IID)는 모두 GitLab GraphQL API의 인수로 사용되지만, 종종 스키마의 특정 부분은 이들 모두를 동시에 허용하지 않습니다.

GitLab GraphQL API가 역사적으로 이것에 일치하지 않았지만 일반적으로 다음을 예상할 수 있습니다:

- 객체가 프로젝트, 그룹 또는 네임스페이스인 경우 객체의 전체 경로를 사용합니다.
- 객체에 IID가 있으면 전체 경로와 IID의 조합을 사용합니다.
- 다른 객체의 경우 [글로벌 ID](#global-ids)를 사용합니다.

예를 들어 전체 경로 `"gitlab-org/gitlab"`로 프로젝트를 찾습니다:

```graphql
{
  project(fullPath: "gitlab-org/gitlab") {
    id
    fullPath
  }
}
```

또 다른 예로, 프로젝트의 전체 경로 `"gitlab-org/gitlab"` 및 이슈의 IID `"1"`로 이슈를 잠급니다:

```graphql
mutation {
  issueSetLocked(input: { projectPath: "gitlab-org/gitlab", iid: "1", locked: true }) {
    issue {
      id
      iid
    }
  }
}
```

글로벌 ID로 CI 러너를 찾는 예:

```graphql
{
  runner(id: "gid://gitlab/Ci::Runner/1") {
    id
  }
}
```

역사적으로 GitLab GraphQL API는 전체 경로 및 IID 필드와 인수의 입력이 일치하지 않았지만 일반적으로:

- 전체 경로 필드 및 인수는 GraphQL `ID` 유형입니다.
- IID 필드 및 인수는 GraphQL `String` 유형입니다.

### 글로벌 ID {#global-ids}

GitLab GraphQL API에서 `id`라는 필드 또는 인수는 거의 항상 [글로벌 ID](https://graphql.org/learn/global-object-identification/)이며 데이터베이스 기본 키 ID가 아닙니다. GitLab GraphQL API의 글로벌 ID는 `"gid://gitlab/"`로 시작합니다. 예를 들어, `"gid://gitlab/Issue/123"`입니다.

글로벌 ID는 일부 클라이언트 측 라이브러리에서 캐싱 및 가져오기에 사용되는 규칙입니다.

GitLab 글로벌 ID는 변경될 수 있습니다. 변경되면 이전 글로벌 ID를 인수로 사용하는 것은 더 이상 사용되지 않으며 [사용 중단 및 주요 변경](#breaking-changes) 프로세스에 따라 지원됩니다. 캐시된 글로벌 ID가 GitLab GraphQL 사용 중단 주기 이후에도 유효할 것으로 예상하지 않아야 합니다.

## 사용 가능한 최상위 쿼리 {#available-top-level-queries}

모든 쿼리의 최상위 진입점은 GraphQL 참조의 [`Query` 유형](reference/_index.md#query-type)에 정의되어 있습니다.

### 다중 쿼리 {#multiplex-queries}

GitLab은 쿼리를 단일 요청으로 일괄 처리하는 것을 지원합니다. 자세한 내용은 [다중 쿼리](https://graphql-ruby.org/queries/multiplex.html)를 참조하세요.

## 주요 변경 {#breaking-changes}

GitLab GraphQL API는 [버전이 없으며](https://graphql.org/learn/best-practices/#versioning) API의 변경 사항은 주로 이전 버전과 호환됩니다.

그러나 GitLab은 때때로 GraphQL API를 이전 버전과 호환되지 않는 방식으로 변경합니다. 이러한 변경은 주요 변경으로 간주되며 필드, 인수 또는 스키마의 다른 부분을 제거하거나 이름을 바꾸는 것을 포함할 수 있습니다. 주요 변경을 만들 때 GitLab은 [사용 중단 및 제거 프로세스](#deprecation-and-removal-process)를 따릅니다.

주요 변경이 통합에 영향을 주지 않도록 하려면 다음을 수행해야 합니다:

- [사용 중단 및 제거 프로세스](#deprecation-and-removal-process)에 대해 숙지하세요.
- [향후 주요 변경 스키마에 대해 API 호출 확인](#verify-against-the-future-breaking-change-schema)을 자주 수행하세요.

GitLab Self-Managed의 경우 EE 인스턴스에서 CE로 [되돌리면](../../update/convert_to_ee/revert.md) 주요 변경이 발생합니다.

### 주요 변경 예외 {#breaking-change-exemptions}

[GraphQL API 참조](reference/_index.md)에서 실험으로 표시된 스키마 항목은 사용 중단 프로세스에서 제외됩니다. 이러한 항목은 언제든지 통지 없이 제거하거나 변경할 수 있습니다.

기능 플래그 뒤에 있고 기본적으로 비활성화된 필드는 사용 중단 및 제거 프로세스를 따르지 않습니다. 이러한 필드는 언제든지 통지 없이 제거할 수 있습니다.

> [!warning]
> GitLab은 [사용 중단 및 제거 프로세스](#deprecation-and-removal-process)를 따르려고 모든 시도를 합니다. 사용 중단 프로세스가 상당한 위험을 초래할 경우 GitLab은 중요한 보안 또는 성능 문제를 해결하기 위해 GraphQL API에 즉각적인 주요 변경을 할 수 있습니다.

### 향후 주요 변경 스키마 확인 {#verify-against-the-future-breaking-change-schema}

{{< history >}}

- GitLab 15.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353642).

{{< /history >}}

더 이상 사용되지 않는 모든 항목이 이미 제거된 것처럼 GraphQL API에 대해 호출을 수행할 수 있습니다. 이런 방식으로 항목이 실제로 스키마에서 제거되기 전에 [주요 변경 릴리스](#deprecation-and-removal-process)에 앞서 API 호출을 확인할 수 있습니다.

이러한 호출을 수행하려면 GraphQL API 엔드포인트에 `remove_deprecated=true` 쿼리 매개변수를 추가하세요. 예를 들어 GitLab.com의 GraphQL의 경우 `https://gitlab.com/api/graphql?remove_deprecated=true`.

### 사용 중단 및 제거 프로세스 {#deprecation-and-removal-process}

GitLab GraphQL API에서 제거하도록 표시된 스키마 부분은 먼저 더 이상 사용되지 않지만 최소 6개 릴리스 동안 계속 사용할 수 있습니다. 그런 다음 이후 `XX.0` 주요 릴리스 중에 완전히 제거됩니다.

항목은 다음에서 더 이상 사용되지 않음으로 표시됩니다:

- [스키마](https://spec.graphql.org/October2021/#sec--deprecated).
- [GraphQL API 참조](reference/_index.md).
- 릴리스 게시물에서 연결된 [사용 중단 기능 제거 일정](../../update/deprecations.md).
- GraphQL API의 내부 검사 쿼리.

사용 중단 메시지는 해당하는 경우 더 이상 사용되지 않는 스키마 항목에 대한 대체 기능을 제공합니다.

주요 변경을 경험하지 않으려면 가능한 한 빨리 GraphQL API 호출에서 더 이상 사용되지 않는 스키마를 제거해야 합니다. [더 이상 사용되지 않는 스키마 항목 없이 스키마에 대해 API 호출을 확인](#verify-against-the-future-breaking-change-schema)해야 합니다.

#### 사용 중단 예 {#deprecation-example}

다음 필드는 다양한 부분 릴리스에서 더 이상 사용되지 않지만 모두 GitLab 17.0에서 제거됩니다:

| 다음에서 필드가 더 이상 사용되지 않음 | 이유 |
|:--------------------|:-------|
| 15.7                | GitLab은 전통적으로 주요 릴리스당 12개의 부분 릴리스를 가집니다. 필드를 6개 이상의 릴리스 동안 사용할 수 있도록 보장하려면 17.0 주요 릴리스에서 제거됩니다(16.0이 아님). |
| 16.6                | 17.0에서의 제거는 6개월의 가용성을 허용합니다. |

### 제거된 항목 목록 {#list-of-removed-items}

이전 릴리스에서 [제거된 항목 목록](removed_items.md)을 보세요.

## 제한 {#limits}

다음 제한이 GitLab GraphQL API에 적용됩니다.

| 제한                                                 | 기본값 |
|:------------------------------------------------------|:--------|
| 최대 페이지 크기                                     | 페이지당 100개 레코드(노드). API의 대부분의 연결에 적용됩니다. 특정 연결은 더 높거나 낮은 다양한 최대 페이지 크기 제한을 가질 수 있습니다. |
| [최대 쿼리 복잡도](#maximum-query-complexity) | 인증되지 않은 요청은 200, 인증된 요청은 250입니다. |
| 최대 쿼리 크기                                    | 쿼리 또는 변형당 10,000자. 이 제한에 도달하면 [변수](https://graphql.org/learn/queries/#variables) 및 [조각](https://graphql.org/learn/queries/#fragments)을 사용하여 쿼리 또는 변형 크기를 줄이세요. 마지막 수단으로 공백을 제거하세요. |
| 속도 제한                                           | GitLab.com의 경우 [GitLab.com 특정 속도 제한](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)을 참조하세요. |
| [데이터 제한](#data-limits)                           | 하나 이상의 Blob 경로를 지정하면 Blob 요청은 20 MB로 제한됩니다. |
| 요청 시간 초과                                       | 30초. |

### 최대 쿼리 복잡도 {#maximum-query-complexity}

GitLab GraphQL API는 쿼리의 복잡도를 점수 매깁니다. 일반적으로 더 큰 쿼리는 더 높은 복잡도 점수를 가집니다. 이 제한은 API의 전체 성능에 부정적인 영향을 미칠 수 있는 쿼리를 수행하는 것으로부터 API를 보호하도록 설계되었습니다.

쿼리의 복잡도 점수와 요청의 제한을 [쿼리](getting_started.md#query-complexity)할 수 있습니다.

쿼리가 복잡도 제한을 초과하면 오류 메시지 응답이 반환됩니다.

일반적으로 쿼리의 각 필드는 복잡도 점수에 `1`을 더하지만 특정 필드의 경우 더 높거나 낮을 수 있습니다. 때때로 특정 인수를 추가하면 쿼리의 복잡도가 증가할 수도 있습니다.

### 데이터 제한 {#data-limits}

Blob 요청은 다음으로 제한됩니다:

- 모든 크기의 단일 Blob.
- 총 크기가 20 MB 이하인 여러 Blob.

20 MB보다 큰 Blob은 개별적으로 요청해야 합니다. 이 제한은 Blob 데이터를 포함하는 필드를 요청할 때만 적용됩니다.

데이터 제한 내에서 유지하려면 요청의 경로 수를 제한해야 할 수도 있습니다. `size` 필드에 대한 요청을 수행하되 데이터 필드는 제외하세요:

```gql
{
  project(fullPath: "gitlab-org/gitlab") {
    repository {
      blobs(paths: ["big_file.rb", "small_file.rb", "huge_file.rb", ..., etc.], ref: "master") {
        nodes {
          path
          size
        }
      }
    }
  }
}
```

응답을 사용하여 총 크기를 계산하고 후속 요청이 20 MB 데이터 제한을 초과하지 않는지 확인하세요.

## 스팸으로 감지된 변형(Mutation) 해결 {#resolve-mutations-detected-as-spam}

GraphQL 변형(Mutation)은 스팸으로 감지될 수 있습니다. 변형(Mutation)이 스팸으로 감지되고:

- CAPTCHA 서비스가 구성되지 않으면 [GraphQL 최상위 오류](https://spec.graphql.org/June2018/#sec-Errors)가 발생합니다. 예를 들어:

  ```json
  {
    "errors": [
      {
        "message": "Request denied. Spam detected",
        "locations": [ { "line": 6, "column": 7 } ],
        "path": [ "updateSnippet" ],
        "extensions": {
          "spam": true
        }
      }
    ],
    "data": {
      "updateSnippet": {
        "snippet": null
      }
    }
  }
  ```

- CAPTCHA 서비스가 구성되면 다음과 같은 응답을 받습니다:
  - `needsCaptchaResponse`을(를) `true`로 설정합니다.
  - `spamLogId` 및 `captchaSiteKey` 필드 설정.

  예를 들어:

  ```json
  {
    "errors": [
      {
        "message": "Request denied. Solve CAPTCHA challenge and retry",
        "locations": [ { "line": 6, "column": 7 } ],
        "path": [ "updateSnippet" ],
        "extensions": {
          "needsCaptchaResponse": true,
          "captchaSiteKey": "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI",
          "spamLogId": 67
        }
      }
    ],
    "data": {
      "updateSnippet": {
        "snippet": null,
      }
    }
  }
  ```

- `captchaSiteKey`을 사용하여 적절한 CAPTCHA API를 사용하는 CAPTCHA 응답 값을 얻습니다. [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display)만 지원됩니다.
- `X-GitLab-Captcha-Response` 및 `X-GitLab-Spam-Log-Id` 헤더를 설정하여 요청을 다시 제출하세요.

> [!note]
> GitLab GraphiQL 구현은 헤더 전달을 허용하지 않으므로 요청은 cURL 쿼리여야 합니다. `--data-binary`는 JSON 임베디드 쿼리에서 이스케이프된 큰따옴표를 올바르게 처리하는 데 사용됩니다.

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --request POST \
  --header "Authorization: Bearer $PRIVATE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" \
  --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" \
  --data-binary '{"query": "mutation {createSnippet(input: {title: \"Title\" visibilityLevel: public blobActions: [ { action: create filePath: \"BlobPath\" content: \"BlobContent\" } ] }) { snippet { id title } errors }}"}' "https://gitlab.example.com/api/graphql"
```
