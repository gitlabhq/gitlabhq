---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: リファレンスアーキテクチャのサイズとコンポーネント固有の調整を定義するためのガイドライン。
title: リファレンスアーキテクチャのサイズを評価する
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

## はじめる前 {#before-you-begin}

この情報は、複雑な環境で適切なリファレンスアーキテクチャを選択する場合に使用できます。このレベルの詳細は必要ない場合もあります。[より複雑でない環境向けの情報](_index.md)を使用して、ご自身の環境の規模を評価できます。

> [!note]専門家によるガイダンスが必要ですか？アーキテクチャのサイズを正しく設定することは、最適なパフォーマンスのために重要です。当社の[プロフェッショナルサービス](https://about.gitlab.com/professional-services/)チームが、お客様固有のアーキテクチャを評価し、パフォーマンス、安定性、可用性の最適化に関するカスタマイズされた推奨事項を提供します。

このドキュメントに従うには、GitLabインスタンスでPrometheusモニタリングがデプロイされている必要があります。Prometheusは、適切なサイジング評価に必要な正確なメトリクスを提供します。

Prometheusをまだ設定していない場合:

1. [Prometheus](../monitoring/prometheus/_index.md)でモニタリングを設定します。リファレンスアーキテクチャのドキュメントには、環境サイズごとのPrometheus設定の詳細が記載されています。クラウドネイティブGitLabの場合、[`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) Helmチャートを使用して、メトリクスのスクレイピングを設定できます。
1. 7〜14日間データを収集して、意味のあるデータパターンを収集します。
1. この情報の残りの部分をお読みください。

Prometheusモニタリングを設定できない場合:

- サイジングを予測するために、最も近いリファレンスアーキテクチャに対する[現在の環境](#analyze-current-environment-and-validate-recommendations)仕様を比較します。
- GitLabSOSまたはKubeSOSログを使用してリファレンスアーキテクチャのサイズを評価するには、[GitLab RPS Analyzer](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/gitlab-rps-analyzer#gitlab-rps-analyzer)を使用します。ただし、これはメトリクスよりも信頼性が低いことに注意してください。

他のプラットフォームから移行する場合、既存のGitLabメトリクスがないと、次のPromQLクエリを適用できません。ただし、一般的な評価開発手法は引き続き有効です:

1. 予想されるワークロードに基づいて、最も近いリファレンスアーキテクチャを見積もります。
1. 予想される追加のワークロードを特定します。
1. 大規模なリポジトリの数を評価します
1. 成長予測を組み込みます。
1. [適切なバッファ](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down)を備えたリファレンスアーキテクチャを選択します。

### PromQLクエリの実行 {#running-promql-queries}

PromQLクエリの実行は、使用するモニタリングソリューションによって異なります。[Prometheus](../monitoring/prometheus/_index.md#how-prometheus-works)モニタリングのドキュメントに記載されているように、Prometheusに直接接続するか、Grafanaのようなダッシュボードツールを使用することで、モニタリングデータにアクセスできます。

## ベースラインサイズを決定する {#determine-your-baseline-size}

1秒あたりのリクエスト数（RPS）は、GitLabインフラストラクチャのサイズを決定するための主要なメトリクスです。さまざまなトラフィックタイプ（API、Web、Git操作）は、さまざまなコンポーネントに負荷をかけるため、それぞれを個別に分析して、真の容量要件を見つけます。

### トラフィックのピークメトリクスを抽出する {#extract-peak-traffic-metrics}

これらのクエリを実行して、最大の負荷を理解します。これらのクエリは、以下を示しています:

- 絶対ピーク。これは、これまでに見られた最高のスパイクです。絶対ピークは、最悪のシナリオを示しています。
- 持続的なピーク。これは95パーセンタイルであり、一般的な「ビジー」レベルと見なされます。持続的なピークは、一般的な高負荷期間を示しています。

絶対ピークがまれな異常である場合は、持続的な負荷に対するサイジングが適切な場合があります。

保持に基づいてクエリの時間範囲を調整します（より長い履歴が利用可能な場合は、`[7d]`を`[30d]`に変更します）。

> [!note]アクティビティーの高い環境では、`max_over_time`または`quantile_over_time`クエリがタイムアウトする場合があります。これが発生した場合は、外部集計関数を削除し、グラフで内部クエリを視覚化します。たとえば、APIトラフィックのピークには、次を使用します:
>
> ```prometheus
> sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))
> ```
>
> 次に、モニタリング期間中にグラフ化された結果からピーク値を視覚的に特定します。

#### 絶対ピークのクエリ {#query-absolute-peaks}

指定された期間に観測された最大RPSを特定するには:

1. これらのクエリを実行します:

   - オートメーション、外部ツール、およびWebhookからのピークAPIリクエストを測定するためのAPIトラフィックピーク:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - ブラウザでのユーザーからのピークUIインタラクションを測定するためのWebトラフィックピーク:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - ピークリポジトリの複製およびフェッチ操作を測定するためのGitプルとクローンピーク:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - ピークコードプッシュ操作を測定するためのGitプッシュピーク:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

#### 持続的なピークのクエリ {#query-sustained-peaks}

まれなスパイクを除外して、一般的な高負荷レベルを特定するには:

1. これらのクエリを実行します:

   - API持続的なピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - Web持続的なピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Gitプルとクローン持続的なピーク:

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Gitプッシュ持続的なピーク:

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

### トラフィックをリファレンスアーキテクチャにマップする {#map-traffic-to-reference-architectures}

以前に記録した結果を使用して、トラフィックをリファレンスアーキテクチャにマップするには:

1. 各トラフィックタイプが推奨するリファレンスアーキテクチャを確認するには、[利用可能なリファレンスアーキテクチャ](_index.md#available-reference-architectures)を参照してください。
1. 分析テーブルに入力します。次の表をガイドラインとして使用します:

   | トラフィックタイプ       | ピークRPS | ピーク推奨RA     | 持続的なRPS | 持続的な推奨RA |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Web                | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Gitプルとクローン | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |
   | Gitプッシュ           | \________ | \_\_\_\_\_（最大___ RPS） | \_____________ | \_\_\_\_\_（最大____ RPS） |

1. **Peak Suggested RA**列のすべてのリファレンスアーキテクチャを比較し、最大のサイズを選択します。**Sustained Suggested RA**列に対して繰り返します。
1. ベースラインをドキュメント化します:
   - 推奨される最大のピークRA。
   - 推奨される最大の持続的なRA。

### リファレンスアーキテクチャを選択する {#choose-a-reference-architecture}

この時点で、2つの候補となるリファレンスアーキテクチャサイズがあります:

- 絶対ピークに基づくもの。
- 持続的な負荷に基づくもの。

リファレンスアーキテクチャを選択するには:

1. ピークと持続が同じRAを示唆している場合は、そのRAを使用します。
1. ピークが持続よりも大きなRAを示唆している場合。ギャップを計算します。ピークRPSは、持続的なRAの上限の10〜15％以内ですか？

一般的なガイドライン:

- ピークRPSが持続的なRA制限を10〜15％未満超過している場合、リファレンスアーキテクチャには組み込みのヘッドルームがあるため、許容可能なリスクで持続的なRAを検討できます。
- 15％を超える場合は、ピークベースのRAから開始し、メトリクスがダウンサイジングをサポートしている場合は、モニタリングして調整します。
  - 例1: ピークは110 RPS、大規模なRAは「最大100 RPS」を処理→10％超過→大規模で十分なはずです（リファレンスアーキテクチャには組み込みのヘッドルームがあります）
  - 例2: ピークは150 RPS、大規模なRAは「最大100 RPS」を処理→50％超過→X大規模を使用（最大200 RPS）
  - 例3: ピークは100 RPS（大規模/100 RPS）ですが、持続は50 RPS（中規模/60 RPS）です。Raw RPSグラフは、負荷がほとんどの場合50 RPS未満であるのに対し、オートメーションスパイクがピークを引き起こすことを示しています。ユーザーは、大規模で保守的に開始してからスケールダウンするか、[ワークロード固有のスケーリング](#identify-component-adjustments)（リスクが高い）で中規模を開始するかどうかを評価します。

40 RPS未満の環境で、高可用性（HA）が要件となる場合は、[高可用性セクション](_index.md#high-availability-ha)を参照して、サポートされている削減で60 RPS / 3,000ユーザーアーキテクチャに切り替える必要があるかどうかを確認します。

### 続行する前に {#before-you-proceed}

このセクションを完了すると、ベースラインリファレンスアーキテクチャのサイズが確立されます。これは基盤となりますが、次のセクションでは、特定のワークロードで標準設定を超えるコンポーネント調整が必要かどうかを特定します。

続行する前に、このセクションで収集した詳細をドキュメント化していることを確認してください。次のものをガイドラインとして使用できます:

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

## RPS構成とワークロードパターンの理解 {#understanding-rps-composition-and-workload-patterns}

合計RPSは主要なサイジングメトリクスですが、ワークロード構成はコンポーネントリソース要件に大きな影響を与えます。さまざまなリクエストタイプは、さまざまなコンポーネントにさまざまな強度で負荷をかけます。

### リクエストタイプ別のRPSの内訳 {#rps-breakdown-by-request-type}

リファレンスアーキテクチャRPSターゲットは、本番データに基づいて一般的なワークロード構成を前提としています:

- **APIリクエスト**（総RPSの約80％）- オートメーション、インテグレーション、Webhook、API駆動型ツール
- **Webリクエスト**（総RPSの約10％）- UI操作、ページナビゲーション、ユーザー駆動型アクション
- **Git操作**（総RPSの約10％）- リポジトリのクローンとプルが中心で、プッシュレートは比較的低い

**非典型的な構成** \- いずれかのリクエストタイプが一般的な比率を大幅に上回る環境（ターゲットRPS範囲内であっても、コンポーネント固有の調整が必要になる場合があります）

### 非典型的なワークロードパターンの識別 {#identifying-atypical-workload-patterns}

[ピークトラフィックメトリクスの抽出](#extract-peak-traffic-metrics)からのRPS抽出クエリを使用して、ワークロード構成を理解します。ディストリビューションを一般的なパターンと比較します:

**APIの比重が高いワークロード**（APIが総RPSの90%超）: 

- ヘビーな自動化、広範なインテグレーション、またはAPI駆動型ツール
- 主な影響: Rails（Webサービス）、PostgreSQL、Gitaly
- 次の点を検討してください: Webサービス/Rails容量の増加、データベース読み取りレプリカ

**Webの比重が高いワークロード**（Webが総RPSの20%超）: 

- 広範なUIインタラクションを備えた大規模なアクティブユーザーベース
- 主な影響: Rails（Webサービス）、PostgreSQL
- 次の点を検討してください: Webサービス容量の増加、データベースの最適化

**Git操作の比重が高いワークロード**（Gitが総RPSの15％超、またはプルレートが規模の割に典型的な水準より明らかに高い）:

- 大規模チームによる頻繁なプル、モノレポパターン、またはリポジトリのクローンを伴うCI/CD中心のワークフロー
- 主な影響: Gitaly、ネットワーク帯域幅
- 次の点を検討してください: Gitaly垂直スケーリング、リポジトリの最適化、ネットワーク強化VM

### 評価アプローチ {#assessment-approach}

1. 提供されたPromQLクエリを使用して、RPSの内訳を抽出します
1. リクエストタイプごとに合計の割合を計算します
1. いずれかのタイプが一般的な割合を大幅に超えているかどうかを特定します
1. 非定型の場合は、スケーリングガイダンスについて[コンポーネント調整の識別](#identify-component-adjustments)を参照してください

> [!note] 小さな変動（どのカテゴリでもRPSの差が5〜10）では、アーキテクチャの変更は必要ありません。RPSの比較のみに基づいて決定を下すのではなく、本番環境からの実際のコンポーネント飽和メトリクス（CPU、メモリ、キューの深さ）をモニタリングします。70％未満の持続的な使用率のコンポーネントは、RPSのわずかな変動に関係なく、一般的に十分な容量を備えています。

## コンポーネント調整の識別 {#identify-component-adjustments}

ワークロード評価では、ベースリファレンスアーキテクチャを超えるコンポーネント調整が必要な特定の使用パターンが識別されます。RPSは全体的なサイズを決定しますが、ワークロードパターンは形状を決定します。同じRPSの2つの環境では、リソースのニーズが大きく異なる場合があります。

さまざまなワークロードは、GitLabアーキテクチャのさまざまな部分に負荷をかけます:

- 数千のジョブを処理しながら、適度なRPSストレスを維持するCI/CDヘビーな環境は、SidekiqとGitalyに負荷をかけます。
- APIの自動化が広範囲に及ぶ環境では、RPSが高くても、負荷がデータベースとRailsのレイヤーに集中します。

### ピーク負荷時の上位エンドポイントを分析します。 {#analyze-top-endpoints-during-peak-load}

前のセクションのピークタイムスタンプを使用して、最大負荷時にどのエンドポイントが最もトラフィックを受信したかを特定します。

> [!note] RPSメトリクスが営業時間外に一貫して高いトラフィック（ピークの50％超）を示す場合、これは典型的なパターンを超えた大規模な自動化を示唆しています。たとえば、営業時間中に100 RPSに達するピークトラフィックが、夜間や週末に50 RPS以上を維持する場合、大幅な自動ワークロードを示します。これは、[コンポーネントの調整を評価する](#determine-component-adjustments)際に考慮してください。

1. このクエリを、可視化を有効にして実行します（時間の経過に伴う分布の場合は棒チャート、一般的な分布の場合は円チャート）:

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. 絶対RPSピーク時の上位エンドポイントの分布の結果を確認します。結果には、次のものがあるかもしれません:

   - エンドポイントパターンが表示されない。この場合は、以前に選択したリファレンスアーキテクチャで続行します。あらゆるワークロードの変更の影響を測定するために、堅牢なモニタリングが実施されていることを確認してください。
   - Gitトラフィック以外の大量のAPI使用。この場合、Webhookとイシュー、グループ、プロジェクトのAPIコールは、データベース集約型のパターンを示します。
   - GitまたはSidekiq関連のエンドポイントの大部分。この場合、マージリクエストの差分、パイプラインジョブ、ブランチ、コミット、ファイル操作、CI/CDジョブ、セキュリティスキャン、およびインポート操作は、Sidekiq/Gitaly集約型のパターンを示します。

1. 調査結果を記録します:

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### コンポーネントの調整を決定します。 {#determine-component-adjustments}

上記の指標は、追加のワークロードの最初の兆候を示しています。リファレンスアーキテクチャにはヘッドルームが組み込まれているため、これらのワークロードは調整なしで処理される場合があります。ただし、強力な指標が存在し、高度な自動化が認識されている場合は、次の調整を検討してください。

以前に特定したワークロードパターンに基づいて、さまざまなコンポーネントでスケールが必要です:

| ワークロードの種類              | 適用時期                                                                                                                                                                                | スケールするコンポーネント |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| データベース集中型         | <ul><li>Gitトラフィック以外の大量のAPI使用（Webhook、イシュー、グループ、およびプロジェクト）</li><li>既知の[広範な自動化またはインテグレーションワークロード](_index.md#additional-workloads)</li></ul> | <ul><li>Railsリソースを増やします</li><li>[データベースのスケール](#database-scaling)</li></ul> |
| Sidekiq/Gitaly集中型\** | <ul><li>大量のGit操作、CI/CDジョブ、セキュリティスキャン、インポート操作、およびGitサーバーフック</li><li>既知のCI/CD集中型の使用パターン</li></ul>                                      | <ul><li>Sidekiq仕様を増やします</li><li>Gitalyの垂直方向のスケール</li><li>[データベースのスケール](#database-scaling)</li><li>高度: 特定の[ジョブクラス](../sidekiq/processing_specific_job_classes.md)を構成します</li></ul> |

#### スケールのガイダンス {#scaling-guidance}

リソースの調整は、ワークロードの強度と飽和メトリクスに基づいて異なります:

1. まず、現在のリソースの1.25倍から1.5倍にします。
1. 実装後のモニタリングデータに基づいて調整します。

クラウドネイティブGitLabをデプロイすることを計画している場合、この評価で特定されたワークロードパターンは、Kubernetes設定にさらに影響を与えます:

- 営業時間外のトラフィックが多い。静止期間中にスケールツーゼロを許可するのではなく、最小ポッド数がベースラインロードに十分であることを確認してください。たとえば、営業時間中に100 RPS、自動化によって発生する夜間に一貫して50 RPSがある場合、最小ポッド数設定は、営業時間外のベースラインロードに合わせる必要があります。
- トラフィックの急増。デフォルトのHPA設定では、スケールが十分に速くない場合があります。これらの移行中にリクエストのキューイングを防ぐために、最初のロールアウト中にポッドのスケール動作をモニタリングします。たとえば、静止時間から稼働時間への増加、または特定の自動化スパイクによって引き起こされる50から200 RPSへの急激なスパイク。

##### データベースのスケール {#database-scaling}

データベースのスケール戦略は、ワークロードの特性によって異なり、複数のアプローチが必要になる場合があります:

1. 即時の容量制約に対処するための垂直方向のスケール。以下があります:
   - レプリカはプライマリロードを削減しないため、書き込み負荷の高いワークロードに必要です。
   - 読み取り操作と書き込み操作の両方に対して、即時の容量増加を提供します。
1. 読み取りレプリカを使用した[データベースロードバランシング](../postgresql/database_load_balancing.md)（推奨）。以下があります:
   - 特に読み取り負荷の高いワークロード（85〜95％の読み取り）に役立ちます。
   - 複数のノード間で読み取りトラフィックを分散します。
   - 垂直方向のスケールと組み合わせて追加できます。
1. 書き込みのパフォーマンスがボトルネックのままである場合は、垂直方向のスケールを続行します。

このPrometheusクエリを使用して、読み取り/書き込みの分布を特定します:

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### 続行する前に {#before-you-proceed-1}

このセクションを完了すると、ワークロードパターンを特定し、必要なコンポーネントの調整を決定しました。

次に進む前に、完全なワークロード評価を記録してください:

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

次のセクションでは、追加のインフラストラクチャの検討が必要になる可能性のある特別なデータ特性を評価します。

## 特別なインフラストラクチャ要件を評価する {#assess-special-infrastructure-requirements}

リポジトリの特性とネットワークの使用パターンは、RPSメトリクスが明らかにするものを超えて、GitLabのパフォーマンスに大きな影響を与える可能性があります。

大規模なモノレポ、広範なバイナリファイル、およびネットワーク集約型の操作には、標準のサイジングでは考慮されないインフラストラクチャの調整が必要です。

### 大規模なモノレポ {#large-monorepos}

大規模なモノレポ（数ギガバイト以上）は、Git操作の実行方法を根本的に変えます。10 GBのリポジトリの単一のクローンは、一般的なリポジトリの数百のクローンよりも多くのリソースを消費します。

これらのリポジトリは、Gitalyだけでなく、ワークロードに応じてRails、Sidekiq、およびデータベースにも影響を与えます。

プロファイリングプロセスは、典型的なサイズを大幅に超えるリポジトリの特定に焦点を当てています:

- 中規模のモノレポ: 2 GB〜10 GB。これらには、適度な調整が必要です。
- 大規模なモノレポ: 10 GB超。これらには、大幅なインフラストラクチャの変更が必要です。

リポジトリのサイズを特定するには:

1. プロジェクトの[使用量クォータ](../../user/storage_usage_quotas.md#view-storage)に移動します。
1. [**リポジトリ**ストレージタイプ](../../user/project/repository/repository_size.md)を確認します。
1. 2 GBを超えるリポジトリと10 GBを超えるリポジトリを持つプロジェクトの数を計算します。
1. 結果を記録します:

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### モノレポのインフラストラクチャ調整 {#infrastructure-adjustments-for-monorepos}

大規模なリポジトリには、垂直方向のスケールと運用上の調整の両方が必要です。これらのリポジトリは、Git操作とCPU使用率からメモリー消費量、ネットワーク帯域幅まで、スタック全体のパフォーマンスに影響を与えます。

| シナリオ                 | コンポーネントの調整 |
|:-------------------------|:----------------------|
| 複数の中規模モノレポ | <ul><li>Gitaly: 1.5倍〜2倍の仕様</li><li>Rails: 1.25倍〜1.5倍の仕様</li></ul> |
| 大規模なモノレポ          | <ul><li>Gitaly: 2倍〜4倍の仕様</li><li>Rails: 1.5倍〜2倍の仕様</li><li>モノレポを専用のGitalyノードにシャーディングすることを検討してください</li></ul> |

モノレポ環境の追加の最適化戦略は、[モノレポのパフォーマンスの向上](../../user/project/repository/monorepos/_index.md)に記載されています。これには、バイナリファイル用のGit LFSとシャロークローンが含まれます。

### ネットワーク負荷の高いワークロード {#network-heavy-workloads}

ネットワークの飽和は、診断が難しいことが多い独自の問題を引き起こします。特定の操作に影響を与えるCPUまたはメモリーのボトルネックとは異なり、ネットワークの飽和により、すべてのGitLab機能で一見ランダムなタイムアウトが発生する可能性があります。

一般的なネットワークロードソース:

- コンテナレジストリの使用量が多い（大きなイメージ、頻繁なプル）。
- LFS操作（バイナリファイル、メディアアセット）。
- 大規模なCI/CDアーティファクト（ビルド出力、テスト結果）。
- モノレポクローン（特にCI/CDパイプライン内）。

#### ネットワーク使用量を測定する {#measure-network-usage}

潜在的なボトルネックを特定するために、ピーク時のネットワーク消費量とベースラインのネットワーク消費量を計算します。発生頻度の低いスパイク（バースト容量で処理）と、持続的な高トラフィック（ネットワーク強化されたVMが必要）を区別するために、両方を評価します。

1. 次のクエリを実行します:

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. 観測期間全体で観測されたピークスパイクと典型的なベースラインの両方を記録します:

   ```plaintext
   Peak outbound traffic: _____ Gbps (baseline: _____ Gbps)
   Peak inbound traffic: _____ Gbps (baseline: _____ Gbps)
   ```

#### ネットワーク容量の要件 {#network-capacity-requirements}

以下のしきい値は、おおよそのガイドラインにすぎません。実際のネットワーク帯域幅の保証は、クラウドプロバイダーとVMタイプによって大きく異なります。特定のインスタンスタイプのネットワーク仕様（ベースラインとバースト制限）を常に検証して、それらがワークロードパターンと一致していることを確認してください。

送信トラフィックと受信トラフィックの測定値に基づいて:

| ネットワークロード | しきい値 | このしきい値の理由                                                 | 必要なアクション |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| 標準     | < 1 Gbps   | ほとんどの標準インスタンスのベースライン帯域幅内               | 標準インスタンスで十分 |
| 中程度     | 1〜3 Gbps  | AWSのベースラインを超える可能性がありますが、GCP/Azureの標準インスタンス内です    | <ul><li>AWS: スロットリングのモニタリング、ネットワーク強化が必要になる場合があります</li><li>GCP/Azure: 標準インスタンスで通常は十分</li></ul> |
| 高         | 3〜10 Gbps | AWSのベースラインを超えています。一部の標準インスタンスの制限に近づきます | <ul><li>AWS: ネットワーク強化されたVMが必要です</li><li>GCP/Azure: インスタンス帯域幅仕様を確認してください</li></ul> |
| 非常に高い    | > 10 Gbps  | ほとんどの標準インスタンスの機能を超えています                        | <ul><li>すべてのプロバイダーでネットワーク強化されたVMが必要です</li><li>大きなアーティファクトの場合は、[オブジェクトプロキシダウンロード](../object_storage.md#proxy-download)を無効にします</li></ul> |

### 続行する前に {#before-you-proceed-2}

次に進む前に、完全なデータプロファイリング評価を記録してください:

```txt
Data Profile Summary:
- Medium monorepos (2GB-10GB): _____
- Large monorepos (>10GB): _____
- Gitaly adjustments needed: _____
- Rails adjustments needed: _____
- Peak outbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Peak inbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Network infrastructure changes: _____
```

## 現在の環境を分析し、推奨事項を検証する {#analyze-current-environment-and-validate-recommendations}

既存の環境を理解することは、推奨事項にとって重要なコンテキストを提供します:

- 現在の環境でパフォーマンスの問題なくワークロードが処理される場合、サイジングの推定に役立つ検証として機能します。
- 逆に、パフォーマンスに問題がある環境では、サイズ不足を永続化しないように慎重な分析が必要です。

### 現在の環境を文書化する {#document-the-current-environment}

包括的な環境データを収集して、現在の状態を確立します:

- アーキテクチャの詳細:
  - タイプ: 高可用性（HA）または非高可用性（非HA）。
  - デプロイ方法: LinuxパッケージまたはクラウドネイティブGitLab。
- コンポーネント仕様:
  - 各コンポーネントのノード数と仕様。
  - カスタム設定または偏差。

### 最も近いリファレンスアーキテクチャを特定する {#identify-the-nearest-reference-architecture}

1. 現在の環境を[使用可能なリファレンスアーキテクチャ](_index.md)と比較します。以下を検討してください:

   - コンポーネントごとのコンピューティングリソースの合計。
   - ノードの分散とアーキテクチャパターン（HAと非HA）。
   - リファレンスアーキテクチャサイズに対するコンポーネント仕様。

1. 調査結果を記録します:

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### 推奨アーキテクチャと現在の環境を比較する {#compare-current-environment-to-recommended-architecture}

以前のセクションで開発した推奨リファレンスアーキテクチャに対して、現在の環境を比較します。現在の環境の場合:

- パフォーマンスの問題がなく、現在のリソースが推奨RAよりも少ない: 
  - 推奨事項は控えめで、将来のヘッドルームを提供します。
  - 推奨されるRAに進みます。
  - 潜在的な最適化の機会について、実装後のモニタリングを行います。
- パフォーマンスの問題がなく、現在のリソースが推奨RAとほぼ同等: 
  - サイジング評価の強力な検証。
  - 現在の環境は、推奨されるサイズが適切であることを確認します。
- パフォーマンスの問題がなく、現在のリソースが推奨RAより多い: 
  - 現在の環境は過剰にプロビジョニングされているか、分析が必要な追加リソースの正当な理由がある可能性があります。Rails、Gitaly、データベース、およびSidekiqでCPU/メモリーの[リソース使用率](../monitoring/prometheus/_index.md#sample-prometheus-queries)を確認します。

    低い使用率（40％未満）は、過剰なプロビジョニングを示唆しています。高い使用率は、RPS分析でキャプチャされていない特定のワークロード要件を示している可能性があります。
  - 推奨事項で、未発見の要件に合わせて調整する必要があるかどうかを確認します。

現在の環境でパフォーマンスの問題が発生した場合:

- 現在の仕様を最小ベースラインとしてのみ使用します。以前のセクションからの推奨事項は、現在の仕様を超える必要があります。
- 推奨事項が現在よりも大幅に低い場合は、調査してください:
  - 評価でキャプチャされていないワークロードパターン。
  - ターゲットを絞ったスケールが必要なコンポーネント固有のボトルネック。

### 続行する前に {#before-you-proceed-3}

このセクションを完了すると、現在の環境を分析し、推奨事項と比較しました。

次に進む前に、完全な環境の比較を記録します:

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

次のセクションでは、仕様が時間の経過とともに適切であることを保証するために、成長予測を評価します。

## 将来のキャパシティを計画する {#plan-for-future-capacity}

インフラストラクチャの変更には、調達、移行、テストにかなりのリードタイムが必要です。成長の推定により、推奨されるアーキテクチャが実装期間全体を通して、その後も実行可能であることが保証されます。

過去の傾向と事業計画を組み合わせることで、最も正確な成長予測が得られます。

### 過去の成長パターンを分析する {#analyze-historical-growth-patterns}

過去の成長パターンは、事業予測よりも将来の軌道を予測するのに役立ちます:

1. [ベースラインサイズ](#determine-your-baseline-size)の情報を使用して、現在のRPSを6～12か月前と比較します。
1. 成長の加速または減速の傾向を特定します。

### 事業計画要素を組み込む {#incorporate-business-planning-factors}

インフラストラクチャのニーズに影響を与えることが予想される事業の変化:

- チームの拡大または統合。
- 新しいプロジェクトの開発。
- 既存のプロジェクトでの開発アクティビティーの増加。

これらの要因（またはその他の組織的な変更）のいずれかが環境への負荷に影響を与え、インフラストラクチャの調整が必要になるかどうかを評価します。関連する変更とその予想されるタイムラインをドキュメント化します。

#### 成長バッファ戦略を決定する {#determine-growth-buffer-strategy}

過去の傾向と事業予測に基づいて、適切な成長対応戦略を選択します:

- 安定した成長または最小限の成長: モニタリングを継続します。リファレンスアーキテクチャには、組み込みのヘッドルームが含まれています。
- 適度な成長: t
- 大幅な成長が予想される場合: 現在のRPSではなく、予測される将来のRPSに合わせてサイズを検討してください。

### 続行する前に {#before-you-proceed-4}

このセクションを完了すると、成長予測がサイズ決定に組み込まれます。

成長分析の全体像を記録します:

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

次のセクションでは、すべての調査結果をまとめて、最終的なアーキテクチャの推奨事項を作成します。

## 調査結果のまとめ {#compile-findings}

これまでのすべてのセクションから調査結果をまとめ、最適なリファレンスアーキテクチャと必要な調整を決定します。

### 最終的なアーキテクチャの決定 {#determine-final-architecture}

各セクションのキーとなる出力を収集し、サイズ決定を行います:

1. [RPS分析](#determine-your-baseline-size)に基づいて特定されたリファレンスアーキテクチャから開始します。
1. [ワークロードパターン](#identify-component-adjustments)と[データ特性](#assess-special-infrastructure-requirements)に基づいて、必要なコンポーネントの調整を適用します。パターンが特定されない場合、または標準の設定で十分な場合は、この手順をスキップしてください。
1. [現在の状態](#analyze-current-environment-and-validate-recommendations)に対して検証します。現在の環境が適切に機能しているものの、推奨事項を上回る場合は、その理由を文書化してください。パフォーマンスに問題がある場合は、推奨事項が現在の仕様を上回るようにしてください。
1. [将来の容量計画における成長](#plan-for-future-capacity)に対応します。現在のリファレンスアーキテクチャで十分か、予測される成長に合わせてサイズを決定する必要があるかを判断します。

### 最終的な推奨事項のドキュメント {#document-final-recommendation}

包括的な評価に基づいて、アーキテクチャの推奨事項の全体像を記録します:

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
│   └── Network: Peak _____ Gbps | Baseline _____ Gbps
├── Current State
│   ├── Nearest RA: _____
|   └── Discrepancies and customizations: _____
└── Growth
    ├── Growth projection: _____
    └── Growth buffer strategy: _____
```

すべてのセクションを完了すると、サイズの評価は完了です。最終的な推奨事項には、次のものが含まれます:

- ベースとなるリファレンスアーキテクチャのサイズ。
- コンポーネント固有の調整
- 成長への対応戦略。

ワークロードパターンが進化するにつれて、仮定を検証し、インフラストラクチャを調整するには、定期的なモニタリングが不可欠です。
