---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL을 사용하여 이슈 보드 식별
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다음 방법을 사용하여 프로젝트의 [이슈 보드](../../user/project/issue_board.md)를 식별할 수 있습니다:

- GraphiQL
- [`cURL`](getting_started.md#command-line)

## GraphiQL 사용 {#use-graphiql}

GraphiQL을 사용하여 프로젝트의 이슈 보드를 나열할 수 있습니다.

1. GraphiQL을 열어봅시다:
   - GitLab.com의 경우: `https://gitlab.com/-/graphql-explorer`
   - GitLab Self-Managed의 경우: `https://gitlab.example.com/-/graphql-explorer`
1. 다음 텍스트를 복사하여 왼쪽 창에 붙여넣습니다. 이 쿼리는 `docs-gitlab-com` 리포지토리의 이슈 보드를 가져옵니다.

   ```graphql
   query {
     project(fullPath: "gitlab-org/technical-writing/docs-gitlab-com") {
       name
       forksCount
       statistics {
         wikiSize
       }
       issuesEnabled
       boards {
         nodes {
           id
           name
         }
       }
     }
   }
   ```

1. **Play**를 선택합니다.

이러한 이슈 보드 중 하나를 보려면 출력에서 숫자 식별자를 복사합니다. 예를 들어, 식별자가 `7174622`인 경우 이 URL을 사용하여 이슈 보드로 이동합니다:

```http
https:/gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/boards/7174622
```

## 관련 항목 {#related-topics}

- [GraphQL API 참조](reference/_index.md)
