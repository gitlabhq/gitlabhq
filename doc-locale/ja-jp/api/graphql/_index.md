---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プログラムによるGitLabの操作
title: GraphQL API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GraphQL](https://graphql.org/)はAPI用のクエリ言語です。GraphQLを使用すると、必要なデータを正確にリクエストできるため、必要なリクエストの数を限定することができます。

GraphQLデータは型別に配置されているため、クライアントは[クライアント側のGraphQLライブラリ](https://graphql.org/community/tools-and-libraries/)を使用してAPIを消費することで、手動の解析を回避することができます。

GraphQL APIは[バージョンなし](https://graphql.org/learn/schema-design/#versioning)です。

## はじめに {#getting-started}

GitLab GraphQL APIを初めて使用する場合は、[GitLab GraphQL APIのスタートガイド](getting_started.md)を参照してください。

利用可能なリソースは、[GraphQL APIリファレンス](reference/_index.md)で確認できます。

GitLab GraphQL APIエンドポイントは`/api/graphql`にあります。

### インタラクティブGraphQLエクスプローラー {#interactive-graphql-explorer}

次のいずれかで、インタラクティブGraphQLエクスプローラーを使用してGraphQL APIを調査できます。

- [GitLab.com](https://gitlab.com/-/graphql-explorer)。
- `https://<your-gitlab-site.com>/-/graphql-explorer`でのGitLab Self-Managed。

詳細については、[GraphiQL](getting_started.md#graphiql)を参照してください。

### GraphQLの例を見る {#view-graphql-examples}

GitLab.comのパブリックプロジェクトからデータをプルするサンプルクエリを使用できます。

- [監査レポートの作成](audit_report.md)
- [イシューボードの特定](sample_issue_boards.md)
- [ユーザーのクエリ](users_example.md)
- [カスタム絵文字の使用](custom_emoji.md)

[スタートガイド](getting_started.md)ページには、GraphQLクエリをカスタマイズするためのさまざまな方法が記載されています。

### 認証 {#authentication}

一部のクエリには認証無しでアクセスできますが、その他のクエリには認証が必要です。ミューテーションには常に認証が必要です。

次のいずれかを使用して認証できます。

- [トークン](#token-authentication)
- [セッションクッキー](#session-cookie-authentication)

認証情報が無効である場合、GitLabはステータスコード`401`とエラーメッセージを返します。

```json
{"errors":[{"message":"Invalid token"}]}
```

#### トークン認証 {#token-authentication}

次のいずれかのトークンを使用して、GraphQL APIで認証します。

- [OAuth 2.0トークン](../oauth2.md)
- [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- [プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)
- [グループアクセストークン](../../user/group/settings/group_access_tokens.md)

[リクエストヘッダー](#header-authentication)で、または[パラメータ](#parameter-authentication)としてトークンを渡すことにより、トークンで認証します。

トークンには正しい[スコープ](#token-scopes)が必要です。

##### ヘッダー認証 {#header-authentication}

`Authorization: Bearer <token>`リクエストヘッダーを使用したトークン認証の例:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer <token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### パラメータ認証 {#parameter-authentication}

`access_token`パラメータでOAuth 2.0トークンを使用する例:

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?access_token=<oauth_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

`private_token`パラメータを使用して、パーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを渡すことができます。

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?private_token=<access_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### トークンスコープ {#token-scopes}

GraphQL APIにアクセスするには、トークンに次のいずれかの正しいスコープが必要です。

| スコープ      | アクセス  |
|------------|---------|
| `read_api` | APIへの読み取りアクセスを許可します。クエリ実行には十分です。 |
| `api`      | APIへの読み取り/書き込みアクセスを許可します。ミューテーションに必要です。 |

#### セッションクッキー認証 {#session-cookie-authentication}

メインのGitLabアプリケーションにサインインすると、`_gitlab_session`セッションクッキーが設定されます。

[インタラクティブGraphQLエクスプローラー](#interactive-graphql-explorer)とGitLab自体のWebフロントエンドは、この認証方法を使用します。

## オブジェクト識別子 {#object-identifiers}

GitLab GraphQL APIは、さまざまな識別子を使用します。

[グローバルID](#global-ids)、フルパス、内部ID（IID）はすべて、GitLab GraphQL APIで引数として使用されますが、多くの場合、スキーマの特定の部分は、これらのすべてを同時に受け入れるわけではありません。

これまで、この点に関してGitLab GraphQL APIは一貫性がありませんでしたが、一般的には次のことが言えます。

- オブジェクトがプロジェクト、グループ、またはネームスペースである場合は、オブジェクトのフルパスを使用します。
- オブジェクトにIIDがある場合は、フルパスとIIDの組み合わせを使用します。
- その他のオブジェクトについては、[グローバルID](#global-ids)を使用します。

たとえば、フルパス`"gitlab-org/gitlab"`でプロジェクトを見つける場合は、次のように使用します。

```graphql
{
  project(fullPath: "gitlab-org/gitlab") {
    id
    fullPath
  }
}
```

別の例として、プロジェクトのフルパス`"gitlab-org/gitlab"`とイシューのIID `"1"`でイシューをロックする場合は、次のように使用します。

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

グローバルIDでCI Runnerを見つける例は次のとおりです。

```graphql
{
  runner(id: "gid://gitlab/Ci::Runner/1") {
    id
  }
}
```

これまで、フルパスフィールドとIIDフィールドおよび引数の型に関して、GitLab GraphQL APIは一貫性がありませんでしたが、一般的には次のことが言えます。

- フルパスフィールドと引数はGraphQL `ID`型です。
- IIDフィールドと引数はGraphQL `String`型です。

### グローバルID {#global-ids}

GitLab GraphQL APIでは、`id`という名前のフィールドまたは引数は、ほぼすべての場合、[グローバルID](https://graphql.org/learn/global-object-identification/)であり、データベースのプライマリキーIDではありません。GitLab GraphQL APIのグローバルIDは、`"gid://gitlab/"`で始まります。例: `"gid://gitlab/Issue/123"`。

グローバルIDは、慣例としてクライアント側の一部のライブラリでキャッシュとフェッチに使用されます。

GitLabのグローバルIDは変更される可能性があります。変更された場合、古いグローバルIDの引数としての使用は非推奨となり、[非推奨と破壊的な変更](#breaking-changes)のプロセスに従ってサポートされます。キャッシュされたグローバルIDがGitLab GraphQLの非推奨サイクル期間を超えて有効になることは想定されていません。

## 利用可能なトップレベルクエリ {#available-top-level-queries}

すべてのクエリのトップレベルのエントリポイントは、GraphQLリファレンスの[`Query`型](reference/_index.md#query-type)で定義されています。

### 多重クエリ {#multiplex-queries}

GitLabは、クエリを1つのリクエストにまとめることをサポートしています。詳細については、[マルチプレックス](https://graphql-ruby.org/queries/multiplex.html)を参照してください。

## 破壊的な変更 {#breaking-changes}

GitLab GraphQL APIは[バージョンなし](https://graphql.org/learn/best-practices/#versioning)であり、APIの変更については、基本的に下位互換性があります。

ただし、GitLabは下位互換性なしでGraphQL APIを変更する場合があります。これらの変更は破壊的な変更と見なされ、フィールド、引数、またはスキーマのその他の部分の削除または名前変更が含まれる場合があります。GitLabは破壊的な変更を作成する場合、[非推奨と削除のプロセス](#deprecation-and-removal-process)に従います。

破壊的な変更がインテグレーションに影響を与えないようにするには、次のようにする必要があります。

- [非推奨と削除のプロセス](#deprecation-and-removal-process)を理解する。
- [将来の破壊的な変更のスキーマに対してAPIコールを頻繁に検証](#verify-against-the-future-breaking-change-schema)する。

GitLab Self-Managedの場合、EEインスタンスからCEインスタンスに[ダウングレード](../../downgrade_ee_to_ce/_index.md)すると、破壊的な変更が発生します。

### 破壊的な変更の適用除外 {#breaking-change-exemptions}

[GraphQL APIリファレンス](reference/_index.md)で実験とラベル付けされたスキーマアイテムは、非推奨プロセスの対象外です。これらのアイテムは、予告なしにいつでも削除または変更される可能性があります。

機能フラグで制御されており、デフォルトで無効になっているフィールドは、非推奨と削除のプロセスに従いません。これらのフィールドは、予告なしにいつでも削除される可能性があります。

{{< alert type="warning" >}}

GitLabは、あらゆる方法で[非推奨と削除のプロセス](#deprecation-and-removal-process)に従うように努めています。非推奨のプロセスが重大なリスクをもたらす場合、GitLabは致命的なセキュリティまたはパフォーマンスの問題を修正するために、GraphQL APIに破壊的な変更を即座に加える可能性があります。

{{< /alert >}}

### 将来の破壊的な変更スキーマを検証する {#verify-against-the-future-breaking-change-schema}

{{< history >}}

- GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/353642)されました。

{{< /history >}}

すべての非推奨アイテムがすでに削除されているかのように、GraphQL APIを呼び出すことができます。このようにすると、アイテムが実際にスキーマから削除される前に、[破壊的な変更のリリース](#deprecation-and-removal-process)に先立ってAPIコールを検証できます。

これらの呼び出しを行うには、`remove_deprecated=true`クエリパラメータをGraphQL APIエンドポイントに追加します。たとえば、GitLab.comのGraphQLの場合は、`https://gitlab.com/api/graphql?remove_deprecated=true`になります。

### 非推奨と削除のプロセス {#deprecation-and-removal-process}

GitLab GraphQL APIからの削除対象としてマークされたスキーマの一部は、最初に非推奨になりますが、少なくとも6つのリリースでは引き続き利用できます。その後、次の`XX.0`メジャーリリース中に完全に削除されます。

アイテムは以下で非推奨とマークされます。

- [スキーマ](https://spec.graphql.org/October2021/#sec--deprecated)。
- [GraphQL APIリファレンス](reference/_index.md)。
- [非推奨機能の削除スケジュール](../../update/deprecations.md)。このスケジュールはリリース投稿からリンクされています。
- GraphQL APIのイントロスペクションクエリ。

非推奨メッセージは、該当する場合、非推奨スキーマアイテムの代替案を提供します。

破壊的な変更が発生しないようにするには、GraphQL APIコールから非推奨スキーマをできるだけ早く削除する必要があります。[非推奨スキーマアイテムなしでスキーマに対するAPIコールを検証](#verify-against-the-future-breaking-change-schema)する必要があります。

#### 非推奨の例 {#deprecation-example}

次のフィールドは、さまざまなマイナーリリースで非推奨になっていますが、GitLab 17.0で両方とも削除されます。

| フィールドが非推奨になるバージョン | 理由 |
|:--------------------|:-------|
| 15.7                | GitLabには通常、メジャーリリースあたり12のマイナーリリースがあります。このフィールドは、さらに6つのリリースで利用できるようにするために、17.0メジャーリリース（16.0ではなく）で削除されます。 |
| 16.6                | 17.0で削除されるため、6か月間利用できます。 |

### 削除されたアイテムのリスト {#list-of-removed-items}

以前のリリースで[削除されたアイテムのリスト](removed_items.md)を表示します。

## 制限 {#limits}

次の制限がGitLab GraphQL APIに適用されます。

| 制限                                                 | デフォルト |
|:------------------------------------------------------|:--------|
| 最大ページサイズ                                     | 1ページあたり100レコード（ノード）。APIのほとんどの接続に適用されます。特定の接続では、最大ページサイズの制限が異なる場合があり、制限が高くなっているか、低くなっています。 |
| [最大クエリ複雑度](#maximum-query-complexity) | 認証されていないリクエストの場合は200、認証されているリクエストの場合は250です。 |
| 最大クエリサイズ                                    | クエリまたはミューテーションあたり10,000文字。この制限に達した場合は、[変数](https://graphql.org/learn/queries/#variables)と[フラグメント](https://graphql.org/learn/queries/#fragments)を使用して、クエリまたはミューテーションのサイズを削減してください。最後の手段として空白を削除します。 |
| レート制限 | GitLab.comの場合、[GitLab.com固有のレート制限](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。 |
| リクエストタイムアウト                                       | 30秒。 |

### 最大クエリ複雑度 {#maximum-query-complexity}

GitLab GraphQL APIは、クエリの複雑度にスコアを付けます。一般的に、クエリが大きいほど、複雑度のスコアが高くなります。この制限は、API全体のパフォーマンスに悪影響を与える可能性のあるクエリの実行からAPIを保護するように設計されています。

クエリの複雑度スコアとリクエストの制限を[クエリ](getting_started.md#query-complexity)できます。

クエリが複雑度の制限を超えると、エラーメッセージ応答が返されます。

一般的に、クエリ内の各フィールドは複雑度スコアに`1`を追加しますが、特定のフィールドの場合は、値がこれより高くなるか、低くなる可能性があります。また、特定の引数を追加すると、クエリの複雑度が増大する場合があります。

## スパムとして検出されたミューテーションを解決する {#resolve-mutations-detected-as-spam}

GraphQLミューテーションはスパムとして検出される可能性があります。ミューテーションがスパムとして検出されたときは、次のようになります。

- CAPTCHAサービスが設定されていない場合、[GraphQLトップレベルエラー](https://spec.graphql.org/June2018/#sec-Errors)が発生します。例は次のとおりです。

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

- CAPTCHAサービスが設定されている場合、次の内容の応答が返されます。
  - `needsCaptchaResponse`が`true`に設定されます。
  - `spamLogId`フィールドと`captchaSiteKey`フィールドが設定されます。

  例は次のとおりです。

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

- 適切なCAPTCHA APIを使用して、`captchaSiteKey`でCAPTCHAの応答値を取得します。[Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display)のみがサポートされています。
- `X-GitLab-Captcha-Response`ヘッダーと`X-GitLab-Spam-Log-Id`ヘッダーを設定して、リクエストを再送信します。

{{< alert type="note" >}}

GitLab GraphiQLの実装では、ヘッダーを渡すことが許可されていないため、これをcURLクエリとして記述する必要があります。`--data-binary`は、エスケープされた二重引用符をJSON埋め込みクエリで適切に処理するために使用されます。

{{< /alert >}}

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
