---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL을 사용하여 프로젝트의 브랜치 규칙 나열
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다음을 사용하여 주어진 프로젝트의 브랜치 규칙을 쿼리할 수 있습니다:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).
- [GitLab Development Kit (GDK)](#use-the-gdk).

## GraphiQL 사용 {#use-graphiql}

GraphiQL을 사용하여 프로젝트의 브랜치 규칙을 나열할 수 있습니다.

1. GraphiQL 열기:
   - GitLab.com의 경우 다음을 사용합니다: `https://gitlab.com/-/graphql-explorer`
   - GitLab Self-Managed의 경우 다음을 사용합니다: `https://gitlab.example.com/-/graphql-explorer`
1. 다음 텍스트를 복사하여 왼쪽 창에 붙여넣습니다. 이 쿼리는 전체 경로(예: `gitlab-org/gitlab-docs`)로 프로젝트를 검색합니다. 프로젝트에 대해 구성된 모든 브랜치 규칙을 요청합니다.

   ```graphql
   query {
     project(fullPath: "gitlab-org/gitlab-docs") {
       branchRules {
         nodes {
           name
           isDefault
           isProtected
           matchingBranchesCount
           createdAt
           updatedAt
           branchProtection {
             allowForcePush
             codeOwnerApprovalRequired
             mergeAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             pushAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             unprotectAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
           }
           externalStatusChecks {
             nodes {
               id
               name
               externalUrl
             }
           }
           approvalRules {
             nodes {
               id
               name
               type
               approvalsRequired
               eligibleApprovers {
                 nodes {
                   name
                 }
               }
             }
           }
         }
       }
     }
   }
   ```

1. **Play**를 선택합니다.

브랜치 규칙이 표시되지 않으면 다음과 같은 이유일 수 있습니다:

- 구성된 브랜치 규칙이 없습니다.
- 역할에 브랜치 규칙을 볼 수 있는 권한이 없습니다. 관리자는 모든 리소스에 액세스할 수 있습니다.

## GDK 사용 {#use-the-gdk}

액세스를 요청하는 대신 [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit)에서 쿼리를 실행하는 것이 더 쉬울 수 있습니다.

1. 기본 관리자 `root`로 로그인하고 [GDK 문서](https://gitlab-org.gitlab.io/gitlab-development-kit/gdk_commands/#get-the-login-credentials)의 자격 증명을 사용합니다.
1. `flightjs/Flight` 프로젝트에 대해 구성된 일부 브랜치 규칙이 있는지 확인합니다.
1. GDK 인스턴스에서 GraphiQL을 엽니다: `http://gdk.test:3000/-/graphql-explorer`.
1. 쿼리를 복사하여 왼쪽 창에 붙여넣습니다.
1. 전체 경로를 다음 경로로 바꿉니다:

   ```graphql
   query {
     project(fullPath: "flightjs/Flight") {
   ```

1. **Play**를 선택합니다.

## 관련 항목 {#related-topics}

- [GraphQL API 참조](reference/_index.md)
