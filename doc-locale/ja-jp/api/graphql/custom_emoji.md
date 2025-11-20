---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQLでカスタム絵文字を使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 13.6で`custom_emoji`という[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911)されました。デフォルトでは無効になっています。
- GitLab 14.0のGitLab.comで有効になりました。
- GitLab 16.7の[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969)で有効になりました。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/)になりました。機能フラグ`custom_emoji`は削除されました。

{{< /history >}}

コメントや説明で[カスタム絵文字](../../user/emoji_reactions.md)を使用するには、GraphQL APIを使用してトップレベルグループに追加します。

## カスタム絵文字を作成する {#create-a-custom-emoji}

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

グループにカスタム絵文字を追加すると、メンバーはコメントで他の絵文字と同じように使用できます。

### 属性 {#attributes}

このクエリは、次の属性を受け入れます:

| 属性    | 型           | 必須               | 説明 |
| :----------- | :------------- | :--------------------- | :---------- |
| `group_path` | 整数または文字列 | はい | トップレベルグループのまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `name`       | 文字列         | はい | カスタム絵文字の名前。 |
| `file`       | 文字列         | はい | カスタム絵文字画像のURL。 |

## GraphiQLを使用する {#use-graphiql}

GraphiQLを使用して、グループの絵文字をクエリできます。

1. GraphiQLを開きます:
   - GitLab.comの場合は、`https://gitlab.com/-/graphql-explorer`を使用します。
   - GitLab Self-Managedの場合は、`https://gitlab.example.com/-/graphql-explorer`を使用します。
1. 次のテキストをコピーして、左側のウィンドウに貼り付けます。このクエリでは、`gitlab-org`はグループパスです。

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

1. **再生**を選択します。

## 関連トピック {#related-topics}

- [GraphQL APIリファレンス](reference/_index.md)
- [フラグメントやインターフェースのようなGraphQL固有のエンティティ](https://graphql.org/learn/)
