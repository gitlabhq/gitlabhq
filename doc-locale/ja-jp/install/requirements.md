---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インストールに必要な前提条件。
title: GitLabのインストール要件
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managedには、デプロイ規模とワークロードに応じて異なる特定のハードウェア、コンポーネント、およびインフラストラクチャの要件があります。大規模な、または分散型のデプロイの場合は、[サイジングガイド](../administration/reference_architectures/sizing.md)を使用して、環境に合った適切な仕様を決定してください。

## ハードウェア {#hardware}

GitLabを単一ノード、または複数のノードにわたって分散型でデプロイできます。単一ノードインストールに必要な最小ハードウェア要件を以下に示します。分散型デプロイの場合、要件はコンポーネントの種類ごとに割り当てられ、負荷に応じてスケールします。期待される負荷とワークロード構成に基づいて適切な仕様を決定するには、[サイジングガイド](../administration/reference_architectures/sizing.md)を使用してください。

### CPU {#cpu}

単一ノードインストールの場合、8 vCPUがベースラインです。ARMベースのプロセッサがサポートされています。分散型デプロイの場合、CPUはコンポーネントの種類ごとに割り当てられ、負荷に応じてスケールします。

> [!note]
> パフォーマンスが不安定なため、バースト可能なインスタンスタイプは推奨されません。

### メモリ {#memory}

単一ノードインストールの場合、16 GBがベースラインです。分散型デプロイの場合、メモリはコンポーネントの種類ごとに割り当てられ、負荷に応じてスケールします。

メモリに制約のある環境での単一ノードインストールの場合、GitLabは最低8 GBのメモリで実行できます。詳細については、[メモリ制約のある環境でGitLabを実行する](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/)を参照してください。

> [!note]
> 可能な場合はスワップを無効にしてください。スワップは、負荷がかかるとパフォーマンスが著しく低下する可能性があります。スワップを無効にできない場合は、GitLabが使用しないように十分なメモリをプロビジョニングしてください。

### ストレージ {#storage}

ストレージ要件はコンポーネント固有です。単一ノードインストールの場合、すべての要件を1台のマシンに集約します。分散型デプロイの場合は、それぞれを関連するノードタイプに適用します:

| コンポーネント | 最小ストレージ | 備考 |
|-----------|----------------|-------|
| アプリケーションノード（Rails, Sidekiq, Puma） | 40 GB | パッケージのインストール（約2.5 GB）のほか、OS、ログ、一時ファイル。 |
| リポジトリストレージ（Gitaly） | すべてのリポジトリを合計した容量以上 | [Gitalyディスク要件](../administration/gitaly/_index.md#disk-requirements)を参照してください。 |
| データベース（PostgreSQL） | 5-12 GB | [PostgreSQLストレージ要件](#storage-requirements)を参照してください。 |

NFS、Amazon EFS、Azure Filesなどのネットワークファイルシステムは、パフォーマンスに大きな影響を与える可能性があるため、避けてください。詳細については、[クラウドベースのファイルシステムの回避](../administration/nfs.md#avoid-using-cloud-based-file-systems)を参照してください。

> [!note]
> 最高のパフォーマンスを得るには、SSDベースのストレージを使用してください。これは、I/O負荷の高いGitalyにとって特に重要です。パフォーマンスが不安定なため、バースト可能なディスクタイプは推奨されません。

## インフラストラクチャ {#infrastructure}

GitLabは、さまざまなインフラストラクチャタイプで動作します。次のセクションでは、サポートされているプラットフォームと高可用性の要件について説明します。

### サポートされているインフラストラクチャ {#supported-infrastructure}

GitLabは、基盤となる環境がこのガイドで説明されているハードウェアおよびコンポーネントの要件を満たしている場合、クラウドプロバイダーおよびセルフマネージドインフラストラクチャで動作します。一般的に使用されるクラウドプロバイダーには、AWS、GCP、Azureなどがあります。[GitLab Support](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support)はGitLab自体を対象としています。基盤となるインフラストラクチャまたはプラットフォームに関するイシューは、そのスコープ外です。

Cloud Nativeデプロイの場合、GitLabは[GitLab Helmチャートの前提条件](https://docs.gitlab.com/charts/installation/tools/)を満たすすべてのKubernetesディストリビューションで実行されます。Kubernetesプラットフォーム固有の動作（ネットワーキング、ストレージクラス、認証など）は、GitLabサポートのスコープ外です。

### 高可用性 {#high-availability}

HAのデプロイには、特定のネットワーク要件があります:

- 同期レプリケーションをサポートするには、ノード間のレイテンシーが5ミリ秒未満である必要があります。
- 耐障害性を高めるには、アベイラビリティーゾーンをまたいでデプロイすることが推奨されます。クォーラム要件を満たすには、奇数個のゾーンを使用してください。
- 複数のセルフマネージドデータセンターにまたがってデプロイするには、同期可能なレイテンシー、冗長なネットワークリンク、および同じ地理的リージョン内に奇数個のセンターが必要です。

> [!warning]
> 単一のGitLabインスタンスは、複数の地理的リージョンにまたがって展開してはなりません。マルチリージョンデプロイの場合は、地理的に分散されたインストール向けに設計された[Geo](../administration/geo/_index.md)を使用してください。複数のデータセンターでのデプロイにおけるインフラストラクチャ関連のイシューは、GitLabサポートのスコープ外となる可能性があります。

## コンポーネント要件 {#component-requirements}

### PostgreSQL {#postgresql}

[PostgreSQL](https://www.postgresql.org/)は唯一サポートされているデータベースであり、以下で利用可能です:

- Linuxパッケージに[バンドルされたインスタンス](https://docs.gitlab.com/omnibus/settings/database/)として。
- [外部サービス](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server)として。

外部インスタンスについては、以下を参照してください:

- 外部で管理されるインスタンスの[必須設定](../administration/postgresql/tune.md#required-settings-for-external-instances)。
- スキーマガイダンスについては、[データベーススキーマ](../administration/postgresql/external.md#database-schemas)を参照してください。
- ロケールに関する考慮事項については、[ロケールの互換性を確認するタイミング](../administration/postgresql/upgrading_os.md#when-to-check-locale-compatibility)を参照してください。

#### サポートされているバージョン {#supported-versions}

次のバージョンのGitLabでは、対応するPostgreSQLバージョンを使用してください。

| GitLabバージョン | Helmチャートバージョン | PostgreSQLの最小バージョン | PostgreSQLの最大バージョン |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 19.x           | 10.x               | 17.x                       | 17.x                       |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 17.x（[GitLab 17.10以降でテスト済み](https://gitlab.com/gitlab-org/gitlab/-/issues/521159)） |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x（[GitLab 16.10以降に対してテスト済み](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)） |
| 16.x           | 7.x                | 13.6                       | 15.x（[GitLab 16.1以降に対してテスト済み](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)） |

PostgreSQLのマイナーリリースには、[バグとセキュリティの修正のみが含まれます](https://www.postgresql.org/support/versioning/)。PostgreSQLで既知のイシューを回避するため、常に最新のマイナーバージョンを使用してください。詳細については、[イシュー364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)を参照してください。

指定されているバージョンよりも新しいPostgreSQLのメジャーバージョンを使用するには、[新しいバージョンがLinuxパッケージにバンドルされているかどうか](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)を確認してください。

#### ストレージ要件 {#storage-requirements}

[ユーザー数](../administration/reference_architectures/_index.md)に応じて、PostgreSQLサーバーには以下が必要です。

- ほとんどのGitLabインスタンスの場合、少なくとも5～10 GBのストレージ。
- Ultimateの場合、少なくとも12 GBのストレージ（1 GBの脆弱性データをインポートする必要があります）。

#### 拡張機能 {#extensions}

拡張機能をインストールするには、PostgreSQLにはスーパーユーザー権限が必要です。手順については、[Manage PostgreSQL extensions](../administration/postgresql/extensions.md)を参照してください。

| 拡張機能            | 最小GitLabバージョン | タイプ        | データベース |
|----------------------|------------------------|-------------|----------|
| `amcheck`            | 18.4                   | 必須    | メイン |
| `btree_gist`         | 13.1                   | 必須    | メイン |
| `pg_trgm`            | 8.6                    | 必須    | メイン |
| `plpgsql`            | 11.7                   | 必須    | main、[Geoセカンダリ追跡データベース](../administration/geo/_index.md)（最小バージョン9.0） |
| `pg_stat_statements` | –                      | 推奨 | すべて |

#### Gitaly Cluster (Praefect) {#gitaly-cluster-praefect}

[Gitalyクラスター](../administration/gitaly/praefect/_index.md)には、メインのGitLabデータベースとは別の専用PostgreSQLインスタンスが必要です。完全なHAを実現するには、サードパーティのPostgreSQLソリューションを使用してください。Linuxパッケージを使用する非HAのPostgreSQLインスタンスは、Gitalyのデータベースレベルの冗長性を必要としない環境には十分です。

### RedisまたはValkey {#redis-or-valkey}

[Redis](https://redis.io/)または[Valkey](https://valkey.io/)は、すべてのユーザーセッションとバックグラウンドタスクを保存します。

サポートされているRedisまたはValkeyのバージョンは次のとおりです:

| データストア | 推奨バージョン | 最小バージョン |
| --------- | ------------------- | --------------- |
| Redis     | 7.2                 | 7.0<sup>1</sup> |
| Valkey    | 7.2                 | 7.2             |

<sup>1</sup> Redis 7.0はアップストリームでEOL（End-of-Life）に達しましたが、ベンダーによっては積極的にメンテナンスされている場合があります。たとえば、Amazon ElastiCache for Redis 7.1は独自のバージョン番号を使用していますが、Redis 7.0をベースに構築されています。

Redisのサポート終了日に関する詳細については、[Redisドキュメント](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/)を参照してください。

- スタンドアロンインスタンスを使用します（高可用性の有無にかかわらず）。Redisクラスターはサポートされていません。
- Serverless RedisおよびValkeyのバリアントはサポートされていません。
- 必要に応じて[削除ポリシー](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy)を設定します。

### Puma {#puma}

推奨される[Puma](https://puma.io/)設定は、[インストール](install_methods.md)によって異なります。デフォルトでは、Linuxパッケージは推奨設定を使用します。

Pumaの設定を調整するには: 

- Linuxパッケージについては、[Puma設定](../administration/operations/puma.md)を参照してください。
- GitLab Helmチャートについては、[`webservice`チャート](https://docs.gitlab.com/charts/charts/gitlab/webservice/)を参照してください。

ワーカーおよびスレッドのサイジングガイダンスについては、[Pumaワーカーおよびスレッドのサイジング](../administration/operations/puma.md#worker-and-thread-sizing)を参照してください。

### Sidekiq {#sidekiq}

[Sidekiq](https://sidekiq.org/)は、複数のスレッドを使用してバックグラウンドジョブを処理します。各プロセスには最低200 MBのメモリが必要で、負荷がかかると大幅に増加する可能性があります。10,000人を超えるユーザーがいる環境では、Sidekiqプロセスごとに少なくとも1 GBを割り当ててください。

### オブジェクトストレージ {#object-storage}

オブジェクトストレージは分散型デプロイに必須であり、すべてのインストールで推奨されます。LFSオブジェクト、CI/CDアーティファクト、アップロード、コンテナレジストリデータ、バックアップなど、バイナリデータを保存します。

任意のS3互換オブジェクトストレージサービスを使用してください。設定およびテスト済みのプロバイダーのリストについては、[オブジェクトストレージ](../administration/object_storage.md)を参照してください。

## オプションコンポーネント {#optional-components}

これらのコンポーネントは、コアGitLabのインストールには必須ではありませんが、使用する場合には個別のインフラストラクチャまたはリソース要件があります。

### コンテナレジストリ {#container-registry}

[GitLabコンテナレジストリ](../administration/packages/container_registry.md)は、GitLabプロジェクト用のDockerおよびOCIイメージを保存し、以下を必要とします:

- ドメイン。
- TLS証明書。
- ファイルシステムまたはS3互換オブジェクトストレージのいずれか。

高トラフィック環境の場合、レジストリはメインのGitLabインスタンスとは別の専用インフラストラクチャで実行できます。

### GitLab Pages {#gitlab-pages}

[GitLab Pages](../administration/pages/_index.md)は、プロジェクトとグループの静的ウェブサイトをホストします。これは別のデーモンとして実行され、DNSワイルドカードを必要とします。カスタムドメインのサポートには、セカンダリIPアドレスとTLS証明書が必要です。

### ElasticsearchとOpenSearch {#elasticsearch-and-opensearch}

[高度な検索](../integration/advanced_search/elasticsearch.md)は、GitLabコンテンツ全体でより高速で高性能な検索を可能にします。これには、個別のElasticsearchまたはOpenSearchクラスターが必要です。クラスターのサイズは、インデックス付きデータの量によって異なります。

### Prometheus {#prometheus}

[Prometheus](https://prometheus.io)モニタリングはLinuxパッケージにバンドルされており、デフォルトで有効になっています。設定または無効化に関する情報については、[Prometheusを使用したGitLabのモニタリング](../administration/monitoring/prometheus/_index.md)を参照してください。

### Zoekt {#zoekt}

[Zoekt](../integration/zoekt/_index.md)は、リポジトリ全体で完全一致コードの検索を提供し、個別のサービスとして実行されます。リソース要件については、[Zoekt管理](../integration/zoekt/_index.md)を参照してください。

### ClickHouse {#clickhouse}

[ClickHouse](../integration/clickhouse.md)は、オープンソースの列指向データベースであり、プロダクト分析機能に使用されます。これは別のデータベースサービスとして実行されます。リソース要件については、[ClickHouse設定](../integration/clickhouse.md)を参照してください。

### AIゲートウェイ {#ai-gateway}

[AIゲートウェイ](install_ai_gateway.md)は、GitLab DuoのAI機能のバックエンドサービスを提供します。これは、DockerまたはKubernetesにデプロイ可能なスタンドアロンサービスとして実行されます。リソース要件については、インストールガイドを参照してください。

### シークレットマネージャー {#secrets-manager}

[GitLab Secrets Manager](../administration/secrets_manager/_index.md)は、OpenBaoを搭載したネイティブのシークレット管理を提供します。これは、個別のKubernetesサービスとして実行され、専用のPostgreSQLデータベースとロードバランサーを必要とします。

## サポートされているWebブラウザ {#supported-web-browsers}

GitLabは、次のWebブラウザをサポートしています。

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLabは、[Baseline](https://web-platform-dx.github.io/baseline/) Widely availableブラウザセットをターゲットにしています。これらは、すべてのコアブラウザで安定したウェブプラットフォーム機能をサポートするブラウザのバージョンです。機能は、少なくとも30か月後にWidely availableステータスに達します。Widely availableブラウザセットには、これらのブラウザのデスクトップバージョンとモバイルバージョンの両方が含まれます。

これらのブラウザでJavaScriptを無効にしてGitLabを実行することはサポートされていません。

## 関連トピック {#related-topics}

- [GitLab Runnerをインストールする](https://docs.gitlab.com/runner/install/)
- [インストールのセキュリティ保護](../security/_index.md)
- [Geoを実行するための要件](../administration/geo/_index.md#requirements-for-running-geo)
