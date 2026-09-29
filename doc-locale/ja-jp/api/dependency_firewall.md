---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトの依存関係ファイアウォールを確認および評価するためのREST API。
title: 依存関係ファイアウォールAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.4で`dependency_firewall_phase1`[機能フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/23242)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

このAPIを使用して、プロジェクトの依存関係ファイアウォールと対話します。依存関係ファイアウォールは、プロジェクトのセキュリティポリシーを満たさないパッケージがフェッチされる前にブロックします。

## プロジェクトの依存関係ファイアウォールのステータスを取得する {#retrieve-status-of-dependency-firewall-for-a-project}

指定されたプロジェクトの依存関係ファイアウォールのステータスを取得します。このエンドポイントを使用して、実行全体でファイアウォールをスキップするかどうかを決定します。ファイアウォールがオフになっているプロジェクトは、`404 Not Found`ではなく成功応答を返すため、アクセスできないプロジェクトと区別できます。

このエンドポイントは、パーソナルアクセストークン、プロジェクトアクセストークン、グループアクセストークン、OAuthトークン、または[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を受け入れます。デプロイトークンはサポートされていません。認証されていないリクエストは、公開プロジェクトを含め、拒否されます。

CI/CDジョブトークンには、特定のきめ細かい権限は必要ありません。それを制約するのは、ジョブが実行されるプロジェクトです。ジョブトークンはそのプロジェクトのみを確認できます。他のプロジェクトへのリクエストは`403 Forbidden`で拒否されます。これは、ターゲットプロジェクトがジョブのプロジェクトを[受信ジョブトークン許可リスト](../ci/jobs/ci_job_token.md)に許可している場合でも、その許可リストエントリがどのようなきめ細かい権限を付与しているかに関わらず拒否されます。あるプロジェクトのファイアウォールステータスは、別のプロジェクトのパイプラインが必要とする情報ではありません。

前提条件: 

- プロジェクトを読み取る権限が必要です。

```plaintext
GET /projects/:id/dependency_firewall/enablement
```

サポートされている属性は以下のとおりです: 

| 属性 | タイプ              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性  | タイプ    | 説明 |
| ---------- | ------- | ----------- |
| `enabled`  | ブール値 | プロジェクトに対して依存関係ファイアウォールが有効になっているかどうか。単一の結合された回答: 応答は、ライセンスまたはネームスペースの設定によって生成されたかどうかを示しません。 |

可能な応答コード:

| ステータスコード | 説明 |
| ----------- | ----------- |
| `401`       | 認証されていません。リクエストに有効な認証が含まれていませんでした。 |
| `403`       | 禁止されています。この資格情報はこのエンドポイントを使用することを許可されていません: ジョブが実行されているプロジェクト以外のプロジェクトのCI/CDジョブトークン、またはプロジェクトを読み取る権限のないきめ細かいトークン。プロジェクトを読み取ることができないユーザーは、代わりに`404`を受け取ります。 |
| `404`       | 見つかりません。意味は、応答ボディが使用するキーによって異なります: `enabled`、`message`、または`error`。この表の後のガイダンスを参照してください。 |
| `429`       | リクエストが多すぎます。このエンドポイントのレート制限を超過しました。これは呼び出し元ユーザーにスコープされています。この制限は、他のプロジェクトエンドポイントの制限とは別です。 |

機能フラグがオフの間は、エンドポイントはまだ一般公開されていないため、`200`ではなく`404`を返します。したがって、`404`応答は3つのことのいずれかを意味し、クライアントはテキストの表現ではなく、応答ボディが使用するキーによってそれらを区別します:

- `{"enabled": false}`のような`enabled`キーを持つボディは、このプロジェクトで機能フラグがオフであることを意味します。ファイアウォールはアクティブではないため、クライアントは実行時にそれをスキップできます。
- `{"error":"404 Not Found"}`のような`error`キーを持つボディは、このエンドポイントがインスタンスに存在しないことを意味します。例えば、インスタンスがGitLab Community Editionを実行しているか、このエンドポイントが追加される前のバージョンである可能性があります。クライアントは設定の問題を報告する代わりに、以前の動作にフォールバックする必要があります。
- `message`キーを持つボディは、エンドポイントが存在し、リクエストを拒否したことを意味します。プロジェクトが存在しないか、読み取ることができません。クライアントは設定の問題を報告し、プロジェクトを保護されていないものとして扱ってはなりません。

この決定をメッセージテキストに依存させないでください。プロジェクトを読み取れない呼び出し元は`{"message":"404 Project Not Found"}`を取得しますが、プロジェクトへのアクセス権がないきめ細かいトークンは`{"message":"404 Not Found"}`を取得します。これは、表現だけを比較するとエンドポイントが見つからないケースと同じように読み取れます。

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/enablement"
```

レスポンス例: 

```json
{
  "enabled": true
}
```

パイプラインジョブから認証するには、`JOB-TOKEN`ヘッダーを使用して[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用します:

```shell
curl --request GET \
  --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/enablement"
```

## プロジェクトの依存関係ファイアウォールポリシーに対してパッケージを評価する {#evaluate-a-package-against-dependency-firewall-policies-for-a-project}

指定されたプロジェクトの依存関係ファイアウォールポリシーに対して単一のパッケージを評価します。

このエンドポイントは、パーソナルアクセストークン、プロジェクトアクセストークン、グループアクセストークン、OAuthトークン、または[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を受け入れます。ジョブトークンは、そのジョブが実行されるプロジェクトのパッケージのみを評価できます。ターゲットプロジェクトがその[受信ジョブトークン許可リスト](../ci/jobs/ci_job_token.md)にジョブのプロジェクトを許可している場合でも、他のプロジェクトのジョブトークンは`403 Forbidden`ステータスコードで拒否されます。デプロイトークンはサポートされていません。

前提条件: 

- プロジェクトのレポーターロール以上が必要です。パッケージレジストリをオンにする必要はありません。依存関係ファイアウォールはアップストリームレジストリからフェッチされた依存関係を評価するため、評価権限はプロジェクトのパッケージレジストリ設定とは独立しています。

```plaintext
POST /projects/:id/dependency_firewall/evaluate
```

サポートされている属性は以下のとおりです: 

| 属性   | タイプ              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `ecosystem` | 文字列            | はい      | パッケージエコシステム。`cargo`、`composer`、`conan`、`gem`、`golang`、`maven`、`npm`、`nuget`、`pub`、`pypi`、または`swift`のいずれか。 |
| `name`      | 文字列            | はい      | パッケージ名、最大255文字。`maven`の場合は、`groupId:artifactId`の形式を使用します。例: `com.example:trivial-lib`。`pypi`の場合、名前は評価前にPEP 503に従って正規化されるため、`Flask_Login`と`flask-login`は同等です。 |
| `version`   | 文字列            | はい      | パッケージバージョン、最大255文字。 |
| `operation` | 文字列            | いいえ       | 評価されているパッケージ操作。`download`または`upload`のいずれか。`download`がデフォルトです。 |

リクエストヘッダー:

- `X-Gitlab-Dependency-Firewall-Session-Id`: オプション。単一のパッケージマネージャー呼び出しからのすべての評価をグループ化するため、パッケージごとに1つの評価をトリガーする単一のインストールコマンドをこの値で関連付けることができます。GitLabは評価の監査イベントと分析イベントに値を記録し、検証せずに不透明な値として扱います。

値は1から255文字で、文字、数字、アンダースコア、ハイフンのみを含めることができます。値がこれらの制約を満たさない場合、GitLabはそれを無視し、ヘッダーを送信しなかったかのように評価が進行します。リクエストは失敗しません。

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | タイプ   | 説明 |
|-----------|--------|-------------|
| `outcome` | 文字列 | 評価結果。`allowed`、`warned`、`blocked`のいずれかです。 |
| `reason`  | 文字列 | パッケージが警告またはブロックされた理由を説明するメッセージ。一致するポリシーの名前。`outcome`が`allowed`の場合、`null`。 |

`outcome`属性は次のいずれかの値をとります:

- `allowed`: ポリシー規則がパッケージと一致しませんでした。依存関係ファイアウォールが有効になっていてもポリシーがリンクされていないプロジェクトは、常に`allowed`を返します。`allowed`の結果は、GitLabがパッケージの脆弱性またはライセンスデータを保持しているという断言ではありません。パッケージメタデータデータベースに存在しないパッケージも許可されます。
- `warned`: ポリシー規則がパッケージと一致し、一致するポリシーは警告モードです。
- `blocked`: ポリシー規則がパッケージと一致し、一致するポリシーは適用モードです。

このエンドポイントは、以下のステータスコードも返すことがあります:

| ステータスコード | コード | 説明 |
|-------------|------|-------------|
| `400` | なし | `name`または`version`が空白であるか、`ecosystem`または`operation`が受け入れられる値のいずれでもない場合。 |
| `401` | なし | リクエストが認証されませんでした。 |
| `403` | なし | 認証済みユーザーがプロジェクトのレポーターロール以上を持っていないか、リクエストがそのジョブが実行されているプロジェクト以外のCI/CDジョブトークンを使用した。 |
| `404` | なし | プロジェクトが存在しないか、認証済みユーザーがそれにアクセスできないか、`dependency_firewall_phase1`機能フラグが無効になっています。 |
| `422` | `dependency_firewall_not_enforced` | 依存関係ファイアウォールがプロジェクトに対して有効になっていません。 |
| `429` | なし | このエンドポイントのレート制限を超過しました。この制限は、プロジェクトとユーザーの組み合わせにスコープされています。 |
| `503` | `dependency_firewall_evaluation_failed` | パッケージメタデータの検索が完了しませんでした。フェッチをブロックします。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/evaluate" \
  --data '{"ecosystem": "npm", "name": "lodash", "version": "4.17.15"}'
```

レスポンス例: 

```json
{
  "outcome": "blocked",
  "reason": "Package 'lodash' violates 'deny-mit' policy"
}
```

依存関係ファイアウォールが有効になっているが、ポリシーがリンクされていないプロジェクトの応答例:

```json
{
  "outcome": "allowed",
  "reason": null
}
```

パイプラインジョブから、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)で認証します:

```shell
curl --request POST \
  --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/evaluate" \
  --data '{"ecosystem": "npm", "name": "lodash", "version": "4.17.15"}'
```
