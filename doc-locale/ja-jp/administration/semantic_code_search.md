---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managedインスタンスでセマンティック検索の管理と設定を行います。
title: セマンティック検索の管理
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で[ベータ版](../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/16910)されました。
- GitLab 18.8でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259)されました。
- GitLab 18.9でGitLab Premiumに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/590394)されました。

{{< /history >}}

> [!note]
> ユーザードキュメントについては、[セマンティック検索](../user/gitlab_duo/semantic_code_search.md)を参照してください。

セマンティック検索を使用すると、AIネイティブなGitLab Duo機能は、リポジトリ内の関連するコードスニペットを見つけることができます。

## 前提条件 {#prerequisites}

- [GitLab AIゲートウェイ](gitlab_duo/gateway.md)または[GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md)へのアクセス。詳細については、[埋め込みモデル](#embedding-models)を参照してください。
- ベータ版および実験的機能が[インスタンス](../user/duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-2)で有効になっている。
- [ベクターストアが設定されている](#vector-storage):
  - Elasticsearch 8.0以降。
  - OpenSearch 2.0以降。
  - [`pgvector`](https://github.com/pgvector/pgvector)拡張機能付きのPostgreSQL。
- GitLab Duo Self-Hostedの場合、[埋め込みモデルが設定されている](#configure-an-embedding-model)。

## ベクターストレージ {#vector-storage}

大規模なリポジトリにはElasticsearchまたはOpenSearchを使用してください。`pgvector`付きのPostgreSQLは、少数の小さなリポジトリがあるセットアップのみに使用してください。インデックス作成およびクエリのパフォーマンスは、`pgvector`で制限される可能性があります。

### 詳細検索のクラスターに接続する {#connect-to-the-advanced-search-cluster}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/18905)されました。

{{< /history >}}

GitLabインスタンスがElasticsearchまたはOpenSearchを[詳細検索](../user/search/advanced_search.md)に使用している場合、同じクラスターに接続することでセマンティック検索を有効にできます:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **セマンティック検索**を展開します。
1. **ベクターストレージ**で、**設定する**を選択します。
1. **ベクターストレージ**ページで、**Advanced search cluster**の下にある**接続**を選択します。

### カスタムベクターストアを設定する {#configure-a-custom-vector-store}

Elasticsearch、OpenSearch、またはPostgreSQL用のカスタムベクターストア接続を設定するには:

- Railsコンソールで、`adapter_class`と`options`を使用して`Ai::ActiveContext::Connection`を作成します。

#### Elasticsearch {#elasticsearch}

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elasticsearch",
  options: options,
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
  options: options,
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
| `aws_role_arn`           | 文字列           | いいえ       | なし       | ロールベースの認証用のAWS IAMロールARN。 |

#### `pgvector`機能付きPostgreSQL {#postgresql-with-pgvector}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/552311)されました。

{{< /history >}}

PostgreSQLでは、[`pgvector`](https://github.com/pgvector/pgvector)拡張機能を使用します:

1. PostgreSQLデータベースで、拡張機能を作成します:

   ```sql
   CREATE EXTENSION vector;
   ```

1. Railsコンソールで、接続を作成します:

   ```ruby
   connection = Ai::ActiveContext::Connection.create!(
     name: "postgres",
     options: options,
     adapter_class: "ActiveContext::Databases::Postgresql::Adapter"
   )
   connection.activate!
   ```

接続オプション:

| オプション           | 型    | 必須 | デフォルト | 説明 |
|------------------|---------|----------|---------|-------------|
| `host`           | 文字列  | はい      | なし    | PostgreSQLホスト。 |
| `port`           | 整数 | いいえ       | なし    | PostgreSQLポート。 |
| `database`       | 文字列  | いいえ       | なし    | データベース名。 |
| `user`           | 文字列  | いいえ       | なし    | PostgreSQLユーザー。 |
| `password`       | 文字列  | いいえ       | なし    | PostgreSQLパスワード。 |
| `connect_timeout`| 整数 | いいえ       | `5`     | 接続タイムアウト（秒）。 |
| `pool_size`      | 整数 | いいえ       | `5`     | 接続プールサイズ。 |

## 埋め込みモデルを設定する {#configure-an-embedding-model}

埋め込みモデルを設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **セマンティック検索**を展開します。
1. **Code embeddings**については、**モデルを設定**を選択します。すでに埋め込みモデルを設定している場合は、代わりに**モデルの変更**が表示されます。
1. **Semantic search code embeddings**ページで、埋め込みモデル、埋め込みディメンション、およびチャンキング戦略を選択します。
1. **埋め込みを設定する**を選択します。すでに埋め込みモデルを設定している場合は、代わりに**埋め込みを更新し、バックフィル処理を開始します**が表示されます。

> [!warning]
> 埋め込みモデルまたはディメンションを変更すると、コードベースのサイズによっては数時間かかるバックフィルが実行されます。この処理中もセマンティック検索は引き続き利用可能です。

### 埋め込みモデル {#embedding-models}

#### GitLab管理モデル {#gitlab-managed-models}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/582638)され、`semantic_search_user_model_selection`という名前の[機能フラグ](feature_flags/_index.md)で提供されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLab管理モデルは、[GitLab AIゲートウェイ](gitlab_duo/gateway.md)で提供されます。Gemini Enterprise Agent Platformによって提供される`text-embedding-005`モデルを選択します。

[GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md)セットアップでGitLab管理モデルを選択することもできます。詳細については、[ハイブリッドAIゲートウェイとモデル設定](gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration)を参照してください。

> [!warning]
> GitLabが選択したモデルを非推奨にした場合、ご自身で別のモデルに切り替える必要があります。

#### セルフホストモデル {#self-hosted-models}

{{< history >}}

- GitLab 19.1で`semantic_search_user_model_selection`[機能フラグ](feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/588849)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

セルフホストモデルは、[独自のインフラストラクチャでホストされる](gitlab_duo_self_hosted/_index.md) AIモデルです。

セルフホストモデルを選択するには:

1. [GitLab Duo Self-Hosted](gitlab_duo_self_hosted/_index.md)をセットアップします。
1. モデルファミリーに`EMBEDDING`を指定して、[セルフホストモデルを追加](gitlab_duo_self_hosted/configure_duo_features.md#add-a-self-hosted-model)します。

### チャンク戦略 {#chunking-strategy}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/600201)され、`semantic_search_user_model_selection`という名前の[機能フラグ](feature_flags/_index.md)で提供されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

チャンク戦略は、コードファイルを埋め込み用のより小さなスニペットに分割するために使用されるアルゴリズムです。次のいずれかの戦略を選択します:

- コードバイト: コードの構造やセマンティクスを考慮せずに、コードを固定サイズのバイトチャンクに分割します。チャンクサイズは、チャンクあたりの最大バイト数を指します。次の場合にこの戦略を使用します:
  - より高速なインデックス作成と、より予測可能なチャンクサイズ。
  - 多様なファイルタイプと言語を持つリポジトリ。
- コードpre-BERT: BERTベースの埋め込みモデル用に最適化されたセマンティック境界を使用してコードを分割します。チャンクサイズは、チャンクあたりの最大トークン数を指します。次の場合にこの戦略を使用します:
  - 検索品質の向上と、コード構造を尊重したより意味のあるチャンク。
  - 整然としたコードを持つリポジトリ。

> [!warning]
> チャンク戦略は、埋め込みモデルを初めて設定するときにのみ選択できます。インデックス作成が開始された後にチャンク戦略を変更するには、インスタンスを完全に再インデックス作成する必要があります。自動再インデックス作成のサポートは、[イシュー600200](https://gitlab.com/gitlab-org/gitlab/-/work_items/600200)および[イシュー602138](https://gitlab.com/gitlab-org/gitlab/-/work_items/602138)で提案されています。

## セマンティック検索ステータスの確認 {#check-semantic-code-search-status}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/596795)されました。

{{< /history >}}

セマンティック検索のステータス（インデックス作成ステータス、ベクターストア接続の詳細、リポジトリ統計、埋め込みキューサイズなど）を確認するには、このRakeタスクを実行します:

```shell
sudo gitlab-rake gitlab:semantic_search:code:info
```

ステータスを継続的に監視するには、監視間隔を秒単位で指定します:

```shell
sudo gitlab-rake "gitlab:semantic_search:code:info[5]"
```

このタスクは、指定された間隔で出力を更新します。タスクを停止するには、<kbd>Control</kbd>+<kbd>C</kbd>を押します。

## デッドキューの管理 {#manage-the-dead-queue}

前提条件: 

- `admin_mode`、`ai_features`、`api`のスコープを持つパーソナルアクセストークン。

埋め込み生成が繰り返し失敗すると、手動介入のためにアイテムがデッドキューに移動されます。デッドキューのサイズは、[ステータスRakeタスク](#check-semantic-code-search-status)出力の`Embedding Queues`セクションで確認できます。

### デッドキューのクリア {#clear-the-dead-queue}

デッドキューからすべてのアイテムを削除するには、このコマンドを実行します:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_token>" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue"
```

### デッドキューの再実行 {#replay-the-dead-queue}

デッドキューアイテムを別の試行のために処理キューに戻すには、`queue`パラメータを使用してターゲットを指定します。有効な値は`retry_queue`、`code`、`code_backfill`です。

デッドキューに再度失敗する前に、もう一度処理を試行するには、`retry_queue`を使用します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --data "queue=retry_queue" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue/replay"
```

メインのコードキューにアイテムを追加するには、`code`を使用します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --data "queue=code" \
  "https://gitlab.example.com/api/v4/admin/active_context/dead_queue/replay"
```
