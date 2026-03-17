---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: リファレンスアーキテクチャのサイズとコンポーネント固有の調整を定義するためのガイド。
title: リファレンスアーキテクチャのサイズを評価する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

適切なリファレンスアーキテクチャを選択するには、リファレンスアーキテクチャに基づいてGitLab環境を評価およびサイジングするための体系的なアプローチを使用する必要があります。

適切なリファレンスアーキテクチャと必要なコンポーネント固有の調整を判断するために、次の情報が分析に役立ちます:

- 1秒あたりのリクエスト数（RPS）のパターン。
- ワークロードの特性。
- リソースの飽和。

## はじめる前 {#before-you-begin}

この情報は、複雑な環境で適切なリファレンスアーキテクチャを選択する場合に使用できます。ここまで詳細な情報が必要とは限りません。[より複雑でない環境向けの情報](_index.md)を使用して環境のサイズを評価することもできます。

> [!note]
> 専門家によるガイダンスが必要ですか？アーキテクチャを適切にサイジングすることは、最適なパフォーマンスを得るうえで非常に重要です。当社の[プロフェッショナルサービス](https://about.gitlab.com/professional-services/)チームが、お客様固有のアーキテクチャを評価し、パフォーマンス、安定性、可用性の最適化に向けてカスタマイズされた推奨事項を提供します。

このドキュメントに従うには、GitLabインスタンスでPrometheusモニタリングがデプロイされている必要があります。Prometheusは、適切なサイジング評価に必要とされる正確なメトリクスを提供します。

Prometheusをまだ設定していない場合:

1. [Prometheus](../monitoring/prometheus/_index.md)によるモニタリングを設定します。リファレンスアーキテクチャのドキュメントには、環境サイズごとのPrometheus設定の詳細が記載されています。クラウドネイティブGitLabの場合、[`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) Helmチャートを使用して、メトリクスのスクレイピングを設定できます。
1. 意味のあるデータパターンを収集するには、7〜14日間データを収集します。
1. この後の情報をお読みください。

Prometheusモニタリングを設定できない場合:

- [現在の環境](#analyze-current-environment-and-validate-recommendations)仕様を最も近いリファレンスアーキテクチャと比較し、サイジングを推定します。
- GitLabSOSまたはKubeSOSのログを使用して、[GitLab RPSアナライザー](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/gitlab-rps-analyzer#gitlab-rps-analyzer)でリファレンスアーキテクチャのサイズを評価します。ただし、これはメトリクスを使用する場合よりも信頼性が低い点に注意してください。

他のプラットフォームから移行する場合、既存のGitLabメトリクスがないため、次のPromQLクエリは適用できません。ただし、一般的な評価手法は引き続き有効です:

1. 想定されるワークロードに基づき、最も近いリファレンスアーキテクチャを見積もります。
1. 想定される追加ワークロードを特定します。
1. 大規模リポジトリの数を評価します。
1. 成長予測を織り込みます。
1. [適切なバッファ](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down)を備えたリファレンスアーキテクチャを選択します。

### PromQLクエリを実行する {#running-promql-queries}

PromQLクエリの実行は、使用するモニタリングソリューションによって異なります。[Prometheusモニタリングのドキュメント](../monitoring/prometheus/_index.md#how-prometheus-works)に記載されているように、Prometheusに直接接続するか、Grafanaなどのダッシュボードツールを使用することで、モニタリングデータにアクセスできます。

## ベースラインサイズを決定する {#determine-your-baseline-size}

1秒あたりのリクエスト数（RPS）は、GitLabインフラストラクチャのサイジングにおける主要なメトリクスです。トラフィックタイプ（API、Web、Git操作）によって負荷がかかるコンポーネントが異なるため、真の容量要件を把握するにはそれぞれを個別に分析します。

### トラフィックピークのメトリクスを抽出する {#extract-peak-traffic-metrics}

次のクエリを実行して、最大負荷を把握します。これらのクエリにより、次のことを確認できます:

- 絶対ピーク。これまでに観測された最大のスパイクです。絶対ピークは最悪のシナリオを示します。
- 持続ピーク。これは95パーセンタイルで、一般的な「ビジー」レベルと見なされます。持続ピークは、典型的な高負荷の時間帯を示します。

絶対ピークがまれな異常値である場合は、持続負荷に合わせてサイジングするのが適切なことがあります。

保持期間に応じて、クエリの時間範囲を調整します（より長い履歴が利用可能な場合は、`[7d]`を`[30d]`に変更します）。

> [!note]
> アクティビティの高い環境では、`max_over_time`や`quantile_over_time`のクエリがタイムアウトする場合があります。その場合は、外部の集計関数を削除し、内部のクエリをグラフで可視化します。たとえば、APIトラフィックのピークを確認するには、次を使用します:
>
> ```prometheus
> sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))
> ```
>
> 次に、モニタリング期間全体にわたるグラフ結果から、ピーク値を目視で特定します。

#### 絶対ピークをクエリする {#query-absolute-peaks}

指定された期間に観測された最大RPSを特定するには:

1. 次のクエリを実行します:

   - APIトラフィックのピーク。自動化、外部ツール、WebhookからのAPIリクエストのピークを測定します:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - Webトラフィックのピーク。ブラウザでのユーザーによるUI操作のピークを測定します:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Gitプルとクローンのピーク。リポジトリの複製およびフェッチ操作のピークを測定します:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Gitプッシュのピーク。コードのプッシュ操作のピークを測定します:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

#### 持続ピークをクエリする {#query-sustained-peaks}

まれなスパイクを除外し、典型的な高負荷レベルを特定するには:

1. 次のクエリを実行します:

   - APIの持続ピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - Webの持続ピーク:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Gitプルとクローンの持続ピーク:

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Gitプッシュの持続ピーク:

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 結果を記録します。

### トラフィックをリファレンスアーキテクチャにマッピングする {#map-traffic-to-reference-architectures}

先ほど記録した結果を使用して、トラフィックをリファレンスアーキテクチャにマッピングするには:

1. [利用可能なリファレンスアーキテクチャ](_index.md#available-reference-architectures)を参照し、各トラフィックタイプが示唆するリファレンスアーキテクチャを確認します。
1. 分析表に入力します。次の表を参考にしてください:

   | トラフィックタイプ       | ピークRPS | ピーク時に推奨されるRA     | 持続RPS | 持続時に推奨されるRA |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | \________ | \_\_\_\_\_（最大 \_\__ RPS） | \_____________ | \_\_\_\_\_（最大 \_\_\__ RPS） |
   | Web                | \________ | \_\_\_\_\_（最大 \_\__ RPS） | \_____________ | \_\_\_\_\_（最大 \_\_\__ RPS） |
   | Gitプルとクローン | \________ | \_\_\_\_\_（最大 \_\__ RPS） | \_____________ | \_\_\_\_\_（最大 \_\_\__ RPS） |
   | Gitプッシュ           | \________ | \_\_\_\_\_（最大 \_\__ RPS） | \_____________ | \_\_\_\_\_（最大 \_\_\__ RPS） |

1. **ピーク時に推奨されるRA**列にあるすべてのリファレンスアーキテクチャを比較し、最大のサイズを選択します。**持続時に推奨されるRA**列についても同じように選択します。
1. ベースラインを文書化します:
   - 推奨される最大のピークRA。
   - 推奨される最大の持続RA。

### リファレンスアーキテクチャを選択する {#choose-a-reference-architecture}

この時点で、候補となるリファレンスアーキテクチャのサイズは2つあります:

- 絶対ピークに基づくもの。
- 持続負荷に基づくもの。

リファレンスアーキテクチャを選択するには:

1. ピークと持続負荷が同じRAを示唆している場合は、そのRAを使用します。
1. ピークが持続負荷より大きいRAを示唆している場合は、差分を計算します。ピークRPSは、持続RAの上限値に対して10〜15%以内の超過に収まっていますか？

一般的なガイドライン:

- ピークRPSが、持続RAの上限値を超える割合が10〜15%未満であれば、リファレンスアーキテクチャにはあらかじめ余裕が見込まれているため、許容可能なリスクとして持続RAを検討できます。
- 15%を超える場合は、ピークベースのRAから開始し、メトリクスに基づいて縮小が可能と判断できれば、モニタリングしながら調整します。
  - 例1: ピークが110 RPS、Large RAは「最大100 RPS」を処理 → 10%超過 → Largeで十分（リファレンスアーキテクチャにはあらかじめ余裕が見込まれている）
  - 例2: ピークは150 RPS、Large RAは「最大100 RPS」を処理 → 50%超過 → X-Large（最大200 RPS）を使用
  - 例3: ピークは100 RPS（Large/100 RPS）、持続は50 RPS（Medium/60 RPS）。Raw RPSグラフでは、自動化によるスパイクがピークを引き起こし、ほとんどの時間は負荷が50 RPS未満であることがわかります。ユーザーは、保守的にLargeで開始して後でスケールダウンするか、[ワークロードに応じたスケーリング](#identify-component-adjustments)を前提にMedium（高リスク）で開始するかを評価します。

40 RPS未満の環境で、かつ高可用性（HA）が要件である場合は、[高可用性のセクション](_index.md#high-availability-ha)を参照して、サポートされる削減を適用した60 RPS / 3,000ユーザーアーキテクチャに切り替える必要があるかどうかを確認します。

### 先に進む前に {#before-you-proceed}

このセクションを完了したことで、ベースラインとなるリファレンスアーキテクチャのサイズを確立しました。これは基盤となりますが、以降のセクションでは、特定のワークロードにより標準設定を超えたコンポーネント調整が必要かどうかを特定します。

先に進む前に、このセクションで収集した詳細を文書化していることを確認してください。次の情報を参考にしてください:

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

## RPSの内訳とワークロードパターンを理解する {#understanding-rps-composition-and-workload-patterns}

合計RPSは主要なサイジングメトリクスですが、ワークロードの内訳はコンポーネントのリソース要件に大きな影響を与えます。リクエストタイプが異なると、負荷がかかるコンポーネントや負荷の強度も異なります。

### リクエストタイプ別のRPSの内訳 {#rps-breakdown-by-request-type}

リファレンスアーキテクチャのRPS目標値は、本番環境のデータに基づく典型的なワークロードの内訳を前提としています:

- **APIリクエスト**（総RPSの約80%）- 自動化、インテグレーション、Webhook、API駆動型ツール
- **Webリクエスト**（総RPSの約10%）- UI操作、ページナビゲーション、ユーザー主導のアクション
- **Git操作**（総RPSの約10%）- リポジトリのクローンとプル。プッシュレートは低い

**非典型的な構成** \- いずれかのリクエストタイプが典型的な割合を大幅に上回る環境（目標RPS範囲内であっても、コンポーネント固有の調整が必要になる場合があります）

### 非典型的なワークロードパターンを特定する {#identifying-atypical-workload-patterns}

[トラフィックピークのメトリクスを抽出する](#extract-peak-traffic-metrics)で使用したRPS抽出クエリを使用して、ワークロードの内訳を把握します。結果として得られた分布を一般的なパターンと比較します:

**APIの比重が高いワークロード**（APIが総RPSの90%超）: 

- 負荷の高い自動化、幅広いインテグレーション、API駆動型ツールの活用
- 主な影響先: Rails（Webservice）、PostgreSQL、Gitaly
- 次の対応を検討してください: Webservice/Railsの処理能力増強、データベースの読み取りレプリカ

**Webの比重が高いワークロード**（Webが総RPSの20%超）: 

- アクティブユーザーが多い、UI操作が頻繁に行われる
- 主な影響先: Rails（Webservice）、PostgreSQL
- 次の対応を検討してください: Webserviceの処理能力増強、データベースの最適化

**Git操作の比重が高いワークロード**（Gitが総RPSの15%超、またはプルレートが規模に対して典型的な水準より明らかに高い）:

- 大規模チームによる頻繁なプル、モノレポパターン、またはリポジトリのクローンを伴うCI/CD中心のワークフロー
- 主な影響先: Gitaly、ネットワーク帯域幅
- 次の対応を検討してください: Gitalyの垂直スケーリング、リポジトリの最適化、ネットワーク性能を強化したVM

### 評価アプローチ {#assessment-approach}

1. 提示されたPromQLクエリを使用して、RPSの内訳を抽出します
1. 各リクエストタイプについて、合計に占める割合を計算します
1. いずれかのタイプが典型的な割合を大きく上回っていないかを特定します
1. 非典型的な場合は、スケーリングのガイダンスとして[コンポーネント調整を特定する](#identify-component-adjustments)を参照してください

> [!note]
> 変動が小さい場合（いずれかのカテゴリでRPSの差が5〜10）は、アーキテクチャの変更を必要としません。RPSの比較だけで判断するのではなく、本番環境の実際のコンポーネント飽和度メトリクス（CPU、メモリ、キュー深度）をモニタリングしてください。コンポーネントの持続的な使用率が70%未満であれば、RPSのわずかな変動にかかわらず、一般的に十分な容量が確保されています。

## コンポーネント調整を特定する {#identify-component-adjustments}

ワークロード評価では、ベースとなるリファレンスアーキテクチャを超えて、コンポーネント調整が必要となる特定の利用パターンを洗い出します。RPSは全体のサイズを決定しますが、ワークロードパターンはその形を決定します。RPSが同一の2つの環境でも、必要となるリソースが大きく異なる場合があります。

ワークロードの種類によって、GitLabアーキテクチャの異なる部分に負荷がかかります:

- 何千ものジョブを処理しながら、RPSは中程度に保たれているCI/CD中心の環境では、SidekiqとGitalyに負荷がかかります。
- APIの自動化が広範にわたる環境では、RPSが高くなる一方で、負荷はデータベースレイヤーとRailsレイヤーに集中します。

### ピーク負荷時の主要エンドポイントを分析する {#analyze-top-endpoints-during-peak-load}

前のセクションで特定したピークタイムスタンプを使用して、最大負荷時にどのエンドポイントが最も多くのトラフィックを受けていたかを特定します。

> [!note]
> RPSメトリクスで、営業時間外に一貫して高いトラフィック（ピークの50%超）が確認される場合、典型的なパターンを超える大規模な自動化が行われていることを示唆します。たとえば、営業時間中にピークトラフィックが100 RPSに達し、夜間や週末でも50 RPS以上を維持している場合は、大量の自動化ワークロードが存在すると考えられます。[コンポーネント調整を評価する](#determine-component-adjustments)際は、この点を考慮してください。

1. 可視化を有効にして次のクエリを実行します（時間推移の分布は棒チャート、一般的な分布は円チャート）:

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. 絶対RPSピーク時における主要エンドポイントの分布の結果を確認します。結果には、次のようなパターンが見られる場合があります:

   - 明確なエンドポイントパターンが見られない。この場合は、以前に選択したリファレンスアーキテクチャを継続します。ワークロードの変化による影響を測定できるよう、堅牢なモニタリング体制を確保します。
   - Git以外のトラフィックにおけるAPI利用が大半を占める。この場合は、Webhookやイシュー、グループ、プロジェクトに対するAPIコールが中心であり、データベース集中型のパターンを示します。
   - GitまたはSidekiq関連のエンドポイントが大半を占める。この場合は、マージリクエストの差分、パイプラインジョブ、ブランチ、コミット、ファイル操作、CI/CDジョブ、セキュリティスキャン、インポート操作などが中心で、Sidekiq/Gitaly集中型のパターンを示します。

1. 調査結果を記録します:

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### コンポーネント調整を決定する {#determine-component-adjustments}

上記の指標は、追加ワークロードの初期のシグナルを示しています。リファレンスアーキテクチャには余裕が見込まれているため、これらのワークロードは調整なしでも処理できる場合があります。ただし、強い兆候があり、高度な自動化が行われていると判明している場合は、次の調整を検討してください。

以前に特定したワークロードパターンによって、スケーリングが必要となるコンポーネントは異なります:

| ワークロードのタイプ              | 適用する条件                                                                                                                                                                                | スケールするコンポーネント |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| データベース集中型         | <ul><li>Git以外のトラフィックにおけるAPI使用が多い（Webhook、イシュー、グループ、プロジェクト）</li><li>[広範な自動化またはインテグレーションワークロード](_index.md#additional-workloads)が確認されている</li></ul> | <ul><li>Railsリソースの増強</li><li>[データベースのスケーリング](#database-scaling)</li></ul> |
| Sidekiq/Gitaly集中型\** | <ul><li>Git操作、CI/CDジョブ、セキュリティスキャン、インポート操作、Gitサーバーフックが多い</li><li>CI/CD中心の使用パターンが確認されている</li></ul>                                      | <ul><li>Sidekiq仕様の引き上げ</li><li>Gitalyの垂直スケール</li><li>[データベースのスケーリング](#database-scaling)</li><li>高度: 特定の[ジョブクラス](../sidekiq/processing_specific_job_classes.md)の設定</li></ul> |

#### スケーリングガイダンス {#scaling-guidance}

リソース調整は、ワークロードの強度と飽和メトリクスに応じて異なります:

1. 現在のリソースの1.25～1.5倍から始めます。
1. 実装後はモニタリングデータに基づいて調整します。

クラウドネイティブGitLabのデプロイを計画している場合、この評価で特定したワークロードパターンは、Kubernetesの設定にもさらなる影響を与えます:

- 営業時間外のトラフィックが高い。閑散時間帯にスケールツーゼロを許可するのではなく、ベースライン負荷に対して十分な最小ポッド数が確保されていることを確認してください。たとえば、営業時間中は100 RPSで、夜間は自動化により一貫して50 RPSを維持している場合、最小ポッド数設定は、営業時間外のベースライン負荷に合わせる必要があります。
- トラフィックの急激なスパイクがある。デフォルトのHPA設定ではスケールが十分に速く行われない可能性があります。初期のロールアウト時にポッドのスケーリング動作をモニタリングし、移行中にリクエストがキューイングされないようにしてください。たとえば、閑散時間帯から稼働時間帯に移行する際や特定の自動化スパイクにより、50 RPSから200 RPSに急増するケースなどが考えられます。

##### データベースのスケーリング {#database-scaling}

データベースのスケーリング戦略はワークロードの特性によって異なり、複数のアプローチが必要になる場合があります:

1. 即時の容量制約に対処するための垂直スケーリング:
   - 書き込み負荷の高いワークロードでは、レプリカを追加してもプライマリの負荷は減らないため垂直スケーリングが必要になります。
   - 読み取りと書き込みの両方の操作に対して、即時の容量増加を提供します。
1. 読み取りレプリカを使用した[データベースロードバランシング](../postgresql/database_load_balancing.md)（推奨）:
   - 読み取り負荷の高いワークロード（読み取りが85〜95%）で特に有効です。
   - 読み取りトラフィックを複数のノードに分散します。
   - 垂直スケーリングと組み合わせて追加できます。
1. 書き込みパフォーマンスが引き続きボトルネックである場合は、垂直スケーリングを継続します。

読み取り/書き込みの分布を特定するには、次のPrometheusクエリを使用します:

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### 先に進む前に {#before-you-proceed-1}

このセクションを完了したことで、ワークロードパターンを特定し、必要なコンポーネント調整を決定しました。

先に進む前に、ワークロード評価をすべて記録してください:

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

次のセクションでは、追加のインフラストラクチャの検討が必要になる可能性がある、特別なデータ特性を評価します。

## 特別なインフラストラクチャ要件を評価する {#assess-special-infrastructure-requirements}

リポジトリの特性やネットワークの使用パターンは、RPSメトリクスからは見えない形でGitLabのパフォーマンスに大きな影響を与える可能性があります。

大規模なモノレポ、大量のバイナリファイル、ネットワーク負荷の高い操作では、標準的なサイジングでは考慮されないインフラストラクチャの調整が必要になります。

### 大規模なモノレポ {#large-monorepos}

大規模なモノレポ（数ギガバイト以上）は、Git操作のパフォーマンスのあり方を根本的に変えます。10 GBのリポジトリを1回クローンするだけで、一般的なリポジトリを数百回クローンするよりも多くのリソースを消費します。

これらのリポジトリは、ワークロードに応じてGitalyだけでなく、Rails、Sidekiq、データベースにも影響します。

プロファイリングプロセスでは、一般的なサイズを大幅に上回るリポジトリを特定することに重点を置きます:

- 中規模なモノレポ: 2 GB〜10 GB。軽微な調整が必要です。
- 大規模なモノレポ: 10 GB超。大幅なインフラストラクチャの変更が必要です。

リポジトリのサイズを特定するには:

1. プロジェクトの[使用量クォータ](../../user/storage_usage_quotas.md#view-storage)に移動します。
1. [**リポジトリ**ストレージタイプ](../../user/project/repository/repository_size.md)を確認します。
1. 2 GB超および10 GB超のリポジトリを持つプロジェクトの数を計算します。
1. 結果を記録します:

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### モノレポのインフラストラクチャの調整 {#infrastructure-adjustments-for-monorepos}

大規模なリポジトリでは、垂直スケーリングと運用面での調整の両方が必要になります。これらのリポジトリは、Git操作やCPU使用率からメモリ消費量、ネットワーク帯域幅に至るまで、スタック全体のパフォーマンスに影響します。

| シナリオ                 | コンポーネントの調整 |
|:-------------------------|:----------------------|
| 複数の中規模なモノレポ | <ul><li>Gitaly: 仕様を1.5〜2倍にする</li><li>Rails: 仕様を1.25〜1.5倍にする</li></ul> |
| 大規模なモノレポ          | <ul><li>Gitaly: 仕様を2〜4倍にする</li><li>Rails: 仕様を1.5〜2倍にする</li><li>モノレポを専用のGitalyノードにシャーディングすることを検討する</li></ul> |

モノレポ環境における追加の最適化戦略は、[モノレポのパフォーマンスを向上させる](../../user/project/repository/monorepos/_index.md)に記載されています。これには、バイナリファイル向けのGit LFSやシャロークローンなどが含まれます。

### ネットワーク負荷の高いワークロード {#network-heavy-workloads}

ネットワーク飽和は、診断が難しくなりがちな固有の問題を引き起こします。特定の操作に影響するCPUやメモリのボトルネックとは異なり、ネットワーク飽和はGitLabのあらゆる機能で、一見ランダムなタイムアウトを発生させる可能性があります。

一般的なネットワーク負荷の発生源:

- コンテナレジストリの高負荷利用（大きなイメージ、頻繁なプル）。
- LFS操作（バイナリファイル、メディアアセット）。
- 大規模なCI/CDアーティファクト（ビルド出力、テスト結果）。
- モノレポのクローン（特にCI/CDパイプライン内）。

#### ネットワーク使用量を測定する {#measure-network-usage}

潜在的なボトルネックを特定するため、ネットワーク消費量のピークとベースラインを計算します。ピークとベースラインの両方を評価することで、一時的なスパイク（バースト容量で対応可能）と、継続的な高トラフィック（ネットワーク性能を強化したVMが必要）を区別できます。

1. 次のクエリを実行します:

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. モニタリング期間を通じて観測されたピークスパイクと、典型的なベースラインの両方を記録します:

   ```plaintext
   Peak outbound traffic: _____ Gbps (baseline: _____ Gbps)
   Peak inbound traffic: _____ Gbps (baseline: _____ Gbps)
   ```

#### ネットワーク容量の要件 {#network-capacity-requirements}

以下のしきい値は、あくまでガイドラインに過ぎません。実際のネットワーク帯域幅の保証は、クラウドプロバイダーやVMタイプによって大きく異なります。対象のインスタンスタイプのネットワーク仕様（ベースラインおよびバースト制限）を必ず検証して、ワークロードのパターンと一致していることを確認してください。

送信および受信トラフィックの測定値に基づくガイドライン:

| ネットワーク負荷 | しきい値 | このしきい値の理由                                                 | 必要なアクション |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| 標準     | 1 Gbps未満   | ほとんどの標準インスタンスにおいてベースライン帯域幅の範囲内               | 標準インスタンスで十分 |
| 中程度     | 1〜3 Gbps  | AWSのベースラインを超える可能性があるが、GCP/Azureの標準インスタンスの範囲内    | <ul><li>AWS: スロットリングをモニタリングする。ネットワーク性能の強化が必要になる場合がある</li><li>GCP/Azure: 通常は標準インスタンスで十分</li></ul> |
| 高い         | 3〜10 Gbps | AWSのベースラインを超える。一部の標準インスタンスの上限に近づく | <ul><li>AWS: ネットワーク性能を強化したVMが必要</li><li>GCP/Azure: インスタンスの帯域幅仕様を確認する</li></ul> |
| 非常に高い    | 10 Gbps超  | ほとんどの標準インスタンスの能力を超える                        | <ul><li>すべてのプロバイダーでネットワーク性能を強化したVMが必要になる</li><li>大きなアーティファクトについては、[オブジェクトプロキシのダウンロード](../object_storage.md#proxy-download)を無効にする</li></ul> |

### 先に進む前に {#before-you-proceed-2}

先に進む前に、データプロファイリング評価をすべて記録してください:

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

既存の環境を理解することは、推奨事項に重要なコンテキストを提供します:

- 現在の環境でパフォーマンスの問題なくワークロードを処理できている場合、サイジングの見積もりにおいて有効な検証材料になります。
- 逆に、パフォーマンスに問題がある環境では、サイズ不足をそのまま継続しないよう、慎重な分析が必要です。

### 現在の環境を文書化する {#document-the-current-environment}

包括的な環境データを収集し、現状を把握します:

- アーキテクチャの詳細:
  - タイプ: 高可用性（HA）または非高可用性（非HA）。
  - デプロイ方法: LinuxパッケージまたはクラウドネイティブGitLab。
- コンポーネントの仕様:
  - 各コンポーネントのノード数と仕様。
  - カスタム設定または標準からの逸脱事項。

### 最も近いリファレンスアーキテクチャを特定する {#identify-the-nearest-reference-architecture}

1. 現在の環境を、[利用可能なリファレンスアーキテクチャ](_index.md)と比較します。次の点を考慮してください:

   - コンポーネントごとの総コンピューティングリソース。
   - ノードの分散とアーキテクチャパターン（HAと非HA）。
   - リファレンスアーキテクチャのサイズと比較した各コンポーネント仕様の過不足。

1. 結果を記録します:

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### 現在の環境を推奨アーキテクチャと比較する {#compare-current-environment-to-recommended-architecture}

前のセクションで策定した推奨リファレンスアーキテクチャに照らして、現在の環境を比較します。現在の環境が次のいずれかに該当する場合:

- パフォーマンスの問題がなく、現在のリソースが推奨RAよりも少ない: 
  - 推奨事項は保守的で、将来の余裕を確保できます。
  - 推奨RAで進めてください。
  - 導入後はモニタリングして、最適化の機会がないか確認してください。
- パフォーマンスの問題がなく、現在のリソースが推奨RAとほぼ同等である: 
  - サイジング評価の強力な検証材料となります。
  - 現在の環境により、推奨サイズが適切であることが確認できます。
- パフォーマンスの問題がなく、現在のリソースが推奨RAより多い: 
  - 現在の環境は過剰にプロビジョニングされている可能性があります。または、追加リソースを必要とする正当な理由が存在する可能性があり、その分析が必要です。Rails、Gitaly、データベース、SidekiqのCPU/メモリ[リソース使用率](../monitoring/prometheus/_index.md#sample-prometheus-queries)を確認してください。

    使用率が低い（40%未満）場合は、過剰なプロビジョニングを示唆しています。使用率が高い場合は、RPS分析では捉えられていない特定のワークロード要件を示している可能性があります。
  - 把握していない要件に対応するために推奨事項の調整が必要かどうかを確認してください。

現在の環境にパフォーマンスの問題がある場合:

- 現在の仕様は最小限のベースラインとしてのみ扱ってください。前のセクションの推奨事項は、現在の仕様を上回る必要があります。
- 推奨事項が現在より大幅に低い場合は、次の点を調査してください:
  - 評価で捉えられていないワークロードパターン。
  - ターゲットを絞ったスケーリングが必要なコンポーネント固有のボトルネック。

### 先に進む前に {#before-you-proceed-3}

このセクションを完了したことで、現在の環境を分析し、推奨事項と比較しました。

先に進む前に、環境の比較結果をすべて記録してください:

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

次のセクションでは、サイジングが時間の経過とともに適切であり続けるよう、成長予測を評価します。

## 将来のキャパシティを計画する {#plan-for-future-capacity}

インフラストラクチャの変更には、調達、移行、テストのために十分なリードタイムが必要です。成長の見積もりにより、推奨アーキテクチャで導入期間中およびその後も運用可能な状態を確実に維持できるようにします。

過去の傾向と事業計画を組み合わせることで、最も正確な成長予測が得られます。

### 過去の成長パターンを分析する {#analyze-historical-growth-patterns}

過去の成長パターンは、事業予測よりも将来の推移を適切に予測できる場合があります:

1. [ベースラインサイズ](#determine-your-baseline-size)の情報を使用して、現在のRPSを6～12か月前のRPSと比較します。
1. 成長の加速または減速の傾向を特定します。

### 事業計画の要素を組み込む {#incorporate-business-planning-factors}

インフラストラクチャのニーズに影響する、想定される事業上の変更:

- チームの拡大または統合。
- 新規プロジェクトの立ち上げ。
- 既存プロジェクトにおける開発アクティビティの増加。

これらの要因（またはその他の組織的な変更）のいずれかが環境への負荷に影響し、インフラストラクチャの調整が必要になる可能性があるかどうかを評価します。関連する変更と、その想定されるタイムラインを文書化します。

#### 成長バッファ戦略を決定する {#determine-growth-buffer-strategy}

過去の傾向と事業予測に基づいて、適切な成長対応戦略を選択します:

- 安定した成長または最小限の成長: モニタリングを継続します。リファレンスアーキテクチャには、あらかじめ余裕が見込まれています。
- 中程度の成長: 将来のRPS予測に対応できるサイズのRAを計画します。
- 大幅な成長が予想される: 現在のRPSではなく、将来のRPS予測に基づいてサイジングすることを検討します。

### 先に進む前に {#before-you-proceed-4}

このセクションを完了したことで、成長予測がサイジングの判断に組み込まれました。

成長分析の結果をすべて記録してください:

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

次のセクションでは、すべての結果をまとめて、最終的なアーキテクチャの推奨事項を作成します。

## 結果をまとめる {#compile-findings}

これまでのセクションの結果をすべてまとめて、最適なリファレンスアーキテクチャと必要な調整を決定します。

### 最終アーキテクチャを決定する {#determine-final-architecture}

各セクションの主要な結果を収集し、サイジングを判断します:

1. [RPS分析](#determine-your-baseline-size)に基づいて特定したリファレンスアーキテクチャから開始します。
1. [ワークロードパターン](#identify-component-adjustments)と[データ特性](#assess-special-infrastructure-requirements)に基づいて、必要なコンポーネントの調整を適用します。パターンが特定されない場合、または標準構成で十分な場合は、この手順をスキップします。
1. [現在の状態](#analyze-current-environment-and-validate-recommendations)に照らして検証します。現在の環境が良好に動作しているものの推奨事項を上回る場合は、その理由を文書化します。パフォーマンスに問題がある場合は、推奨事項が現在の仕様を上回るようにします。
1. [将来の容量計画では成長](#plan-for-future-capacity)を織り込みます。現在のRAで十分か、成長予測に基づくサイジングが必要かを判断します。

### 最終的な推奨事項を文書化する {#document-final-recommendation}

包括的な評価に基づいて、アーキテクチャの推奨事項をすべて記録してください:

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

これで、すべてのセクションが完了し、サイジング評価は完了しました。最終的な推奨事項には、次の内容が含まれます:

- ベースとなるリファレンスアーキテクチャのサイズ。
- コンポーネント別の調整。
- 成長への対応戦略。

ワークロードパターンの進化に伴い、前提を検証しインフラストラクチャを調整するために定期的なモニタリングは引き続き不可欠です。
