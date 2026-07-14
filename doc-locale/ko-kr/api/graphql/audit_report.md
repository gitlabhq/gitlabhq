---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL을 사용하여 감사 보고서 생성
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다음을 사용하여 특정 사용자 부분 집합의 감사 보고서를 생성할 수 있습니다:

- GraphiQL
- [`cURL`](getting_started.md#command-line)

## GraphiQL 사용 {#use-graphiql}

GraphiQL을 사용하여 사용자 부분 집합에 대한 정보를 조회할 수 있습니다.

1. GraphiQL을 열어봅시다:
   - GitLab.com의 경우: `https://gitlab.com/-/graphql-explorer`
   - GitLab Self-Managed의 경우: `https://gitlab.example.com/-/graphql-explorer`
1. 다음 텍스트를 복사하여 왼쪽 창에 붙여넣습니다. 이 쿼리는 사용자 이름으로 사용자 부분 집합을 검색합니다. 또는 해당 [Global ID](_index.md#global-ids)를 사용할 수 있습니다.

   ```graphql
   {
     users(usernames: ["user1", "user2", "user3"]) {
       pageInfo {
         endCursor
         startCursor
         hasNextPage
       }
       nodes {
         id
         ...memberships
       }
     }
   }

   fragment membership on MemberInterface {
     createdAt
     updatedAt
     accessLevel {
       integerValue
       stringValue
     }
     createdBy {
       id
     }
   }

   fragment memberships on User {
     groupMemberships {
       nodes {
         ...membership
         group {
           id
           name
         }
       }
     }

     projectMemberships {
       nodes {
         ...membership
         project {
           id
           name
         }
       }
     }
   }
   ```

1. **Play**를 선택합니다.

> [!note]
> [GraphQL API는 표준 ID가 아닌 GlobalID를 반환합니다](getting_started.md#queries-and-mutations). 또한 단일 정수가 아닌 입력값으로 GlobalID를 예상합니다.

이 쿼리는 사용자가 명시적으로 구성원이 된 그룹 및 프로젝트를 반환합니다.

- GraphiQL은 세션 토큰을 사용하여 리소스에 대한 액세스 권한을 부여하기 때문에 출력이 현재 인증된 사용자가 액세스할 수 있는 프로젝트 및 그룹으로 제한됩니다.
- 인스턴스 관리자로 로그인한 경우 모든 리소스에 액세스할 수 있습니다.

## 페이지 매김 및 그래프 노드 {#pagination-and-graph-nodes}

쿼리에는 다음이 포함됩니다:

- [`pageInfo`](#pageinfo)
- [`nodes`](#nodes)

### `pageInfo` {#pageinfo}

여기에는 페이지 매김을 구현하는 데 필요한 데이터가 포함되어 있습니다. GitLab은 커서 기반 [페이지 매김](getting_started.md#pagination)을 사용합니다. 자세한 내용은 GraphQL 설명서에서 [페이지 매김](https://graphql.org/learn/pagination/)을 참조하세요.

### `nodes` {#nodes}

GraphQL 쿼리에서 `nodes`는 [`nodes` on a graph](https://en.wikipedia.org/wiki/Vertex_(graph_theory))의 컬렉션을 나타냅니다. 이 경우 노드 컬렉션은 `User` 객체의 컬렉션입니다. 각 항목에 대해 출력에는 다음이 포함됩니다:

- 사용자의 `id`
- 해당 사용자에게 속하는 프로젝트 또는 그룹 멤버십을 나타내는 `membership` 프래그먼트입니다. 프래그먼트는 `...memberships` 표기법으로 표시됩니다.

## 관련 항목 {#related-topics}

- [GraphQL API 참조](reference/_index.md)
- [프래그먼트 및 인터페이스와 같은 GraphQL별 엔티티](https://graphql.org/learn/)
