---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: キーワードのマッチングではなく、意味に基づいてリポジトリ内の関連するスニペットを検索します。
title: セマンティック検索
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/16910)されました。

{{< /history >}}

セマンティック検索はAIを使用して、キーワードのマッチングではなく、意味に基づいてリポジトリ内の関連するスニペットを検索します。

セマンティック検索は、コードベースをベクター埋め込みに変換し、これらの埋め込みをベクターデータベースに格納します。検索クエリも埋め込みに変換され、codeコードの埋め込みと比較して、意味的に最も類似した結果を見つけます。このアプローチでは、キーワードが一致しない場合でも、関連するcodeコードが見つかります。

この機能の改善は、[エピック18018](https://gitlab.com/groups/gitlab-org/-/epics/18018)および[エピック20110](https://gitlab.com/groups/gitlab-org/-/epics/20110)で提案されています。

## 前提条件 {#prerequisites}

- 次のいずれかを設定します:
  - [GitLab AIゲートウェイ](../../administration/gitlab_duo/gateway.md)へのkeyアクセス。
  - 埋め込み生成のためにVertex AI `text-embedding-005`モデルへのkeyアクセス権を持つ、[セルフホストAIゲートウェイ](../../install/install_ai_gateway.md)。
- 次の機能をオンにします:
  - GitLab.comの場合、トップレベルネームスペースの実験機能をオンにします。
  - GitLabセルフマネージドの場合、インスタンスのGitLab Duoの実験機能とbetaベータ機能をオンにします。
- プロジェクトに対して[GitLab Duo](turn_on_off.md#turn-gitlab-duo-on-or-off)をオンにします。
- サポートされているベクターストアを設定します:
  - Elasticsearch 8.0以降。
  - OpenSearch 2.0以降。

## セマンティック検索を有効にする {#enable-semantic-code-search}

### UIを使用する場合 {#with-the-ui}

GitLabインスタンスが高度な検索にElasticsearchまたはOpenSearchを使用している場合は、同じクラスターに接続することで、セマンティック検索を有効にできます:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **セマンティック検索**を展開します。
1. **拡張検索クラスターに接続**を選択します。

### Railsコンソールを使用 {#with-the-rails-console}

ElasticsearchまたはOpenSearchのカスタムベクターストア接続を作成するには、Railsコンソールで、`adapter`と`options`を使用して接続を作成します。

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
| `client_adapter`         | 文字列           | いいえ       | `typhoeus` | 使用するHTTPアダプター。使用可能な値は、`typhoeus`と`net_http`です。 |
| `client_request_timeout` | 整数          | いいえ       | `30`       | リクエストのtimeoutタイムアウト（秒単位）。 |
| `retry_on_failure`       | 整数          | いいえ       | `0`        | fail失敗時の再試行回数。 |
| `debug`                  | ブール値          | いいえ       | `false`    | デバッグロギングを有効にします。 |

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
| `client_adapter`         | 文字列           | いいえ       | `typhoeus` | 使用するHTTPアダプター。使用可能な値は、`typhoeus`と`net_http`です。 |
| `client_request_timeout` | 整数          | いいえ       | `30`       | リクエストのtimeoutタイムアウト（秒単位）。 |
| `retry_on_failure`       | 整数          | いいえ       | `0`        | fail失敗時の再試行回数。 |
| `debug`                  | ブール値          | いいえ       | `false`    | デバッグロギングを有効にします。 |
| `aws`                    | ブール値          | いいえ       | `false`    | AWS署名バージョン4署名を有効にします。 |
| `aws_region`             | 文字列           | いいえ       | なし       | OpenSearchドメインのAWSリージョン。 |
| `aws_access_key`         | 文字列           | いいえ       | なし       | AWSアクセスキーID。 |
| `aws_secret_access_key`  | 文字列           | いいえ       | なし       | AWSシークレットアクセスキー。 |

## セマンティック検索を使用する {#use-semantic-code-search}

セマンティック検索は、GitLab MCPサーバーツールとして利用できます。このツールの使用方法の詳細については、[`semantic_code_search`](model_context_protocol/mcp_server_tools.md#semantic_code_search)を参照してください。

GitLabプロジェクトでセマンティック検索を初めて使用する場合:

- リポジトリcodeコードがインデックス作成され、ベクター埋め込みに変換されます。
- これらの埋め込みは、構成されたベクターストアに格納されます。
- codeコードがデフォルトブランチにマージされると、更新は段階的に処理されます。

最初インデックス作成は、リポジトリのサイズに応じて数分かかる場合があります。
