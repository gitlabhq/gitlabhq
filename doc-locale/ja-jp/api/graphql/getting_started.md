---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQL APIクエリとミューテーションの実行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このガイドでは、GitLab GraphQL APIの基本的な使用方法を説明します。

API自体の開発に携わりたいデベロッパー向けの実装の詳細については、[GraphQL APIスタイルガイド](../../development/api_graphql_styleguide.md)をお読みください。

## 実行の例

ここで説明する例は、以下を使用して実行できます。

- [GraphiQL](#graphiql)。
- [コマンドライン](#command-line)。
- [Railsコンソール](#rails-console)。

### GraphiQL

GraphiQL（「グラフィカル」と発音）を使用すると、実際のGraphQLクエリをAPIに対してインタラクティブに実行できます。GraphiQLは、ハイライトした構文とオートコンプリートを備えたUIを提供することで、スキーマを簡単に調べられるようにします。

ほとんどの人にとって、GraphiQLの使用は、GitLab GraphQL APIを調べる最も簡単な方法です。

GraphiQLは以下でも使用できます。

- [GitLab.com](https://gitlab.com/-/graphql-explorer)。
- `https://<your-gitlab-site.com>/-/graphql-explorer`でのGitLab Self-Managed。

最初にGitLabにサインインして、GitLabアカウントでリクエストを認証します。

使用を開始するには、[クエリとミューテーションの例](#queries-and-mutations)を参照してください。

### コマンドライン

ローカルコンピューターでコマンドラインを使用して、`curl`リクエストでGraphQLクエリを実行できます。リクエストは、クエリをペイロードとして`/api/graphql`に`POST`します。ベアラートークンとして使用する[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を生成して、リクエストを承認できます。詳細については、[GraphQL認証](_index.md#authentication)を参照してください。

例:

```shell
GRAPHQL_TOKEN=<your-token>
curl "https://gitlab.com/api/graphql" --header "Authorization: Bearer $GRAPHQL_TOKEN" \
     --header "Content-Type: application/json" --request POST \
     --data "{\"query\": \"query {currentUser {name}}\"}"
```

クエリ文字列に文字列をネストするには、データを一重引用符で囲むか、<code>\\\\</code>で文字列をエスケープします。

```shell
curl "https://gitlab.com/api/graphql" --header "Authorization: Bearer $GRAPHQL_TOKEN" \
    --header "Content-Type: application/json" --request POST \
    --data '{"query": "query {project(fullPath: \"<group>/<subgroup>/<project>\") {jobs {nodes {id duration}}}}"}'
      # or "{\"query\": \"query {project(fullPath: \\\"<group>/<subgroup>/<project>\\\") {jobs {nodes {id duration}}}}\"}"
```

### Railsコンソール

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GraphQLクエリは、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で実行できます。たとえば、プロジェクトを検索するには、次のようにクエリを実行します。

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

## クエリとミューテーション

GitLab GraphQL APIを使用すると、以下を実行できます。

- データ取得のためのクエリ。
- データの作成、更新、削除のための[ミューテーション](#mutations)。

{{< alert type="note" >}}

GitLab GraphQL APIでは、`id`は[グローバルID](https://graphql.org/learn/global-object-identification/)を指します。これは、`"gid://gitlab/Issue/123"`の形式のオブジェクト識別子です。詳細については、[グローバルID](_index.md#global-ids)を参照してください。

{{< /alert >}}

[GitLab GraphQLスキーマ](reference/_index.md)は、クライアントがクエリできるオブジェクトやフィールド、対応するデータ型を示しています。

例: `gitlab-org`グループ内で現在認証されているユーザーがアクセスできる（制限まで）すべてのプロジェクトの名前のみを取得します。

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

例: 特定のプロジェクトとイシュー#2のタイトルを取得します。

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

### グラフ走査

子ノードを取得する場合は、次の構文を使用します。

- `edges { node { } }`構文。
- 短い形式の`nodes { }`構文。

その下では、グラフを走査しています。これがGraphQLという名前の由来です。

例: プロジェクトの名前と、そのすべてのイシューのタイトルを取得します。

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

クエリの詳細: [GraphQLドキュメント](https://graphql.org/learn/queries/)

### 認証

GitLabにサインインして[GraphiQL](#graphiql)を使用すると、すべてのクエリが認証済みユーザーとして実行されます。詳細については、[GraphQL認証](_index.md#authentication)を参照してください。

### ミューテーション

ミューテーションは、データに変更を加えます。新しいレコードを更新、削除、または作成できます。通常、ミューテーションはInputTypeと変数を使用しますが、ここにはどちらも表示されません。

ミューテーションには以下があります。

- インプット。たとえば、どの絵文字リアクションを追加するか、どのオブジェクトに絵文字リアクションを追加するかなどの引数です。
- returnストートメント。つまり、成功した場合に何を取得したいか。
- エラー。念のため、何がうまくいかなかったのかを常に尋ねてください。

#### 作成ミューテーション

例: お茶を飲みましょう - イシューに`:tea:`リアクション絵文字を追加します。

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

例: イシューにコメントを追加します。この例では、`GitLab.com`イシューのIDを使用します。ローカルインスタンスを使用している場合は、書き込み可能なイシューのIDを取得する必要があります。

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

#### 更新ミューテーション

作成したノートの結果`id`が表示されたら、それをメモしてください。編集して、より早く飲めるようにしましょう。

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

#### 削除ミューテーション

お茶がなくなってしまったので、コメントを削除しましょう。

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

次のような出力が得られるはずです。

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

ノートの詳細を要求しましたが、もう存在しないため、`null`が取得されます。

ミューテーションの詳細: [GraphQLドキュメント](https://graphql.org/learn/queries/#mutations)。

### プロジェクト設定を更新する

単一のGraphQLミューテーションで複数のプロジェクト設定を更新できます。この例は、`CI_JOB_TOKEN`スコープの動作における[大きな変更](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)の回避策です。

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

### イントロスペクションクエリ

クライアントは、[イントロスペクションクエリ](https://graphql.org/learn/introspection/)を行うことにより、スキーマに関する情報についてGraphQLエンドポイントにクエリできます。

[GraphiQL Query Explorer](#graphiql)は、イントロスペクションクエリを使用して以下を行います。

- GitLab GraphQLスキーマに関する知識を取得します。
- オートコンプリートを行います。
- インタラクティブな`Docs`タブを提供します。

例: スキーマ内のすべての型名を取得します。

```graphql
{
  __schema {
    types {
      name
    }
  }
}
```

例: イシューに関連付けられたすべてのフィールドを取得します。`kind`は、`OBJECT`、`SCALAR`、`INTERFACE`のような型のenum値を示します。

```graphql
query IssueTypes {
  __type(name: "Issue") {
    kind
    name
    fields {
      name
      description
      type {
        name
      }
    }
  }
}
```

イントロスペクションの詳細: [GraphQLドキュメント](https://graphql.org/learn/introspection/)

### クエリの複雑さ

クエリの計算された[複雑さのスコアと制限](_index.md#maximum-query-complexity)は、`queryComplexity`をクエリすることでクライアントに公開できます。

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

## ソート

GitLab GraphQLエンドポイントの一部では、オブジェクトのコレクションをソートする方法を指定できます。スキーマで許可されているものだけでソートできます。

例: イシューは作成日でソートできます。

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

## ページネーション

ページネーションは、最初の10件など、レコードのサブセットのみを要求する方法です。さらに必要な場合は、`please give me the next ten records`のような形式で、サーバーから次の10件を再度リクエストできます。

デフォルトでは、GitLab GraphQL APIはページごとに100件のレコードを返します。この動作を変更するには、`first`引数または`last`引数を使用します。どちらの引数も値を受け取ります。`first: 10`は最初の10件のレコードを返し、`last: 10`は最後の10件のレコードを返します。ページごとに返されるレコード数には制限があり、通常は`100`です。

例: 最初の2つのイシューのみを取得します（スライス）。`cursor`フィールドは位置を示し、その取得を基準にしてさらにレコードを取得できます。

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

例: 次の3つを取得します。（カーソル値`eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0`は異なる場合がありますが、上記の2番目のイシューに対して返される`cursor`値です。）

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

ページネーションとカーソルの詳細: [GraphQLドキュメント](https://graphql.org/learn/pagination/)

## クエリURLを変更する

GraphQLリクエストを別のURLに送信する必要がある場合があります。たとえば、`GeoNode`クエリは、セカンダリジオサイトのURLに対してのみ機能します。

GraphiQL EplorerでGraphQLリクエストのURLを変更するには、GraphiQLのヘッダー領域（左下の領域、変数があるところ）にカスタムヘッダーを設定します。

```JSON
{
  "REQUEST_PATH": "<the URL to make the graphQL request against>"
}
```
