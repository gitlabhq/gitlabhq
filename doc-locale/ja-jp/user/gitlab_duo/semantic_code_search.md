---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: キーワードのマッチングではなく、意味に基づいてリポジトリ内の関連するコードスニペットを検索します。
title: セマンティックコード検索
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/16910)されました。

{{< /history >}}

セマンティックコード検索はAIを使用して、キーワードのマッチングではなく、意味に基づいてリポジトリ内の関連するスニペットを検索します。

セマンティックコード検索では、コードベースをベクター埋め込みに変換し、これらの埋め込みをベクターデータベースに保存します。検索クエリも埋め込みに変換され、コードの埋め込みと比較することで、意味的に最も近い結果を見つけます。このアプローチにより、キーワードが一致しない場合でも関連するコードを見つけることができます。

この機能に対する改善は、[エピック18018](https://gitlab.com/groups/gitlab-org/-/epics/18018)および[エピック20110](https://gitlab.com/groups/gitlab-org/-/epics/20110)で提案されています。

## 前提条件 {#prerequisites}

- 次のいずれかが設定されていること:
  - [GitLab AIゲートウェイ](../../administration/gitlab_duo/gateway.md)へのアクセス。
  - 埋め込み生成のためにVertex AIの`text-embedding-005`モデルにアクセスできる、[セルフホストAIゲートウェイ](../../install/install_ai_gateway.md)。
- 次の機能をオンにすること:
  - GitLab.comの場合、トップレベルネームスペースに対する実験的機能。
  - GitLab Self-Managedの場合、インスタンスに対するGitLab Duoの実験的機能およびベータ版機能。
- プロジェクトで[GitLab Duo](turn_on_off.md#turn-gitlab-duo-on-or-off)がオンになっていること。
- サポートされているベクターストアが設定されていること:
  - Elasticsearch 8.0以降。
  - OpenSearch 2.0以降。
- 管理者アクセス権が必要です。

## セマンティックコード検索を有効にする {#enable-semantic-code-search}

### UIを使用する場合 {#with-the-ui}

GitLabインスタンスで高度な検索にElasticsearchまたはOpenSearchを使用している場合は、同じクラスターに接続することで、セマンティックコード検索を有効にできます:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **セマンティック検索**を展開します。
1. **拡張検索クラスターに接続**を選択します。

### Railsコンソールを使用する場合 {#with-the-rails-console}

ElasticsearchまたはOpenSearch用にカスタムベクターストア接続を作成するには、Railsコンソールで、`adapter`と`options`を使用して接続を作成します。

#### Elasticsearch {#elasticsearch}

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elasticsearch",
  options: { url: ["http://your-elasticsearch-url:9200"] },
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter"
)
connection.activate!
```

接続オプション:

| オプション                   | 型             | 必須 | デフォルト    | 説明 |
|--------------------------|------------------|----------|------------|-------------|
| `url`                    | 文字列の配列 | はい      | なし       | ElasticsearchクラスターのURLの配列（例: `["http://localhost:9200"]`）。 |
| `client_adapter`         | 文字列           | いいえ       | `typhoeus` | 使用するHTTPアダプター。使用可能な値は`typhoeus`と`net_http`です。 |
| `client_request_timeout` | 整数          | いいえ       | `30`       | リクエストのタイムアウト（秒）。 |
| `retry_on_failure`       | 整数          | いいえ       | `0`        | 失敗時の再試行回数。 |
| `debug`                  | ブール値          | いいえ       | `false`    | デバッグログを有効にします。 |

#### OpenSearch {#opensearch}

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "opensearch",
  options: { url: ["http://your-opensearch-url:9200"] },
  adapter_class: "ActiveContext::Databases::Opensearch::Adapter"
)
connection.activate!
```

接続オプション:

| オプション                   | 型             | 必須 | デフォルト    | 説明 |
|--------------------------|------------------|----------|------------|-------------|
| `url`                    | 文字列の配列 | はい      | なし       | OpenSearchクラスターのURLの配列（例: `["http://localhost:9200"]`）。 |
| `client_adapter`         | 文字列           | いいえ       | `typhoeus` | 使用するHTTPアダプター。使用可能な値は`typhoeus`と`net_http`です。 |
| `client_request_timeout` | 整数          | いいえ       | `30`       | リクエストのタイムアウト（秒）。 |
| `retry_on_failure`       | 整数          | いいえ       | `0`        | 失敗時の再試行回数。 |
| `debug`                  | ブール値          | いいえ       | `false`    | デバッグログを有効にします。 |
| `aws`                    | ブール値          | いいえ       | `false`    | AWS Signature Version 4署名を有効にします。 |
| `aws_region`             | 文字列           | いいえ       | なし       | OpenSearchドメインのAWSリージョン。 |
| `aws_access_key`         | 文字列           | いいえ       | なし       | AWSアクセスキーID。 |
| `aws_secret_access_key`  | 文字列           | いいえ       | なし       | AWSシークレットアクセスキー。 |

## セマンティックコード検索を使用する {#use-semantic-code-search}

セマンティックコード検索は、GitLab MCPサーバーツールとして利用できます。このツールの使用方法の詳細については、[`semantic_code_search`](model_context_protocol/mcp_server_tools.md#semantic_code_search)を参照してください。

GitLabプロジェクトでセマンティックコード検索を初めて使用する場合:

- リポジトリ内のコードのインデックスが作成され、ベクター埋め込みに変換されます。
- これらの埋め込みは、設定済みのベクターストアに保存されます。
- コードがデフォルトブランチにマージされると、更新は段階的に処理されます。

初回のインデックス作成には、リポジトリのサイズに応じて数分かかる場合があります。
