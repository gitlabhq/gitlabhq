---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: DevOpsのパフォーマンスに関するインサイトを得て、ワークフローを改善する機会を見つけます。
title: DevOps Research and Assessment（DORA）メトリクス
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[DevOps Research and Assessment（DORA）](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)メトリクスは、DevOpsのパフォーマンスに関するエビデンスに基づいたインサイトを提供します。これら4つの主要な測定値は、チームが変更をどれだけ迅速に配信し、それらの変更が本番環境でどれだけうまく機能するかを示します。DORAメトリクスを継続的に追跡すると、ソフトウェアデリバリープロセス全体の改善機会が明確になります。

DORAメトリクスを使用して戦略的な意思決定を行い、ステークホルダーへのプロセス改善投資を正当化したり、チームのパフォーマンスを業界のベンチマークと比較して、競争上の優位性を特定したりできます。

4つのDORAメトリクスは、DevOpsの2つの重要な側面を測定します。

- **ベロシティメトリクス**: 組織がソフトウェアをどれだけ迅速に配信するかを追跡します。
  - [デプロイ頻度](#deployment-frequency): コードが本番環境にデプロイされる頻度
  - [変更のリード時間](#lead-time-for-changes): コードが本番環境に到達するまでにかかる時間

- **安定性メトリクス**: ソフトウェアの信頼性を測定します。
  - [変更失敗率](#change-failure-rate): デプロイによって本番環境の障害がどのくらいの頻度で発生するか
  - [サービス復旧時間](#time-to-restore-service): 障害後にサービスがどのくらいの速さで復旧するか

ベロシティと安定性の両方のメトリクスに焦点を当てることで、リーダーは配信ワークフローにおけるスピードと品質の最適なバランスを見つけることができます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 動画での解説については、[DORA metrics: User analytics](https://www.youtube.com/watch?v=jYQSH4EY6_U)（DORAメトリクス: ユーザー分析）と[GitLab speed run: DORA metrics](https://www.youtube.com/watch?v=1BrcMV6rCDw)（GitLabの高速実行: DORAメトリクス）をご覧ください。

## デプロイ頻度 {#deployment-frequency}

{{< history >}}

- GitLab 16.0で、`all`および`monthly`間隔の頻度計算式の修正が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/394712)されました。

{{< /history >}}

デプロイ頻度とは、指定された日付範囲（時間単位、日単位、週単位、月単位、または年単位）における本番環境へのデプロイの成功頻度です。

ソフトウェアリーダーは、デプロイ頻度のメトリクスを使用することで、チームがソフトウェアを本番環境にどれだけ頻繁に正常にデプロイしているか、またチームが顧客のリクエストや新しい市場機会にどれだけ迅速に対応できるかを把握することができます。デプロイ頻度が高いということは、フィードバックをより早く得て、より迅速にイテレーションを行い、改善や機能を提供できることを意味します。

### デプロイ頻度の予測 {#deployment-frequency-forecasting}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

デプロイ頻度の予測（以前はバリューストリーム予測と呼ばれていました）は、統計的予測モデルを使用して、生産性メトリクスを予測し、ソフトウェア開発ライフサイクル全体のアノマリを特定します。この情報は、製品およびチームの計画と意思決定を改善するのに役立ちます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Value stream forecasting](https://www.youtube.com/watch?v=6u8_8QQ5pEQ&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)（バリューストリーム予測）の概要をご覧ください。

### デプロイ頻度の計算方法 {#how-deployment-frequency-is-calculated}

GitLabでは、デプロイ頻度は、指定された環境への1日あたりの平均デプロイ数として測定され、デプロイの終了時間（`finished_at`プロパティ）に基づいています。GitLabは、指定された日の完了したデプロイの数からデプロイ頻度を計算します。成功したデプロイ（`Deployment.statuses = success`）のみがカウントされます。

計算では、本番環境`environment tier`または`production/prod`という名前の環境が考慮に入れられます。デプロイ情報がグラフに表示されるためには、環境が本番環境デプロイ階層の一部である必要があります。

[`.gitlab/insights.yml`ファイル](../project/insights/_index.md#configuration)の`environment_tiers`パラメータで`other`を指定することにより、さまざまな環境のDORAメトリクスを設定できます。

{{< alert type="note" >}}

デプロイ頻度は**平均値**として計算されます。他のDORAメトリクスは中央値を使用します。中央値は推奨される値であり、より正確で信頼性の高いパフォーマンスのビューを提供します。この違いは、DORAフレームワークを採用する前にデプロイ頻度がGitLabに追加され、このメトリクスの計算は他のレポートに組み込まれたときにも変更されなかったことに起因します。[イシュー499591](https://gitlab.com/gitlab-org/gitlab/-/issues/499591)では、各メトリクスの計算方法をカスタマイズし、平均値と中央値を選択するオプションを提供することを提案しています。

{{< /alert >}}

### デプロイ頻度を改善する方法 {#how-to-improve-deployment-frequency}

最初のステップは、グループとプロジェクト間のコードリリースのケイデンスをベンチマークすることです。次に、以下を検討する必要があります。

- 自動テストを追加する。
- 自動コード検証を追加する。
- 変更をより小さなイテレーションに分割する。

## 変更のリード時間 {#lead-time-for-changes}

変更のリード時間とは、コードの変更が本番環境に入るまでにかかる時間です。

**変更のリード時間**は、**リードタイム**と同じではありません。バリューストリーム分析では、リードタイムは、イシューに関する作業がリクエストされた瞬間（イシューの作成）から、その作業が完了して配信された瞬間（イシューの完了）までに要する時間を測定します。

ソフトウェアリーダーにとって、変更のリード時間は、CI/CDパイプラインの効率性を示すとともに、作業が顧客にどれだけ迅速に配信されるかを視覚化するものです。時間の経過とともに、変更のリード時間は短縮され、チームのパフォーマンスは向上するはずです。変更のリード時間が短いということは、CI/CDパイプラインがより効率的であることを意味します。

### 変更のリード時間の計算方法 {#how-lead-time-for-changes-is-calculated}

GitLabは、マージリクエストが本番環境に正常に配信されるまでにかかる秒数、つまりマージリクエストのマージ時刻（マージボタンがクリックされたとき）から、コードが本番環境で正常に実行されるまでの秒数に基づいて、変更のリード時間を計算します。このとき、計算に`coding_time`を追加しません。データは、デプロイが完了した直後に集計されますが、わずかな遅延があります。

デフォルトでは、変更のリード時間は、複数のデプロイジョブが含まれる1つのブランチオペレーション（たとえば、デフォルトブランチでの開発からステージング、本番環境まで）のみの測定をサポートします。マージリクエストがステージングでマージされ、次に本番環境でマージされる場合、GitLabはそれらを1つではなく、2つのデプロイされたマージリクエストとして解釈します。

#### マージの前に完了するデプロイ {#deployments-finishing-before-merge}

まれに、関連付けられたマージリクエストがマージされる前に、デプロイが完了する場合があります。

このシナリオは、次のような場合に発生する可能性があります。

- デプロイプロセスが、マージワークフローとは無関係にトリガーされる。
- コードレビューの完了前に、手動によるデプロイが介入する。

この場合、GitLabは数式`GREATEST(0, deployment_finished_at - merge_request_merged_at)`を使用します。`GREATEST`関数は、負の値の代わりに`0`を返すことにより、リード時間の値が負にならないようにします。この関数は、データの整合性を保持しながら、データベースの制約違反を防ぎます。

### 変更のリード時間を改善する方法 {#how-to-improve-lead-time-for-changes}

最初のステップは、グループとプロジェクト間のCI/CDパイプラインの効率性をベンチマークすることです。次に、以下を検討する必要があります。

- バリューストリーム分析を使用して、プロセスのボトルネックを特定する。
- 変更をより小さなイテレーションに分割する。
- 自動化を追加する。
- パイプラインのパフォーマンスを改善する。

## サービス復旧時間 {#time-to-restore-service}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356959)されました。

{{< /history >}}

サービス復旧時間とは、組織が本番環境の障害から回復するまでにかかる時間です。

ソフトウェアリーダーにとって、サービス復旧時間は、組織が本番環境の障害から回復するまでにかかる時間を示すものです。サービス復旧時間が短いということは、組織が競争上の優位性を高め、ビジネス成果を向上させるために、新しい革新的な機能をリスクを冒して導入できることを意味します。

### サービス復旧時間の計算方法 {#how-time-to-restore-service-is-calculated}

GitLabでは、サービス復旧時間は、本番環境でインシデントがオープンになっていた時間の中央値として測定されます。GitLabは、指定された期間に本番環境でインシデントがオープンになっていた秒数を計算します。これは以下を前提としています。

- [GitLabインシデント](../../operations/incident_management/incidents.md)が追跡されている。
- すべてのインシデントが本番環境に関連している。
- インシデントとデプロイが厳密に1対1の関係にある。インシデントは1つの本番環境デプロイのみに関連付けられ、本番環境デプロイは1つのインシデントのみに関連付けられます。

### サービス復旧時間を改善する方法 {#how-to-improve-time-to-restore-service}

最初のステップは、グループとプロジェクトの間で、サービスの中断および停止に対するチームの対応と、そこからの復旧をベンチマークすることです。次に、以下を検討する必要があります。

- 本番環境に対する可観測性を向上させる。
- 対応ワークフローを改善する。
- デプロイ頻度と変更のリード時間を改善して、修正を本番環境により効率的に導入できるようにする。

## 変更失敗率 {#change-failure-rate}

変更失敗率とは、本番環境で変更に起因する障害が発生する頻度です。

ソフトウェアリーダーは、変更失敗率のメトリクスを使用して、リリースされるコードの品質に関するインサイトを得ることができます。変更失敗率が高い場合は、非効率的なデプロイプロセス、または自動テストカバレッジの不足を示している可能性があります。

### 変更失敗率の計算方法 {#how-change-failure-rate-is-calculated}

GitLabでは、変更失敗率は、指定された期間に本番環境でインシデントを引き起こすデプロイの割合として測定されます。GitLabは、変更失敗率を、インシデント数を本番環境へのデプロイ数で割った数として計算します。この計算は以下を前提としています。

- [GitLabインシデント](../../operations/incident_management/incidents.md)が追跡されている。
- すべてのインシデントは、環境に関係なく、本番環境のインシデントである。
- 変更失敗率は、主に全体的な安定性を追跡するために使用される。そのため、特定の日に、すべてのインシデントとデプロイは、結合された日次レートに集計されます。[イシュー444295](https://gitlab.com/gitlab-org/gitlab/-/issues/444295)では、デプロイとインシデント間の特定の関係を追加することを提案しています。
- 変更失敗率では、重複するインシデントが個別のエントリとして計算されるため、二重カウントが発生する。[イシュー480920](https://gitlab.com/gitlab-org/gitlab/-/issues/480920)では、より正確な計算のためのソリューションを提案しています。

たとえば、10回のデプロイ（1日あたり1回のデプロイがあると見なす）があり、最初の日に2つのインシデント、最後の日に1つのインシデントがある場合、変更失敗率は0.3になります。

### 変更失敗率を改善する方法 {#how-to-improve-change-failure-rate}

最初のステップは、グループとプロジェクトの間で、品質と安定性をベンチマークすることです。次に、以下を検討する必要があります。

- 安定性とスループット（デプロイ頻度と変更のリード時間）の適切なバランスを見つけ、スピードのために品質を犠牲にしない。
- コードレビュープロセスの有効性を改善する。
- 自動テストを追加する。

## DORAカスタム計算ルール {#dora-custom-calculation-rules}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 15.4で`dora_configuration`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561)されました。デフォルトでは無効になっています。これは[実験的機能](../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

これは[実験的機能](../../policy/development_stages_support.md)です。この機能をテストしているユーザーのリストに参加する場合は、[提案されたテストフローをこちらで参照してください](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561#steps-to-check-on-localhost)。バグを見つけた場合は、[イシューをこちらでオープンしてください](https://gitlab.com/groups/gitlab-org/-/epics/11490)。ユースケースとフィードバックを共有する場合は、[エピック11490](https://gitlab.com/groups/gitlab-org/-/epics/11490)にコメントしてください。

### 変更のリード時間に対するマルチブランチルール {#multi-branch-rule-for-lead-time-for-changes}

デフォルトの[変更のリード時間の計算](#how-lead-time-for-changes-is-calculated)とは異なり、この計算ルールを使用すると、オペレーションごとに単一のデプロイジョブでマルチブランチオペレーションを測定できます。たとえば、開発ブランチの開発ジョブから、ステージングブランチのステージングジョブ、本番環境ブランチの本番環境ジョブに至るまでのジョブが対象です。

この計算ルールは、開発フローの一部であるターゲットブランチで`dora_configurations`テーブルを更新することで実装されました。これにより、GitLabは複数のブランチを1つとして認識し、他のマージリクエストを除外できます。

この設定により、選択したプロジェクトの日次DORAメトリクスの計算方法が変更されますが、他のプロジェクト、グループ、またはユーザーには影響しません。

この機能は、プロジェクトレベルの伝播のみをサポートします。

これを行うには、Railsコンソールで次のコマンドを実行します。

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
Dora::Configuration.create!(project: my_project, branches_for_lead_time_for_changes: ['master', 'main'])
```

既存の設定を更新するには、次のコマンドを実行します。

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
record = Dora::Configuration.where(project: my_project).first
record.branches_for_lead_time_for_changes = ['development', 'staging', 'master', 'main']
record.save!
```

## DORAメトリクスを測定する {#measure-dora-metrics}

### GitLab CI/CDパイプラインを使用しない場合 {#without-using-gitlab-cicd-pipelines}

デプロイ頻度は、一般的なプッシュベースのデプロイ用に作成されたデプロイレコードに基づいて計算されます。これらのデプロイレコードは、プルベースのデプロイでは作成されません。たとえば、コンテナイメージがエージェントを使用してGitLabに接続されている場合などです。

このような場合にDORAメトリクスを追跡するには、デプロイAPIを使用して[デプロイレコードを作成](../../api/deployments.md#create-a-deployment)することができます。デプロイ階層が設定されている環境名を指定する必要があります。これは、プラン変数がデプロイメントではなく、指定された環境に対して指定されているためです。詳細については、[外部デプロイツールのデプロイを追跡する](../../ci/environments/external_deployment_tools.md)方法を参照してください。

### Jiraを使用する場合 {#with-jira}

- デプロイ頻度と変更のリード時間は、GitLab CI/CDとマージリクエスト（MR）に基づいて計算され、Jiraデータを必要としません。
- サービス復旧時間と変更失敗率を計算するには、[GitLabインシデント](../../operations/incident_management/manage_incidents.md)が必要です。詳細については、[外部インシデントを使用して](#with-external-incidents)これらのメトリクスを測定する方法と、[Jiraインシデントレプリケーターガイド](https://gitlab.com/smathur/jira-incident-replicator)を参照してください。

### 外部インシデントを使用する場合 {#with-external-incidents}

インシデント管理のサービス復旧時間と変更失敗率を測定できます。

PagerDutyの場合、[Webhookを設定](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook)して、各PagerDutyインシデントに対してGitLabインシデントを自動的に作成できます。この設定では、PagerDutyとGitLabの両方で変更を行う必要があります。

他のインシデント管理ツールの場合、[HTTPインテグレーション](../../operations/incident_management/integrations.md#alerting-endpoints)を設定して、次のことを自動的に行うことができます。

1. [アラートがトリガーされたときにインシデントを作成する](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered)。
1. [リカバリーアラートを介してインシデントをクローズする](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts)。

## 分析機能 {#analytics-features}

DORAメトリクスは、次の分析機能に表示されます。

- [バリューストリームダッシュボード](value_streams_dashboard.md)には、[DORAメトリクスの比較パネル](value_streams_dashboard.md#devsecops-metrics-comparison)と[DORAパフォーマーズスコアパネル](value_streams_dashboard.md#dora-performers-score)が含まれています。
- [CI/CD分析チャート](ci_cd_analytics.md)には、DORAメトリクスの経時的な履歴が表示されます。
- [インサイトレポート](../project/insights/_index.md)は、[DORAクエリパラメータ](../project/insights/_index.md#dora-query-parameters)を使用してカスタムチャートを作成するオプションを提供します。
- [GraphQL API](../../api/graphql/reference/_index.md)（およびインタラクティブな[GraphQLエクスプローラー](../../api/graphql/_index.md#interactive-graphql-explorer)）と[REST API](../../api/dora/metrics.md)は、メトリクスデータの取得をサポートしています。

## プロジェクトとグループの可用性 {#project-and-group-availability}

次の表は、プロジェクトとグループにおけるDORAメトリクスの可用性の概要を示しています。

| メトリクス                    | レベル             | コメント |
|---------------------------|-------------------|----------|
| `deployment_frequency`    | プロジェクト           | 単位はデプロイ数。 |
| `deployment_frequency`    | グループ             | 単位はデプロイ数。集計方法は平均。  |
| `lead_time_for_changes`   | プロジェクト           | 単位は秒。集計方法は中央値。 |
| `lead_time_for_changes`   | グループ             | 単位は秒。集計方法は中央値。 |
| `time_to_restore_service` | プロジェクトとグループ | 単位は日。集計方法は中央値。（GitLab 15.1以降のUIチャートで利用可能） |
| `change_failure_rate`     | プロジェクトとグループ | デプロイの割合。（GitLab 15.2以降のUIチャートで利用可能） |

## データ集計 {#data-aggregation}

次の表は、さまざまなチャートにおけるDORAメトリクスのデータ集計の概要を示しています。

| メトリクス名 | 測定値 | [バリューストリームダッシュボード](value_streams_dashboard.md)におけるデータ集計 | [CI/CD分析チャート](ci_cd_analytics.md)におけるデータ集計 | [カスタムインサイトレポート](../project/insights/_index.md#dora-query-parameters)におけるデータ集計 |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| デプロイ頻度 | デプロイの成功数 | 1か月ごとの日次平均 | 日次平均 | `day`（デフォルト）または`month` |
| 変更のリード時間 | コミットを本番環境に正常に配信するまでにかかる秒数 | 1か月ごとの日次中央値 | 時間の中央値 |  `day`（デフォルト）または`month` |
| サービス復旧時間 | インシデントが開いていた秒数           | 1か月ごとの日次中央値 | 日次中央値 | `day`（デフォルト）または`month` |
| 変更失敗率 | 本番環境でインシデントを引き起こすデプロイの割合 | 1か月ごとの日次中央値 | 失敗したデプロイの割合 | `day`（デフォルト）または`month` |
