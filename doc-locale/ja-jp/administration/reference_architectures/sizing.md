---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: リファレンスアーキテクチャのサイズとコンポーネント固有の調整を定義するためのガイドライン。
title: リファレンスアーキテクチャのサイジング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

適切なリファレンスアーキテクチャを選択するには、リファレンスアーキテクチャに基づいてGitLab環境を評価およびサイジングするための体系的なアプローチを使用する必要があります。

適切なリファレンスアーキテクチャと必要なコンポーネント固有の調整を決定するために、次の情報が分析に役立ちます:

- 1秒あたりのリクエスト数（RPS）パターン。
- ワークロードの特性。
- リソース飽和。

{{< alert type="note" >}}

専門家によるガイドラインが必要ですか？アーキテクチャのサイズを正しく設定することは、最適なパフォーマンスを得るために重要です。弊社の[Professional Services](https://about.gitlab.com/professional-services/)チームは、お客様固有のアーキテクチャを評価し、パフォーマンス、安定性、可用性の最適化に関するテーラーメイドの推奨事項を提供します。

{{< /alert >}}

## 始める前に {#before-you-begin}

このドキュメントでは、PrometheusモニタリングがGitLabインスタンスとともにデプロイされていることを前提としています。Prometheusは、適切なサイジング評価に必要な正確なメトリクスを提供します。

Prometheusをまだ構成していない場合:

1. [Prometheus](../monitoring/prometheus/_index.md)でモニタリングを構成します。リファレンスアーキテクチャのドキュメントには、各環境サイズに対するPrometheus設定の詳細が記載されています。クラウドネイティブGitLabの場合、[`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) Helmチャートを使用してメトリクスのスクレイプを構成できます。
1. 有意なデータパターンを収集するために、7〜14日間データを収集します。
1. この情報の残りの部分をお読みください。

Prometheusモニタリングを構成できない場合:

- サイズを推定するために、最も近いリファレンスアーキテクチャに対する[現在の環境を比較](#analyze-current-environment-and-validate-recommendations)してください。
- ログから基本的なピークRPSを抽出するには、[`get-rps.rb`スクリプト](https://gitlab.com/gitlab-com/support/toolbox/dotfiles/-/blob/main/scripts/get-rps.rb)を使用します。ログ分析には重大な制限があります。メトリックよりも信頼性の低いデータが提供され、クラウドネイティブGitLabでは利用できません。

他のプラットフォームから移行する場合、既存のGitLabメトリクスがないと、次のPromQLクエリは適用できません。ただし、一般的な評価開発手法は引き続き有効です:

1. 予想されるワークロードに基づいて、最も近いリファレンスアーキテクチャを見積もります。
1. 予想される追加のワークロードを特定します。
1. 大規模なリポジトリの数を評価します
1. 成長予測を組み込みます。
1. [適切なバッファ](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down)を持つリファレンスアーキテクチャを選択します。

### PromQLクエリの実行 {#running-promql-queries}

PromQLクエリの実行は、使用するモニタリングソリューションによって異なります。[Prometheusモニタリングのドキュメント](../monitoring/prometheus/_index.md#how-prometheus-works)に記載されているように、モニタリングデータには、Prometheusに直接接続するか、Grafanaのようなダッシュボードツールを使用することでアクセスできます。

## ベースラインサイズの決定 {#determine-your-baseline-size}

1秒あたりのリクエスト数（RPS）は、GitLabインフラストラクチャのサイジングの主要なメトリクスです。さまざまなトラフィックタイプ（API、Web、Gitオペレーション）はさまざまなコンポーネントに負荷をかけるため、真の容量要件を見つけるためにそれぞれ個別に分析されます。

### ピークトラフィックメトリクスの抽出 {#extract-peak-traffic-metrics}

これらのクエリを実行して、最大の負荷を理解してください。これらのクエリは以下を示しています:

- 絶対ピーク：今までに見られた最も高いスパイク。絶対ピークは最悪のシナリオを示します。
- 維持されたピーク：95パーセンタイルであり、通常の「ビジー」レベルと見なされます。維持されたピークは、典型的な高負荷期間を示します。

絶対ピークがまれなアノマリである場合、維持された負荷に対するサイジングが適切な場合があります。

保持に基づいてクエリの時間範囲を調整します（より長い履歴が利用可能な場合は、`[7d]`を`[30d]`に変更します）。

#### 絶対ピークのクエリ {#query-absolute-peaks}

指定された期間に観測された最大RPSを特定するには:

1. これらのクエリを実行します:

   - APIトラフィックのピーク：自動化、外部ツール、およびWebhookからのピークAPIリクエストを測定します:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))[7d:1m]
     )
     ```

   - Webトラフィックのピーク：ブラウザのユーザーからのピークUIインタラクションを測定します:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController"}[1m]))[7d:1m]
     )
     ```

   - Gitのプルとクローンのピーク：ピークリポジトリのクローンとフェッチ操作を測定します:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Gitプッシュピーク：ピークコードのプッシュ操作を測定します:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

#### 維持されたピークのクエリ {#query-sustained-peaks}

まれなスパイクを除外して、典型的な高負荷レベルを特定するには:

1. これらのクエリを実行します:

   - API維持ピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))[7d:1m]
     )
     ```

   - Web維持ピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController"}[1m]))[7d:1m]
     )
     ```

   - Gitのプルとクローン維持ピーク:

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Gitプッシュ維持ピーク:

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

### トラフィックをリファレンスアーキテクチャにマップ {#map-traffic-to-reference-architectures}

以前に記録した結果を使用して、トラフィックをリファレンスアーキテクチャにマップするには:

1. トラフィックタイプごとに推奨されるリファレンスアーキテクチャを確認するには、[初期サイジングガイドライン](_index.md#initial-sizing-guide)を参照してください。
1. 分析テーブルに記入します。次の表をガイドラインとして使用します:

   | トラフィックタイプ       | ピークRPS | ピーク時の推奨RA     | 維持されたRPS | 維持された推奨RA |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Web                | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Gitのプルとクローン | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Git push（プッシュ）           | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |

1. **Peak Suggested RA**（ピーク時の推奨RA）列のすべてのリファレンスアーキテクチャを比較し、最大のサイズを選択します。**Sustained Suggested RA**（維持された推奨RA）列に対して繰り返します。
1. ベースラインをドキュメント化します:
   - 推奨される最大のピークRA。
   - 推奨される最大の維持されたRA。

### リファレンスアーキテクチャの選択 {#choose-a-reference-architecture}

この時点で、2つの候補リファレンスアーキテクチャサイズがあります:

- 絶対ピークに基づくもの。
- 維持された負荷に基づくもの。

リファレンスアーキテクチャを選択するには:

1. ピークと維持が同じRAを示唆している場合は、そのRAを使用します。
1. ピークが維持よりも大きなRAを示唆している場合。ギャップを計算します。ピークRPSは、維持されたRAの上限の10〜15％以内ですか？

一般的なガイドライン:

- ピークRPSが維持されたRA制限を10〜15％未満で超える場合、リファレンスアーキテクチャにはヘッドルームが組み込まれているため、許容できるリスクを考慮して維持されたRAを検討できます。
- 15％を超えると、ピークベースのRAから開始し、メトリクスがダウングレードをサポートしている場合は、モニタリングして調整します。
  - 例1: ピークは110 RPS、大規模RAは「最大100 RPS」を処理します→10％以上→大規模で十分なはずです（リファレンスアーキテクチャにはヘッドルームが組み込まれています）
  - 例2: ピークは150 RPS、大規模RAは「最大100 RPS」を処理します→50％以上→X-Largeを使用します（最大200 RPS）

40 RPS未満の環境で、高可用性（HA）が要件である場合は、[高可用性セクション](_index.md#high-availability-ha)を参照して、サポートされている削減で60 RPS / 3,000ユーザーアーキテクチャへの切り替えが必要かどうかを特定します。

### 次に進む前に {#before-you-proceed}

このセクションを完了すると、ベースラインリファレンスアーキテクチャサイズが確立されます。これは基盤となりますが、次のセクションでは、特定のワークロードが標準設定を超えてコンポーネントの調整を必要とするかどうかを特定します。

続行する前に、このセクションで収集した詳細をドキュメント化していることを確認してください。次のガイドとして使用できます:

```markdown
Reference architecture assessment summary:

- Selected reference architecture: _____
- Justification based on _____ RPS [absolute/sustained]

| Traffic Type       | Peak RPS | Sustained RPS (95th) |
|:-------------------|:---------|:---------------------|
| API                | ________ | ____________________ |
| Web                | ________ | ____________________ |
| Git pull and clone | ________ | ____________________ |
| Git push           | ________ | ____________________ |

Highest RPS Peak timestamp for workload analysis: _____
```

## コンポーネントの調整の特定 {#identify-component-adjustments}

ワークロード評価では、ベースリファレンスアーキテクチャを超えてコンポーネントの調整を必要とする特定の使用パターンが特定されます。RPSは全体的なサイズを決定しますが、ワークロードパターンは形状を決定します。同じRPSを持つ2つの環境は、リソースのニーズが大幅に異なる可能性があります。

さまざまなワークロードは、GitLabアーキテクチャのさまざまな部分に負荷をかけます:

- 適度なRPSを維持しながら数千ものジョブを処理するCI/CD負荷の高い環境は、SidekiqとGitalyに負荷をかけます。
- 高いRPSを示す広範なAPI自動化を備えた環境ですが、データベースとRailsレイヤーに負荷が集中しています。

### ピーク負荷時の上位エンドポイントの分析 {#analyze-top-endpoints-during-peak-load}

前のセクションのピークタイムスタンプを使用して、最大負荷時にどのエンドポイントが最もトラフィックを受信したかを特定します。

{{< alert type="note" >}}

RPSメトリクスが営業時間外に一貫して高いトラフィック（ピークの50％超）を示している場合、これは典型的なパターンを超えた重い自動化を示唆しています。たとえば、ピークトラフィックが営業時間中に100 RPSに達するが、夜間と週末に50以上のRPSを維持する場合、自動化されたワークロードが大幅に増加していることを示します。[コンポーネントの調整の評価](#determine-component-adjustments)時にこれを考慮してください。

{{< /alert >}}

1. 視覚化を有効にしてこのクエリを実行します（時間経過に伴う分布の場合は棒チャート、一般的な分布の場合は円チャート）:

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. 絶対RPSピーク時の上位エンドポイントの分布の結果を確認します。結果は次のようになる可能性があります:

   - 目に見えるエンドポイントパターンはありません。この場合、以前に選択したリファレンスアーキテクチャに進みます。堅牢なモニタリングを配置して、ワークロードの変更の影響を測定していることを確認してください。
   - Git以外のトラフィックに対する重いAPI使用の大部分。この場合、Webhookとイシュー、グループ、およびプロジェクトAPIコールは、データベース集中型パターンを示しています。
   - GitまたはSidekiq関連のエンドポイントの大部分。この場合、マージリクエストの差分、パイプラインジョブ、ブランチ、コミット、ファイル操作、CI/CDジョブ、セキュリティスキャン、およびインポート操作は、Sidekiq / Gitaly集中型パターンを示します。

1. 調査結果を記録します:

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### コンポーネントの調整の決定 {#determine-component-adjustments}

上記の指標は、追加のワークロードの初期シグナルを提供します。リファレンスアーキテクチャに組み込まれたヘッドルームのため、これらのワークロードは調整なしで処理される場合があります。ただし、強力な指標が存在し、高レベルの自動化が認識されている場合は、次の調整を検討してください。

以前に特定されたワークロードパターンに基づいて、さまざまなコンポーネントをスケールする必要があります:

| ワークロードタイプ              | 適用時期                                                                                                                                                                                | スケールするコンポーネント |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| データベース集中型         | <ul><li>Git以外のトラフィックに対する重いAPI使用（Webhook、イシュー、グループ、プロジェクト）</li><li>既知の[広範な自動化またはインテグレーションワークロード](_index.md#additional-workloads)</li></ul> | <ul><li>Railsリソースの増加</li><li>[データベースのスケール](#database-scaling)</li><ul> |
| Sidekiq / Gitaly集中型\** | <ul><li>重いGit操作、CI/CDジョブ、セキュリティスキャン、インポート操作、およびGitサーバーフック</li><li>既知のCI/CD負荷の高い使用パターン</li></ul>                                      | <ul><li>Sidekiq仕様の増加</li><li>Gitaly垂直方向のスケール</li><li>[データベースのスケール](#database-scaling)</li><li>高度: 特定の[ジョブクラス](../sidekiq/processing_specific_job_classes.md)の構成</li></ul> |

#### スケールのガイドライン {#scaling-guidance}

リソースの調整は、ワークロードの強度と飽和メトリクスに基づいて異なります:

1. 1.25x〜1.5x現在のリソースから開始します。
1. 実装後のモニタリングデータに基づいて洗練します。

クラウドネイティブGitLabをデプロイすることを計画している場合、この評価で特定されたワークロードパターンは、Kubernetes設定にさらに影響を与えます:

- 営業時間外のトラフィックが多い。静止期間中のスケールツーゼロを許可するのではなく、最小ポッド数がベースライン負荷に対して十分であることを確認してください。たとえば、営業時間中に100 RPS、自動化によって引き起こされる夜間に一貫した50 RPSがある場合、最小ポッド数設定は、ベースライン時間外負荷と一致する必要があります。
- 急激なトラフィックスパイク。デフォルトのHPA設定では、十分に高速にスケールできない場合があります。初期ロールアウト中のポッドのスケール動作をモニタリングして、これらの移行中のリクエストキューイングを防ぎます。たとえば、静止時間から稼働時間へのランプアップ、または特定の自動化スパイクによって引き起こされる50〜200 RPSからの急速なスパイク。

##### データベースのスケール {#database-scaling}

データベースのスケール戦略は、ワークロードの特性によって異なり、複数のアプローチが必要になる場合があります:

1. 容量の制約にすぐに対処するための垂直方向のスケール。これは、以下を行います:
   - レプリカがプライマリ負荷を軽減しないため、書き込み負荷の高いワークロードに必要です。
   - 読み取り操作と書き込み操作の両方に対して、即座に容量を増やします。
1. 読み取りレプリカを使用した[データベースのロードバランシング](../postgresql/database_load_balancing.md):
   - 特に読み取り負荷の高いワークロード（85〜95％の読み取り）に役立ちます。
   - 読み取りトラフィックを複数のノードに分散します。
   - 垂直方向のスケールと組み合わせて追加できます。
1. 書き込みパフォーマンスがボトルネックのままである場合は、垂直方向のスケールを続行します。

このPrometheusクエリを使用して、読み取り/書き込みの分布を特定します:

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### 次に進む前に {#before-you-proceed-1}

このセクションを完了すると、ワークロードパターンを特定し、必要なコンポーネントの調整を決定できます。

次に進む前に、完全なワークロード評価を記録します:

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

次のセクションでは、追加のインフラストラクチャの考慮事項が必要になる可能性のある特別なデータ特性を評価します。

## 特別なインフラストラクチャ要件の評価 {#assess-special-infrastructure-requirements}

RPSメトリクスで明らかになるもの以外に、リポジトリの特性とネットワークの使用パターンがGitLabのパフォーマンスに大きな影響を与える可能性があります。

大規模なモノレポ、広範なバイナリファイル、およびネットワーク負荷の高い操作には、標準のサイジングでは考慮されないインフラストラクチャの調整が必要です。

### 大規模なモノレポ {#large-monorepos}

大規模なモノレポ（数ギガバイト以上）は、Git操作の実行方法を根本的に変えます。10 GBのリポジトリの1回のプルは、一般的なリポジトリの数百回のプルよりも多くのリソースを消費します。

これらのリポジトリは、Gitalyだけでなく、ワークロードに応じてRails、Sidekiq、データベースにも影響を与えます。

プロファイリングプロセスは、一般的なサイズを大幅に超えるリポジトリの特定に重点を置いています:

- 中規模のモノレポ: 2 GB～10 GB。これらには、控えめな調整が必要です。
- 大規模なモノレポ：>10 GB。これらには、大幅なインフラストラクチャの変更が必要です。

リポジトリのサイズを特定するには:

1. プロジェクトの[使用量クオータ](../../user/storage_usage_quotas.md#view-storage)に移動します。
1. [**リポジトリ**ストレージタイプ](../../user/project/repository/repository_size.md)を確認します。
1. 2 GBより大きいリポジトリと10 GBより大きいリポジトリを持つプロジェクトの数を計算します。
1. 結果を記録します:

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### モノレポのインフラストラクチャ調整 {#infrastructure-adjustments-for-monorepos}

大規模なリポジトリには、垂直方向のスケーリングと運用上の調整の両方が必要です。これらのリポジトリは、Git操作とCPU使用率からメモリ消費量とネットワーク帯域幅まで、スタック全体のパフォーマンスに影響を与えます。

| シナリオ                 | コンポーネントの調整 |
|:-------------------------|:----------------------|
| いくつかの中規模モノレポ | <ul><li>Gitaly: 1.5倍～2倍の仕様</li><li>Rails: 1.25倍～1.5倍の仕様</li></ul> |
| 大規模なモノレポ          | <ul><li>Gitaly: 2倍～4倍の仕様</li><li>Rails: 1.5倍～2倍の仕様</li><li>専用のGitalyノードにモノレポをシャーディングすることを検討してください</li></ul> |

モノレポ環境向けの追加の最適化戦略は、[モノレポパフォーマンスの改善](../../user/project/repository/monorepos/_index.md)に記載されています。これには、バイナリファイル用のLFSとシャロークローンが含まれます。

### ネットワーク負荷の高いワークロード {#network-heavy-workloads}

ネットワークの飽和は、診断が困難な独自の問題を引き起こします。CPUまたはメモリのボトルネックが特定の操作に影響を与えるのとは異なり、ネットワークの飽和は、すべてのGitLab機能で一見ランダムなタイムアウトを引き起こす可能性があります。

一般的なネットワーク負荷のソース:

- コンテナレジストリの大量使用（大規模なイメージ、頻繁なプル）。
- LFS操作（バイナリファイル、メディア資産）。
- 大規模なCI/CDアーティファクト（ビルド出力、テスト結果）。
- モノレポクローン（特にCI/CDパイプライン内）。

#### ネットワーク使用量の測定 {#measure-network-usage}

潜在的なボトルネックを特定するために、ピーク時のネットワーク消費量を計算します。

1. 次のクエリを実行します:

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. 結果を記録します:

   ```plaintext
   Max outbound traffic: _____ Gbps
   Max inbound traffic: _____ Gbps
   ```

#### ネットワーク容量要件 {#network-capacity-requirements}

以下のしきい値は、おおよそのガイドラインにすぎません。実際のネットワーク帯域幅の保証は、クラウドプロバイダーとVMの種類によって大きく異なります。特定のインスタンスタイプについて、ワークロードパターンに合っていることを確認するために、ネットワーク仕様（ベースラインとバースト制限）を必ず検証してください。

送信トラフィックと受信トラフィックの測定に基づきます:

| ネットワーク負荷 | しきい値 | このしきい値の理由                                                 | 必要なアクション |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| 標準     | 1 Gbps未満   | ほとんどの標準インスタンスのベースライン帯域幅内               | 標準インスタンスで十分 |
| 適度     | 1～3 Gbps  | AWSのベースラインを超える可能性がありますが、GCP/Azureの標準インスタンス内    | <ul><li>AWS: スロットリングをモニタリングし、ネットワーク強化が必要になる場合があります</li><li>GCP/Azure: 通常、標準インスタンスで十分です</li></ul> |
| 高         | 3～10 Gbps | AWSのベースラインを超えています。一部の標準インスタンスの制限に近づいています | <ul><li>AWS: ネットワーク強化されたVMが必要です</li><li>GCP/Azure: インスタンスの帯域幅仕様を確認します</li></ul> |
| 非常に高い    | 10 Gbps超  | ほとんどの標準インスタンス機能を超えています                        | <ul><li>すべてのプロバイダーでネットワーク強化されたVMが必要です</li><li>大規模なアーティファクトの場合は、[オブジェクトプロキシのダウンロード](../object_storage.md#proxy-download)を無効にします</li></ul> |

### 次に進む前に {#before-you-proceed-2}

次に進む前に、完全なデータプロファイリング評価を記録します:

```txt
Data Profile Summary:
- Medium monorepos (2GB-10GB): _____
- Large monorepos (>10GB): _____
- Gitaly adjustments needed: _____
- Rails adjustments needed: _____
- Peak outbound traffic: _____ Gbps
- Peak inbound traffic: _____ Gbps
- Network infrastructure changes: _____
```

## 現在の環境の分析と推奨事項の検証 {#analyze-current-environment-and-validate-recommendations}

既存の環境を理解することで、推奨事項に関する重要なコンテキストが得られます:

- 現在の環境でパフォーマンスの問題なくワークロードを処理できる場合、サイジングの見積もりに関する貴重な検証として役立ちます。
- 逆に、パフォーマンスに問題のある環境では、サイズ不足が永続化しないように慎重な分析が必要です。

### 現在の環境のドキュメント化 {#document-the-current-environment}

包括的な環境データを収集して、現在の状態を確立します:

- アーキテクチャの詳細:
  - タイプ：高可用性（HA）または非高可用性（非HA）。
  - デプロイ方法: LinuxパッケージまたはクラウドプロバイダーネイティブGitLab。
- コンポーネントの仕様:
  - 各コンポーネントのノード数と仕様。
  - カスタム設定または偏差。

### 最も近いリファレンスアーキテクチャの特定 {#identify-nearest-reference-architecture}

1. 現在の環境を[利用可能なリファレンスアーキテクチャ](_index.md)と比較します。以下を検討してください:

   - コンポーネントごとのコンピューティングリソースの合計。
   - ノードの分散とアーキテクチャパターン（HA対非HA）。
   - リファレンスアーキテクチャサイズに対するコンポーネントの仕様。

1. 調査結果を記録します:

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### 現在の環境と推奨アーキテクチャの比較 {#compare-current-environment-to-recommended-architecture}

現在の環境を、前のセクションで開発した推奨されるリファレンスアーキテクチャと比較します。現在の環境が以下の場合:

- パフォーマンスの問題がなく、現在のリソースが推奨されるRAよりも少ない場合:
  - 推奨事項は控えめで、将来のヘッドルームを提供します。
  - 推奨されるRAに進みます。
  - デプロイ後の潜在的な最適化の機会について、モニタリングします。
- パフォーマンスの問題がなく、現在のリソースが推奨されるRAとほぼ同じ場合:
  - サイジング評価の強力な検証。
  - 現在の環境は、推奨されるサイズが適切であることを確認します。
- パフォーマンスの問題がなく、現在のリソースが推奨されるRAよりも多い場合:
  - 現在の環境は、過剰にプロビジョニングされているか、分析が必要な追加リソースの正当な理由がある可能性があります。Rails、Gitaly、データベース、SidekiqのCPU/メモリの[リソース使用率](../monitoring/prometheus/_index.md#sample-prometheus-queries)を確認します。

    低い使用率（40％未満）は、過剰なプロビジョニングを示唆しています。高い使用率は、RPS分析でキャプチャされていない特定のワークロード要件を示している可能性があります。
  - 未発見の要件に合わせて推奨事項を調整する必要があるかどうかを確認します。

現在の環境にパフォーマンスの問題がある場合:

- 現在の仕様を最小ベースラインとしてのみ使用します。以前のセクションからの推奨事項は、現在の仕様を超える必要があります。
- 推奨事項が現在よりも大幅に低い場合は、以下を調査してください:
  - 評価でキャプチャされていないワークロードパターン。
  - ターゲットを絞ったスケーリングが必要なコンポーネント固有のボトルネック。

### 次に進む前に {#before-you-proceed-3}

このセクションを完了すると、現在の環境を分析し、推奨事項と比較します。

次に進む前に、完全な環境比較を記録します:

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

次のセクションでは、サイジングが時間の経過とともに適切であることを保証するために、成長予測を評価します。

## 将来の容量を計画する {#plan-for-future-capacity}

インフラストラクチャの変更には、調達、移行、およびテストにかなりのリードタイムが必要です。成長の見積もりにより、推奨されるアーキテクチャが実装期間中およびそれを超えて実行可能であることが保証されます。

過去の傾向と事業計画を組み合わせることで、最も正確な成長予測が得られます。

### 過去の成長パターンの分析 {#analyze-historical-growth-patterns}

過去の成長パターンは、事業予測よりも将来の軌跡を予測するのに役立ちます:

1. [ベースラインサイズ](#determine-your-baseline-size)の情報を使用して、現在のRPSを6～12か月前と比較します。
1. 成長の加速または減速傾向を特定します。

### 事業計画要素の組み込み {#incorporate-business-planning-factors}

インフラストラクチャのニーズに影響を与える可能性のある事業の変化:

- チームの拡大または統合。
- 新しいプロジェクトの開発。
- 既存のプロジェクトでの開発アクティビティーの増加。

これらの要因（またはその他の組織の変更）が環境への負荷に影響を与え、インフラストラクチャの調整が必要になるかどうかを評価します。関連する変更とその予想されるタイムラインをドキュメント化します。

#### 成長バッファ戦略の決定 {#determine-growth-buffer-strategy}

過去の傾向と事業予測に基づいて、適切な成長対応戦略を選択します:

- 安定した成長または最小限の成長: モニタリングを続けます。リファレンスアーキテクチャには、組み込みのヘッドルームが含まれています。
- 適度な成長: 予測される将来のRPSを処理できるようにサイズ設定されたRAを計画します。
- 予測される大幅な成長: 現在のRPSではなく、予測される将来のRPSに合わせてサイズ設定することを検討してください。

### 次に進む前に {#before-you-proceed-4}

このセクションを完了すると、成長予測がサイジングの決定に組み込まれます。

完全な成長分析を記録します:

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

次のセクションでは、すべての調査結果を最終的なアーキテクチャの推奨事項にまとめます。

## 調査結果のコンパイル {#compile-findings}

最適なリファレンスアーキテクチャと必要な調整を決定するために、これまでのすべてのセクションの調査結果をコンパイルします。

### 最終的なアーキテクチャの決定 {#determine-final-architecture}

各セクションの主要な出力を収集して、サイジングの決定を形成します:

1. [RPS分析](#determine-your-baseline-size)に基づいて特定されたリファレンスアーキテクチャから始めます。
1. [ワークロードパターン](#identify-component-adjustments)と[データ特性](#assess-special-infrastructure-requirements)に基づいて、必要なコンポーネントの調整を適用します。パターンが特定されない場合、または標準設定で十分な場合は、このステップをスキップします。
1. [現在の状態](#analyze-current-environment-and-validate-recommendations)に対して検証します。現在の環境が良好に機能しているが、推奨事項を超えている場合は、その理由をドキュメント化してください。パフォーマンスに問題がある場合は、推奨事項が現在の仕様を超えていることを確認してください。
1. [将来の容量のための計画における成長](#plan-for-future-capacity)に対応します。現在のRAで十分かどうか、または予測される成長に合わせてサイズ設定が必要かどうかを判断します。

### 最終的な推奨事項のドキュメント化 {#document-final-recommendation}

包括的な評価に基づいて、完全なアーキテクチャの推奨事項を記録します:

```plaintext
Final Architecture Recommendation
==================================

- Selected RA: [Size] based on [Absolute/Sustained] Peak RPS of [value]
- Component adjustments required:
  - [ ] No adjustments needed - standard RA configuration sufficient
  - [ ] Adjustments required:
      - Rails: _____
      - Sidekiq: _____
      - Database: _____
      - Gitaly: _____
      - Network considerations: □ Standard instances □ Network-optimized instances
- Selected RA is aligned with existing environment: [Yes/No/Not applicable]
- Growth accommodation: [Current RA sufficient / Sized up for growth]

Assessment Summary:
├── RPS Analysis
│   ├── Absolute Peak RPS: _____ → Baseline RA: _____
│   └── Sustained Peak RPS: _____ → Sustained RA: _____
├── Workload Type
│   └── Type: [ ] Database-Intensive [ ] Sidekiq-Intensive [ ] None
├── Data Profile
│   ├── Large repos (>2GB): _____ | Monorepos (>10GB): _____
│   └── Network peak: _____ Gbps
├── Current State
│   ├── Nearest RA: _____
|   └── Discrepancies and customizations: _____
└── Growth
    ├── Growth projection: _____
    └── Growth buffer strategy: _____
```

すべてのセクションを完了すると、サイジング評価は完了です。最終的な推奨事項には、以下が含まれます:

- 基本となるリファレンスアーキテクチャのサイズ。
- コンポーネント固有の調整
- 成長対応戦略。

ワークロードパターンが進化するにつれて、仮定を検証し、インフラストラクチャを調整するには、定期的なモニタリングが不可欠です。
