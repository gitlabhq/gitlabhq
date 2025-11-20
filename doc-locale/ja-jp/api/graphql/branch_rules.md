---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQLを使用して、プロジェクトのブランチルールをリスト表示する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GraphQLを使用して、特定のプロジェクトのブランチルールをクエリできます:

- GraphiQL。
- [`cURL`](getting_started.md#command-line)。
- [GitLab Development Kit（GDK）](#use-the-gdk)。

## GraphiQLを使用する {#use-graphiql}

GraphiQLを使用して、プロジェクトのブランチルールをリスト表示できます。

1. GraphiQLを開きます:
   - GitLab.comの場合は、`https://gitlab.com/-/graphql-explorer`を使用します。
   - GitLab Self-Managedの場合は、`https://gitlab.example.com/-/graphql-explorer`を使用します。
1. 次のテキストをコピーして、左側のウィンドウに貼り付けます。このクエリは、`gitlab-org/gitlab-docs`などのフルパスでプロジェクトを検索します。プロジェクト用に設定されたすべてのブランチルールをリクエストします。

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

1. **再生**を選択します。

ブランチルールが表示されない場合、次の理由が考えられます:

- ブランチルールが設定されていません。
- あなたのロールには、ブランチルールを表示する権限がありません。管理者は、すべてのリソースにアクセスできます。

## GDKを使用する {#use-the-gdk}

アクセスをリクエストする代わりに、[GitLab Development Kit（GDK）](https://gitlab.com/gitlab-org/gitlab-development-kit)でクエリを実行する方が簡単な場合があります。

1. [GDKドキュメント](https://gitlab-org.gitlab.io/gitlab-development-kit/gdk_commands/#get-the-login-credentials)の認証情報を使用して、`root`としてサインインします。
1. `flightjs/Flight`プロジェクト用に設定されたブランチルールがあることを確認します。
1. GDKインスタンスで、GraphiQLを`http://gdk.test:3000/-/graphql-explorer`で開きます。
1. クエリをコピーして、左側のウィンドウに貼り付けます。
1. フルパスを次のパスに置き換えます:

   ```graphql
   query {
     project(fullPath: "flightjs/Flight") {
   ```

1. **再生**を選択します。

## 関連トピック {#related-topics}

- [GraphQL APIリファレンス](reference/_index.md)
