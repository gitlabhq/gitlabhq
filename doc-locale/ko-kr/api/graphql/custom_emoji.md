---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL과 함께 사용자 지정 이모지 사용
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 13.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911) 되었으며 [플래그](../../administration/feature_flags/_index.md) 이름은 `custom_emoji`입니다. 기본적으로 비활성화됨.
- GitLab 14.0에서 GitLab.com에 활성화되었습니다.
- [GitLab Self-Managed에 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969)되었으며 GitLab 16.7입니다.
- [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/)는 GitLab 16.9입니다. 기능 플래그 `custom_emoji` 제거됨.

{{< /history >}}

[사용자 지정 이모지](../../user/emoji_reactions.md)를 주석 및 설명에 사용하려면 GraphQL API를 사용하여 최상위 그룹에 추가할 수 있습니다.

## 사용자 지정 이모지 생성 {#create-a-custom-emoji}

```graphql
mutation CreateCustomEmoji($groupPath: ID!) {
  createCustomEmoji(input: {groupPath: $groupPath, name: "party-parrot", url: "https://cultofthepartyparrot.com/parrots/hd/parrot.gif"}) {
    clientMutationId
    customEmoji {
      name
    }
    errors
  }
}
```

그룹에 사용자 지정 이모지를 추가한 후 멤버는 주석에서 다른 이모지와 동일한 방식으로 사용할 수 있습니다.

### 속성 {#attributes}

쿼리는 이러한 속성을 허용합니다:

| 속성    | 유형           | 필수               | 설명 |
| :----------- | :------------- | :--------------------- | :---------- |
| `group_path` | 정수 또는 문자열 | 예 | ID 또는 [최상위 그룹의 URL 인코딩 경로](../rest/_index.md#namespaced-paths)입니다. |
| `name`       | 문자열         | 예 | 사용자 지정 이모지의 이름입니다. |
| `file`       | 문자열         | 예 | 사용자 지정 이모지 이미지의 URL입니다. |

## GraphiQL 사용 {#use-graphiql}

GraphiQL을 사용하여 그룹의 이모지를 쿼리할 수 있습니다.

1. GraphiQL 열기:
   - GitLab.com의 경우 다음을 사용합니다: `https://gitlab.com/-/graphql-explorer`
   - GitLab Self-Managed의 경우 다음을 사용합니다: `https://gitlab.example.com/-/graphql-explorer`
1. 다음 텍스트를 복사하여 왼쪽 창에 붙여넣습니다. 이 쿼리에서 `gitlab-org`는 그룹 경로입니다.

   ```graphql
       query GetCustomEmoji {
         group(fullPath: "gitlab-org") {
           id
           customEmoji {
             nodes {
               name,
               url
             }
           }
         }
       }
   ```

1. **Play**을 선택합니다.

## 관련 항목 {#related-topics}

- [GraphQL API 참조](reference/_index.md)
- [조각 및 인터페이스와 같은 GraphQL 고유 엔티티](https://graphql.org/learn/)
