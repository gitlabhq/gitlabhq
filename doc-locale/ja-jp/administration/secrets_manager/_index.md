---
stage: Security Platform
group: Secrets Manager OpenBao
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager（OpenBao）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/16319)され、実験として、GitLab 18.8で一部の初期テスター向けにクローズド[ベータ](../../policy/development_stages_support.md#beta)が提供されました。
- GitLab 19.0でクローズドベータからパブリックベータに[変更](https://gitlab.com/groups/gitlab-org/-/work_items/21731)されました。

{{< /history >}}

[GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md)は、オープンソースのシークレット管理ソリューションである[OpenBao](https://openbao.org/)を使用します。OpenBaoは、GitLabのインスタンスで使用されるシークレットに対して、安全なストレージ、アクセス制御、およびライフサイクル管理を提供します。

GitLab CI/CDジョブで、GitLab Secrets Managerのシークレットを使用する場合は、[GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions) 19.0以降を使用する必要があります。

## OpenBaoアーキテクチャ {#openbao-architecture}

OpenBaoは、既存のGitLabサービスと並行して動作するオプションコンポーネントとして、GitLabと統合されます。

- RailsバックエンドとRunnerは、ロードバランサーを介してOpenBao APIに接続します。
- OpenBaoはPostgreSQLにデータを保存します。Helmチャートは、OpenBaoが同じPostgreSQLインスタンス上の別個の論理データベースを使用するように設定します。Helmチャートの`global.openbao.psql`を使用して接続を設定します。
- OpenBaoは、設定されたシークレットストア（デフォルトではHelmチャートによってマウントされたKubernetesシークレット）からアンシールキーを取得します。
- OpenBaoは、監査ログが有効な場合にRailsバックエンドに監査ログを送信します。

```mermaid
flowchart TB
    SecretStore[Secret store]
    PostgreSQL[PostgreSQL]
    LB[Load balancer]
    OpenBao[OpenBao active node]
    Rails[Rails backend]
    Runner[GitLab Runner]
    Workhorse[Workhorse]

    Rails-- Write secrets and permissions -->LB
    Runner-- Get pipeline secrets -->LB
    LB-->OpenBao
    OpenBao-- Get unseal key -->SecretStore
    OpenBao-- Store -->PostgreSQL
    OpenBao-- Audit logs -->Workhorse
    Workhorse-->Rails
```

OpenBaoは、すべてのリクエストを処理する単一ノードで実行され、アクティブノードが失敗した場合は、オプションで複数のスタンバイノードが引き継ぎます。

## OpenBaoをインストールする {#install-openbao}

前提条件: 

- 管理者アクセス権。
- GitLab 19.0以降。
- Kubernetesクラスター。
- クラウドネイティブGitLabデプロイの場合、外部（Omnibus以外）のPostgreSQLインスタンス。外部のPostgreSQLインスタンスは、クラウドネイティブデプロイ用のGitLab Helmチャートで必要とされ、OpenBao固有のものではありません。OpenBaoは、そのインスタンス上で個別の論理データベースを使用します。

GitLabデプロイに基づいて、インストール方法を選択してください:

- **Cloud Native GitLab**: GitLabをKubernetesにデプロイする場合にこれを使用します。詳細については、[OpenBao Helmチャートドキュメント](https://docs.gitlab.com/charts/charts/openbao/)を参照してください。
- **Linux package**: GitLabをLinuxパッケージで単一ノードまたは複数のノードにデプロイする場合にこれを使用します。詳細については、[LinuxパッケージインスタンスへのOpenBaoのインストール](linux_package_integration.md)を参照してください。

インストール後、[GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md)のユーザードキュメントに従ってOpenBaoが機能していることを確認してください。

## サイジングの推奨事項 {#sizing-recommendations}

OpenBaoのリソース要件は、GitLabインスタンスのサイズとシークレットの使用パターンによって異なります。

これらの推奨事項は、検証済みの開始点です。デプロイをモニタリングし、実際の使用パターンに基づいてリソースを調整してください。要件は、シークレットをフェッチするCI/CDジョブの数、およびシークレットマネージャーが有効になっているグループとプロジェクトの数によって異なります。

### ポッドのリソース {#pod-resources}

OpenBaoは、すべてのリクエストを処理する単一ノードで実行されます。追加のレプリカは、高可用性のフェイルオーバーのみを提供します。OpenBaoはPostgreSQLデータベースに接続されている場合、水平リードスケーラビリティ（HRS）をサポートしないため、スタンバイノードはリードトラフィックを処理しません。

| シークレットフェッチ数/秒 | CPUリクエスト | メモリリクエスト | レプリカ |
|------------------|-------------|----------------|----------|
| 3まで          | 500m        | 2 GB           | 2        |
| 6まで          | 500m        | 3 GB           | 2        |
| 12まで         | 500m        | 4 GB           | 2        |
| 30まで         | 500m        | 9 GB           | 2        |
| 60まで         | 1,000m      | 16 GB          | 2        |
| 150まで        | 2,000m      | 31 GB          | 2        |

#### シークレットフェッチレートの推定 {#estimate-your-secret-fetch-rate}

適用される行を判断するには、1秒あたりのシークレットフェッチ数を推定します:

```plaintext
fetches/s = Git Pull RPS × adoption rate × 3
```

各項目の説明は以下のとおりです: 

- `Git Pull RPS`は、GitLabインスタンスのピークGitプルスループットです。これは、既存の環境モニタリングから測定できます。[ピークトラフィックメトリクスの抽出](../reference_architectures/sizing.md#extract-peak-traffic-metrics)を参照してください。
- `adoption rate`は、シークレットマネージャーを使用するCI/CDジョブの割合（たとえば、5％の場合は0.05、20％の場合は0.20、50％の場合は0.50）です。
- `3`は、シークレットマネージャーを使用するジョブごとにフェッチされるシークレットの想定平均数です。

**シークレットフェッチ数/秒**が結果と同じか、わずかに上回る行を選択します。たとえば、導入率20%でGitプルRPSの測定値が20のデプロイの場合: `20 × 0.20 × 3 = 12 fetches/s`。少なくとも**最大12**の行を使用します。

デプロイ後、推定値を実際の使用量と比較して検証します。[モニタリングクエリ](#monitor-your-openbao-deployment)を使用してリソース使用量を測定し、しきい値を超えた場合は次の行にスケールすることで、リソースを増やしてください。

### リソースの計算方法 {#how-resources-are-calculated}

**CPU**は、CI/CDジョブがシークレットをフェッチする頻度によって決定されます。シークレット書き込み操作（シークレットの作成または更新）は、パイプラインのボリュームに比べて頻度が低く、CPU負荷にはほとんど影響しません。この表では、各CI/CDジョブがGitクローンから始まるため、Gitクローンレート（Git Pull RPS）をCIジョブレートのプロキシとして使用します。式の詳細については、[シークレットフェッチレートの推定](#estimate-your-secret-fetch-rate)を参照してください。CPU制限をCPUリクエストの2倍に設定します。これにより、起動時とプロビジョニング時の急増に対するバーストヘッドルームが提供され、安定状態でのノードの過剰な予約を防ぎます。

**メモリ**はOpenBaoネームスペースの数によって決定され、これはシークレットマネージャーが有効になっているGitLabグループとプロジェクトの数に対応します。1ネームスペースあたり約5 MB、さらに1 GBの安全マージン（最低2 GB）を割り当てます。メモリ制限をメモリリクエスト（保証されたQoSクラス）と等しく設定します。OpenBaoは、メモリ制限を超えると、正常な低下なしにすぐにクラッシュします。

**Replicas**は、高可用性のフェイルオーバーのみを提供します。すべてのデプロイに2つのレプリカを使用します。OpenBaoはPostgreSQLストレージバックエンドでの水平リードスケーラビリティ（HRS）をサポートしないため、追加のレプリカはスループットのメリットを提供しません。

### データベースリソース {#database-resources}

OpenBaoは、PostgreSQL上の独立した論理データベースにデータを保存します。GitLabデータベースと同じPostgreSQLサーバーに配置できます。[リファレンスアーキテクチャのPostgreSQL推奨事項](../reference_architectures/_index.md)を超える追加のデータベースコンピューティング能力は必要ありません。

#### データベース接続プール {#database-connection-pool}

OpenBao Helmチャートは、これらのPostgreSQL接続プールデフォルト値を設定します:

| 設定                                              | デフォルト値 |
|------------------------------------------------------|---------------|
| `config.storage.postgresql.maxParallel`              | 5             |
| `config.storage.postgresql.maxIdleConnections`       | 2             |

モニタリングでデータベース接続の待機時間が観測されない限り、これらの値を増やさないでください。

#### データベースストレージ {#database-storage}

データベースストレージの要件は、主にシークレットの総数に依存します。そのメタデータと保存されたバージョンを含む各シークレットは、約13 KBのストレージを必要とします。

| 総シークレット数  | 推定ストレージ |
|----------------|-------------------|
| 10,000         | ~130 MB           |
| 50,000         | ~650 MB           |
| 100,000        | ~1.3 GB           |
| 200,000        | ~2.6 GB           |

すべてのリファレンスアーキテクチャの階層で、ストレージの増加は無視できます。5〜10 GBのデータベースストレージを割り当てることで、十分なヘッドルームが確保されます。

## GitLab Secrets Managerを有効にする {#enable-gitlab-secrets-manager}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235502)されました

{{< /history >}}

シークレットマネージャーがインスタンスで有効になっている場合、特定の[グループとプロジェクト](../../ci/secrets/secrets_manager/_index.md#enable-gitlab-secrets-manager)でそれを有効にできます。

前提条件: 

- 管理者アクセス権。
- OpenBaoがインストールされ、設定されている必要があります。

シークレットマネージャーをインスタンスに対して有効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Secrets Manager**を展開します。
1. **Secrets Manager**切替をオンにします。

## OpenBaoのデプロイをモニタリングする {#monitor-your-openbao-deployment}

次のクエリを使用して、デプロイが適切にサイジングされていることを確認し、スケーリングが必要な時期を検出してください。

### CPU使用率 {#cpu-utilization}

OpenBao CPU使用量を測定するには:

```prometheus
sum(rate(container_cpu_usage_seconds_total{container="openbao-server"}[5m]))
```

結果はCPUコア単位です。サイジング表のCPUリクエスト値と比較するために、1,000を掛けてミリコアに変換します。CPU使用率がCPUリクエストの50％を常に超える場合は、サイジング表の次の行にスケールすることを検討してください。

### メモリ使用率 {#memory-utilization}

OpenBaoメモリ使用量を測定するには:

```prometheus
sum(container_memory_working_set_bytes{container="openbao-server"})
```

結果はバイト単位です。メモリは、グループとプロジェクトがシークレットマネージャーを有効にすると、1ネームスペースあたり約5 MBずつ増加します。再起動後、OpenBaoがデータベースからネームスペースのメタデータを読み込むと、メモリは安定します。

正しいメモリリクエストを計算するには、シークレットマネージャーが有効になっているグループとプロジェクトを数え、5 MBを掛けてから1 GBを追加します。結果が現在のメモリリクエストを超える場合は、ポッドのリソースを更新してください。メモリがアクティブなプロビジョニングなしに持続的な上昇傾向を示す場合、潜在的な問題について調査してください。

### CPUスロットリング {#cpu-throttling}

レイテンシーに影響を与える可能性のあるCPUスロットリングを検出するには:

```prometheus
sum(rate(container_cpu_cfs_throttled_periods_total{container="openbao-server"}[5m]))
/
sum(rate(container_cpu_cfs_periods_total{container="openbao-server"}[5m]))
```

スロットル比率が0.25（25％）を超える場合、現在のワークロードに対してCPU制限が低すぎることを示します。OpenBaoがスロットルされると、CPU時間を待機しているgoroutineがシークレットフェッチレイテンシーの増加を引き起こします。

### OpenBaoメトリクス {#openbao-metrics}

OpenBao Prometheusメトリクスを使用して、要求レイテンシー、ストレージバックエンドのパフォーマンス、キャッシュの効率性、およびノードの健全性を監視します。

デフォルトでは、OpenBaoはポート`8209`の認証されていないリスナーで、パス`/v1/sys/metrics`のメトリクスを提供します。メトリクス名は`openbao_`プレフィックスを使用し、OpenBaoは24時間メトリクスデータを保持します。ポート、メトリクスのプレフィックス、または保持期間を変更するには、[モニタリング設定オプション](https://docs.gitlab.com/charts/charts/openbao/#monitoring-configuration-options)を参照してください。

メトリクスポートはサービスを通じて公開されていないため、監視機能をスクレイプしてOpenBaoポッドを直接設定します。

Prometheus Operatorを使用している場合、GitLabチャートには、デフォルトで無効になっているPodMonitorが含まれています。これを有効にするには、`openbao.podMonitor.enabled`を`true`に設定します。

これらのメトリクスは、デプロイの運用に最も役立ちます:

| メトリック                               | タイプ    | 説明 |
|--------------------------------------|---------|-------------|
| `openbao_core_active`                | ゲージ   | ノードがアクティブなノード（`1`）であるか、スタンバイノード（`0`）であるか。 |
| `openbao_core_unsealed`              | ゲージ   | ノードがアンシール済み（`1`）か、シール済み（`0`）か。 |
| `openbao_core_in_flight_requests`    | ゲージ   | 同時に処理されているリクエストの数。 |
| `openbao_core_handle_request`        | 概要 | リクエスト処理のレイテンシー。 |
| `openbao_postgres_get`               | 概要 | PostgreSQLストレージバックエンドからエントリを読み取る時間。 |
| `openbao_postgres_put`               | 概要 | PostgreSQLストレージバックエンドにエントリを書き込む時間。 |
| `openbao_postgres_list`              | 概要 | PostgreSQLストレージバックエンドのエントリをリストする時間。 |
| `openbao_postgres_delete`            | 概要 | PostgreSQLストレージバックエンドからエントリを削除する時間。 |
| `openbao_barrier_get`                | 概要 | 暗号化バリアを介してエントリを読み取る時間。 |
| `openbao_barrier_put`                | 概要 | 暗号化バリアを介してエントリを書き込む時間。 |
| `openbao_barrier_list`               | 概要 | 暗号化バリアを介してエントリをリストする時間。 |
| `openbao_barrier_delete`             | 概要 | 暗号化バリアを介してエントリを削除する時間。 |
| `openbao_cache_hit`                  | カウンター | キャッシュヒット数。 |
| `openbao_cache_miss`                 | カウンター | キャッシュミス数。 |
| `openbao_cache_write`                | カウンター | キャッシュ書き込み数。 |
| `openbao_audit_log_request_failure`  | カウンター | 監査ログリクエストの失敗数。 |
| `openbao_audit_log_response_failure` | カウンター | 監査ログ応答の失敗数。 |
| `openbao_runtime_alloc_bytes`        | ゲージ   | OpenBaoプロセスによって割り当てられたメモリのバイト数。 |

概要メトリクスは、`_count`、`_sum`、およびクオンタイル系列（`0.5`、`0.9`、`0.99`）を公開します。平均を計算するには、[レイテンシーの上昇を確認](troubleshooting.md#confirm-latency-is-elevated)で示すように、`_count`系列のレートで`_sum`系列のレートを割ります。

これらのメトリクスを使用するしきい値と診断クエリについては、[低速なシークレット操作を診断する](troubleshooting.md#diagnose-slow-secret-operations)を参照してください。

OpenBaoメトリクスの完全なリストについては、[OpenBaoテレメトリメトリクス](https://openbao.org/docs/internals/telemetry/metrics/all/)を参照してください。

### ヘルスチェックエンドポイント {#health-check-endpoints}

OpenBaoは、モニタリング用のヘルスチェックエンドポイントを提供します:

- `<your-openbao-url>/v1/sys/health`: OpenBaoのヘルスステータスを返します。
- `<your-openbao-url>/v1/sys/seal-status`: シールステータスを返します。

これらのエンドポイントをモニタリングシステムと統合できます。

## 高可用性 {#high-availability}

OpenBaoは単一ノードのアクティブノードアーキテクチャを使用します。1つのノードがすべてのリクエストを処理し、アクティブノードが失敗した場合は、スタンバイノードが自動フェイルオーバーを提供します。

### フェイルオーバー {#failover}

スタンバイノードは起動時にすべてのネームスペースメタデータを読み込むため、アクティブへのプロモーションに追加の初期化は必要ありません。ネームスペースの数はフェイルオーバー時間に影響しません。

本番環境デプロイの場合:

- 冗長性のために少なくとも2つのOpenBaoレプリカを実行します。
- 高可用性のPostgreSQLバックエンドを使用します。
- [モニタリングクエリ](#monitor-your-openbao-deployment)を使用してモニタリングとアラートを実装します。

### アップグレード時のダウンタイム {#upgrade-downtime}

OpenBaoはゼロダウンタイムのアップグレードをサポートしていません。アップグレード中、OpenBaoは起動時に各ネームスペースを順次初期化します。シークレットマネージャーが有効になっているすべてのグループまたはプロジェクトは1つのネームスペースとしてカウントされます。

アップグレードには、1,000ネームスペースあたり約11秒と、ベースラインとして5秒かかります。

OpenBaoがオンデマンドのネームスペース読み込みを実装すると、アップグレードのダウンタイムは大幅に短縮されます。詳細については、[イシュー595721](https://gitlab.com/gitlab-org/gitlab/-/work_items/595721)を参照してください。

## Geoデプロイ {#geo-deployment}

OpenBaoは[Geo](../geo/_index.md)デプロイをサポートしています。OpenBaoはプライマリとセカンダリ両方のGeoサイトにデプロイされますが、プライマリサイトのみがアクティブなOpenBaoノードを実行します。

> [!warning]
> OpenBaoは、異なるドメインを使用するセカンダリサイトへのGeoフェイルオーバーをサポートしていません。セカンダリサイトがプライマリドメインを指すようにDNSを更新せずに独自のドメインを維持する場合、GitLab Secrets Managerが有効になっているすべてのプロジェクトとグループに対してJWT認証を手動で再プロビジョニングする必要があります。再プロビジョニングはルートレベルと各ネームスペースに適用され、大規模なデプロイでは時間がかかります。移行ツールが[issue 595722](https://gitlab.com/gitlab-org/gitlab/-/issues/595722)で提案されています。ツールが存在するまでは、DNSレコードを更新して、プライマリドメインがプロモートされたセカンダリサイトを指すようにします。

### GeoにおけるOpenBaoの動作 {#openbao-behavior-in-geo}

プライマリサイトでは、OpenBaoは書き込み可能なPostgreSQLデータベースに接続されたアクティブノードとして実行されます。セカンダリサイトでは、OpenBaoはPostgreSQLリードレプリカに接続されたスタンバイモードで実行されます。

PostgreSQLストリーミングレプリケーションは、すべてのOpenBaoデータ（シークレット、ポリシー、認証設定）をプライマリからセカンダリサイトに自動的に転送します。

両方のGitLabインスタンス（プライマリとセカンダリ）は、プライマリOpenBao URLに接続します。セカンダリOpenBaoデプロイはスタンバイのままとなり、セカンダリPostgreSQLデータベースが[Geo](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster)フェイルオーバー中に書き込み可能になると、アクティブにプロモートされます。

セカンダリサイトでは、OpenBaoは`failed to acquire lock`および`cannot execute INSERT in a read-only transaction`エラーをログに記録します。これらのエラーは想定される動作です。OpenBaoは読み取り専用データベースでHAリーダーロックを取得できません。

### セカンダリサイトにOpenBaoをインストールする {#install-openbao-on-a-secondary-site}

前提条件: 

- Geoが設定されている必要があります。詳細については、[Geo](../geo/setup/_index.md)の設定を参照してください。
- OpenBaoは、セカンダリにデプロイする前に、プライマリサイトにインストールされ、動作している必要があります。詳細については、[OpenBaoのインストール](#install-openbao)を参照してください。

1. セカンダリOpenBaoは、レプリケートされたデータを復号化するために、プライマリと同じアンシール設定を使用する必要があります。手順は、設定されたアンシール方法によって異なります:

   - Kubernetesシークレット（デフォルト）: プライマリクラスターからセカンダリクラスターへ`gitlab-openbao-unseal` Kubernetesシークレットをコピーします:

     ```shell
     kubectl --namespace gitlab get secret gitlab-openbao-unseal -o yaml
     ```

     エクスポートされたシークレットをセカンダリクラスターに適用します。詳細については、[シークレットをバックアップする](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets)を参照してください。

   - KMSベースの自動アンシール: セカンダリクラスターに同じKMSキーを設定します。詳細については、[シール解除と初期化のオプション](https://docs.gitlab.com/charts/charts/openbao/#unsealing-and-initialization-options)を参照してください。

1. DNSレコードを更新して、フェイルオーバー中にプライマリドメインがセカンダリサイトを指すように計画している場合、事前にOpenBaoを適切に設定することをお勧めします。Helmチャートを設定し、`url`と`jwt_audience`をプライマリOpenBao URLに設定します:

   ```yaml
   global:
     openbao:
       enabled: true
       url: https://openbao.<primary-domain>
       jwt_audience: https://openbao.<primary-domain>
   ```

   チャートの設定オプションの詳細については、[OpenBaoチャートドキュメント](https://docs.gitlab.com/charts/charts/openbao/)を参照してください。

1. セカンダリサイトにGitLab Helmチャートをデプロイします。OpenBaoポッドが起動し、スタンバイモードのままになります。これは想定される動作です。

1. セカンダリクラスターでOpenBaoポッドが実行されていることを確認します:

   ```shell
   kubectl --namespace gitlab get pods -l app=openbao
   ```

   すべてのポッドが`Running`状態である必要があります。セカンダリポッドには`openbao-active: "true"`ラベルがありません。これは想定される動作です。

1. アクティブサービスにセカンダリクラスター上のエンドポイントがないことを確認します:

   ```shell
   kubectl --namespace gitlab get endpoints gitlab-openbao-active
   ```

   セカンダリにエンドポイントがないことは想定される動作です。

1. CIパイプラインを実行してシークレットマネージャーをテストし、セカンダリサイトで[シークレットマネージャー変数](../../ci/secrets/secrets_manager/_index.md)を使用します。

## トラブルシューティング {#troubleshooting}

デプロイ、接続、プロビジョニング、シーリング、データベース、監査ログ、およびGeoに関する問題を診断するには、[OpenBaoのトラブルシューティング](troubleshooting.md)を参照してください。

## メンテナンス {#maintenance}

OpenBaoをバックアップおよび復元する、リカバリーキーを管理する、またはOpenBao認証をリカバリーするには、[OpenBaoを保守する](maintenance.md)を参照してください。
