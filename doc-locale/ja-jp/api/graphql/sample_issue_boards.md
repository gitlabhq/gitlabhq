---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: イシューボードをGraphQLを使って特定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトの[イシューボード](../../user/project/issue_board.md)を特定するには、以下を使用します:

- GraphiQL。
- [`cURL`](getting_started.md#command-line)。

## GraphiQLを使用する {#use-graphiql}

プロジェクトのイシューボードを一覧表示するには、GraphiQLを使用できます。

1. GraphiQLを開きます:
   - GitLab.comの場合は、`https://gitlab.com/-/graphql-explorer`を使用します。
   - GitLab Self-Managedの場合は、`https://gitlab.example.com/-/graphql-explorer`を使用します。
1. 次のテキストをコピーして左側のウィンドウに貼り付けます。このクエリは、`docs-gitlab-com`リポジトリのイシューボードを取得します。

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

1. **Play**を選択します。

これらのイシューボードのいずれかを表示するには、出力から数値の識別子をコピーします。たとえば、識別子が`7174622`の場合、このURLを使用してイシューボードに移動します:

```http
https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/boards/7174622
```

## 関連トピック {#related-topics}

- [GraphQL API参照](reference/_index.md)
