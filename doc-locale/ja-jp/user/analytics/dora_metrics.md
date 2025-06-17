---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DevOps Research and Assessment（DORA）メトリクス
---

{{< details >}}

- プラン:Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[DevOps Research and Assessment（DORA）](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)メトリクスは、DevOpsのパフォーマンスに関するエビデンスに基づいたインサイトを提供します。これら4つの主要な測定値は、チームが変更をどれだけ迅速にデリバリーし、それらの変更が本番環境でどれだけうまく機能するかを示しています。DORAメトリクスを継続的に追跡すると、ソフトウェアデリバリープロセス全体の改善機会が明確になります。

DORAメトリクスを使用して戦略的な意思決定を行い、ステークホルダーへのプロセス改善投資を正当化したり、チームのパフォーマンスを業界のベンチマークと比較して競争上の優位性を特定したりできます。

4つのDORAメトリクスは、DevOpsの2つの重要な側面を測定します。

- **ベロシティメトリクス**: 組織がソフトウェアをどれだけ迅速にデリバリーするかを追跡します:
  - [デプロイ頻度](#deployment-frequency):コードが本番環境にデプロイされる頻度
  - [変更のリード時間](#lead-time-for-changes):コードが本番環境に到達するまでにかかる時間

- **安定性メトリクス**: ソフトウェアの信頼性を測定します:
  - [変更失敗率](#change-failure-rate):デプロイによって本番環境の障害がどのくらいの頻度で発生するか
  - [サービス復旧時間](#time-to-restore-service):障害後にサービスがどのくらいの速さで復旧するか

ベロシティと安定性の両方のメトリクスに焦点を当てることで、リーダーはデリバリーワークフローにおけるスピードと品質の最適なバランスを見つけることができます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 動画での解説については、[DORAメトリクスをご覧ください:ユーザー分析](https://www.youtube.com/watch?v=jYQSH4EY6_U) と [GitLab のスピード実行:DORAメトリクス](https://www.youtube.com/watch?v=1BrcMV6rCDw)。

## デプロイ頻度

{{< history >}}

- [導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/394712)、GitLab 16.0の`all` および `monthly`間隔の頻度計算式の修正。

{{< /history >}}

デプロイ頻度とは、指定された日付範囲（時間単位、日単位、週単位、月単位、または年単位）における本番環境へのデプロイの成功頻度です。

ソフトウェアリーダーは、デプロイ頻度のメトリクスを使用して、チームがソフトウェアを本番環境にどれだけ頻繁に正常にデプロイしているか、またチームが顧客のリクエストや新しい市場機会にどれだけ迅速に対応できるかを理解できます。デプロイ頻度が高いということは、フィードバックをより早く得て、より迅速にイテレーションを行い改善や機能を提供できることを意味します。

### デプロイ頻度の予測

{{< details >}}

- プラン:Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated
- 状態:実験

{{< /details >}}

デプロイ頻度の予測（以前はバリューストリーム予測と呼ばれていました）は、統計的予測モデルを使用して、生産性メトリクスを予測し、ソフトウェア開発ライフサイクル全体のアノマリを特定します。この情報は、製品およびチームの計画と意思決定を改善するのに役立ちます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [バリューストリーム予測](https://www.youtube.com/watch?v=6u8_8QQ5pEQ&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)の概要をご覧ください。

### デプロイ頻度の計算方法

GitLabでは、デプロイ頻度は、指定された環境への1日あたりの平均デプロイ数として測定され、デプロイの終了時間（`finished_at`プロパティ）に基づいています。GitLabは、指定された日の完了したデプロイの数からデプロイ頻度を計算します。成功したデプロイ（`Deployment.statuses = success`）のみがカウントされます。

計算では、本番環境`environment tier`または`production/prod`という名前の環境が考慮されます。デプロイメント情報がグラフに表示されるためには、環境が本番環境のデプロイメントプランの一部である必要があります。

[`.gitlab/insights.yml`ファイル](../project/insights/_index.md#insights-configuration-file)の`environment_tiers`パラメーターで`other`を指定することにより、さまざまな環境のDORAメトリクスを Configure できます。

{{< alert type="note" >}}

デプロイ頻度は**平均値**として計算されます。他のDORAメトリクスは中央値を使用します。これは、より正確で信頼性の高いパフォーマンスのビューを提供するため推奨されます。この違いは、デプロイ頻度がDORAフレームワークを採用する前にGitLabに追加されたためであり、このメトリクスの計算は他のレポートに組み込まれたときにも変更されなかったためです。[イシュー 499591](https://gitlab.com/gitlab-org/gitlab/-/issues/499591)では、各メトリクスの計算方法をカスタマイズし、平均値と中央値を選択するオプションを提供することを提案しています。

{{< /alert >}}

### デプロイ頻度を改善する方法

最初の手順は、グループとプロジェクト間のコードリリースのケイデンスをベンチマークすることです。次に、以下を検討する必要があります:

- 自動Testの追加。
- 自動コード検証の追加。
- 変更をより小さなイテレーションに分割する。

## 変更のリード時間

変更のリード時間とは、コードの変更が本番環境に入るまでにかかる時間です。

**変更のリード時間**は、**リードタイム**と同じではありません。バリューストリーム分析では、リードタイムは、イシューに関する作業がリクエストされた瞬間（イシューの作成）から、その作業が完了してデリバリーされた瞬間（イシューの完了）までに要する時間を測定します。

ソフトウェアリーダーにとって、変更のリード時間はCI/CDパイプラインの効率性を反映し、作業が顧客にどれだけ迅速にデリバリーされるかを視覚化します。時間の経過とともに、変更のリード時間は短縮され、チームのパフォーマンスは向上するはずです。変更のリード時間が短いということは、CI/CDパイプラインがより効率的であることを意味します。

### 変更のリード時間の計算方法

GitLabは、マージリクエストが本番環境に正常にデリバリーされるまでにかかる時間（マージリクエストのマージ時間（マージボタンがクリックされたとき）から、コードが本番環境で正常に実行されるまで）に基づいて変更のリード時間を計算し、計算に`coding_time`を追加しません。データは、デプロイが完了した直後に集約されますが、わずかな遅延があります。

デフォルトでは、変更のリード時間は、複数のデプロイメントジョブを持つ1つのブランチ操作のみの測定をサポートします（たとえば、デフォルトブランチでの開発からステージング、本番環境まで）。マージリクエストがステージングでマージされ、次に本番環境でマージされる場合、GitLabはそれらを1つではなく、2つのデプロイされたマージリクエストとして解釈します。

### 変更のリード時間を改善する方法

最初の手順は、グループとプロジェクト間のCI/CDパイプラインの効率性をベンチマークすることです。次に、以下を検討する必要があります:

- バリューストリーム分析を使用して、プロセスにおけるボトルネックを特定する。
- 変更をより小さなイテレーションに分割する。
- 自動化の追加。
- パイプラインのパフォーマンスの改善。

## サービス復旧時間

サービス復旧時間とは、組織が本番環境の障害から回復するまでにかかる時間です。

ソフトウェアリーダーにとって、サービス復旧時間は、組織が本番環境の障害から回復するまでにかかる時間を反映します。サービス復旧時間が短いということは、組織が競争上の優位性を高め、ビジネス成果を向上させるために、新しい革新的な機能をリスクを冒して導入できることを意味します。

### サービス復旧時間の計算方法

GitLabでは、サービス復旧時間は、本番環境でインシデントがオープンになっていた時間の中央値として測定されます。GitLabは、指定された期間に本番環境でインシデントがオープンになっていた秒数を計算します。これは以下を前提としています:

- [GitLabインシデント](../../operations/incident_management/incidents.md)が追跡されている。
- すべてのインシデントは、環境に関係なく、本番環境に関連しています。
- インシデントとデプロイメントは、厳密に1対1の関係にあります。インシデントは1つの本番環境デプロイメントにのみ関連付けられ、本番環境デプロイメントは1つ以下のインシデントに関連付けられます。

### サービス復旧時間を改善する方法

最初の手順は、グループとプロジェクトの間で、サービスの停止および停止からのチームの対応と復旧をベンチマークすることです。次に、以下を検討する必要があります:

- 本番環境への可観測性を向上させる。
- 対応ワークフローの改善。
- 修正をより効率的に本番環境に導入できるように、デプロイ頻度と変更のリード時間を改善する。

## 変更失敗率

変更失敗率とは、変更によって本番環境で障害が発生する頻度です。

ソフトウェアリーダーは、変更失敗率のメトリクスを使用して、出荷されるコードの品質に関するインサイトを得ることができます。変更失敗率が高い場合は、非効率的なデプロイプロセス、または自動テストカバレッジの不足を示している可能性があります。

### 変更失敗率の計算方法

GitLabでは、変更失敗率は、指定された期間に本番環境でインシデントを引き起こすデプロイの割合として測定されます。GitLabは、変更失敗率を、本番環境へのインシデント数を除算したデプロイメント数として計算します。この計算は以下を前提としています:

- [GitLabインシデント](../../operations/incident_management/incidents.md)が追跡されている。
- すべてのインシデントは、環境に関係なく、本番環境のインシデントです。
- 変更失敗率は、主に高レベルの安定性の追跡として使用されます。そのため、特定の日には、すべてのインシデントとデプロイは結合された日次レートに集約されます。[イシュー 444295](https://gitlab.com/gitlab-org/gitlab/-/issues/444295)では、デプロイとインシデント間の特定のリレーションシップを追加することを提案しています。
- 変更失敗率では、重複するインシデントが個別のエントリとして計算されるため、二重カウントが発生します。[イシュー 480920](https://gitlab.com/gitlab-org/gitlab/-/issues/480920)では、より正確な計算のためのソリューションを提案しています。

たとえば、10回のデプロイ（1日あたり1回のデプロイを考慮）があり、最初の日に2つのインシデント、最後の日に1つのインシデントがある場合、変更失敗率は0.3になります。

### 変更失敗率を改善する方法

最初の手順は、グループとプロジェクトの間で、品質と安定性をベンチマークすることです。次に、以下を検討する必要があります:

- 安定性とスループット（デプロイ頻度と変更のリード時間）の適切なバランスを見つけ、スピードのために品質を犠牲にしない。
- コードレビュープロセスの有効性を改善する。
- 自動Testの追加。

## DORAカスタム計算ルール

{{< details >}}

- プラン:Ultimate
- 提供:GitLab Self-Managed
- 状態:実験

{{< /details >}}

{{< history >}}

- GitLab 15.4 で`dora_configuration`という名前の[フラグで](../../administration/feature_flags.md) [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561)されました。デフォルトでは無効になっています。この機能は[実験](../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

この機能は[実験](../../policy/development_stages_support.md)です。この機能を Test しているユーザーのリストに参加するには、[提案されたテストフローはこちら](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561#steps-to-check-on-localhost)。バグを見つけた場合は、[こちらでイシューをオープンしてください](https://gitlab.com/groups/gitlab-org/-/epics/11490)。ユースケースとフィードバックを共有するには、[エピック 11490](https://gitlab.com/groups/gitlab-org/-/epics/11490)にコメントしてください。

### 変更のリード時間に対するマルチブランチルール

デフォルトの[変更のリード時間の計算](#how-lead-time-for-changes-is-calculated)とは異なり、この計算ルールを使用すると、操作ごとに単一のデプロイジョブを使用してマルチブランチ操作を測定できます。たとえば、開発ブランチの開発ジョブから、ステージブランチのステージジョブ、本番環境のブランチの本番環境ジョブまでです。

この計算ルールは、開発フローの一部であるターゲットブランチで`dora_configurations`テーブルを更新することで実装されました。これにより、GitLabはブランチを1つとして認識し、他のマージリクエストを除外できます。

この設定により、選択したプロジェクトの日次DORAメトリクスの計算方法が変更されますが、他のプロジェクト、グループ、またはユーザーには影響しません。

この機能は、プロジェクトレベルの伝播のみをサポートします。

これを行うには、Railsコンソールで次のコマンドを実行します:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
Dora::Configuration.create!(project: my_project, branches_for_lead_time_for_changes: ['master', 'main'])
```

既存の設定を更新するには、次のコマンドを実行します:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
record = Dora::Configuration.where(project: my_project).first
record.branches_for_lead_time_for_changes = ['development', 'staging', 'master', 'main']
record.save!
```

## DORAメトリクスの測定

### GitLab CI/CDパイプラインを使用しない場合

デプロイ頻度は、一般的なプッシュベースのデプロイ用に作成されたデプロイレコードに基づいて計算されます。これらのデプロイレコードは、プルベースのデプロイでは作成されません。たとえば、コンテナイメージがエージェントを使用してGitLabに接続されている場合などです。

このような場合にDORAメトリクスを追跡するには、Deployments APIを使用して[デプロイレコードを作成する](../../api/deployments.md#create-a-deployment)ことができます。デプロイプランがConfigureされている環境名を指定する必要があります。これは、プラン変数がデプロイメントではなく、指定された環境に対して指定されているためです。詳細については、[外部デプロイツールのデプロイを追跡する](../../ci/environments/external_deployment_tools.md)方法を参照してください。

### Jiraを使用

- デプロイ頻度と変更のリード時間は、GitLab CI/CDとマージリクエスト（MR）に基づいて計算され、Jiraデータを必要としません。
- サービス復旧時間と変更失敗率を計算するには、[GitLabインシデント](../../operations/incident_management/manage_incidents.md)が必要です。詳細については、これらのメトリクスを[外部インシデントとともに](#with-external-incidents)測定する方法と、[Jiraインシデントレプリケーターガイド](https://gitlab.com/smathur/jira-incident-replicator)を参照してください。

### 外部インシデントを使用

インシデント管理のサービス復旧時間と変更失敗率を測定できます。

PagerDutyの場合、[Webhookを設定](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook)して、各PagerDutyインシデントに対してGitLabインシデントを自動的に作成できます。この設定では、PagerDutyとGitLabの両方で変更を行う必要があります。

他のインシデント管理ツールの場合、[HTTPインテグレーション](../../operations/incident_management/integrations.md#http-endpoints)を設定して、次のことを自動的に行うことができます:

1. [アラートがトリガーされたときにインシデントを作成する](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered)。
1. [リカバリーアラートを介してインシデントをクローズする](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts)。

## 分析機能

DORAメトリクスは、次の分析機能に表示されます:

- [バリューストリームダッシュボード](value_streams_dashboard.md)には、[DORAメトリクスの比較パネル](value_streams_dashboard.md#devsecops-metrics-comparison)と[DORAパフォーマーズスコアパネル](value_streams_dashboard.md#dora-performers-score)が含まれています。
- [CI/CD分析チャート](ci_cd_analytics.md)には、時間の経過に伴うDORAメトリクスの履歴が表示されます。
- [インサイトレポート](../project/insights/_index.md)は、[DORAクエリパラメーター](../project/insights/_index.md#dora-query-parameters)を使用してカスタムチャートを作成するオプションを提供します。
- [GraphQL API](../../api/graphql/reference/_index.md)（インタラクティブな[GraphQLエクスプローラー](../../api/graphql/_index.md#interactive-graphql-explorer)付き）と[REST API](../../api/dora/metrics.md)は、メトリクスデータの取得をサポートしています。

## プロジェクトとグループの可用性

次のテーブルは、プロジェクトおよびグループにおけるDORAメトリクスの可用性の概要を示しています。

| メトリクス                    | レベル             | コメント |
|---------------------------|-------------------|----------|
| `deployment_frequency`    | プロジェクト           | デプロイ数の単位。 |
| `deployment_frequency`    | グループ             | デプロイ数の単位。集計方法は平均です。  |
| `lead_time_for_changes`   | プロジェクト           | 単位は秒。集計方法は中央値です。 |
| `lead_time_for_changes`   | グループ             | 単位は秒。集計方法は中央値です。 |
| `time_to_restore_service` | プロジェクトとグループ | 単位は日。集計方法は中央値です。（GitLab 15.1以降のUIチャートで利用可能） |
| `change_failure_rate`     | プロジェクトとグループ | デプロイの割合。（GitLab 15.2以降のUIチャートで利用可能） |

## データ集約

次の表は、さまざまなチャートにおけるDORAメトリクスのデータ集約の概要を示しています。

| メトリクス名 | 測定値 | [バリューストリームダッシュボード](value_streams_dashboard.md)におけるデータ集約 | [CI/CD分析チャート](ci_cd_analytics.md)におけるデータ集約 | [カスタムインサイトレポート](../project/insights/_index.md#dora-query-parameters)におけるデータ集約 |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| デプロイ頻度 | デプロイの成功数 | 1か月あたりの1日の平均 | 1日の平均 | `day`（デフォルト）または`month` |
| 変更のリード時間 | コミットを本番環境に正常に配信するまでにかかる秒数 | 1か月あたりの1日の中央値 | 中央値 |  `day`（デフォルト）または`month` |
| サービス復旧時間 | インシデントが開いていた秒数           | 1か月あたりの1日の中央値 | 1日の平均値 | `day`（デフォルト）または`month` |
| 変更失敗率 | 本番環境でインシデントを引き起こすデプロイの割合 | 1か月あたりの1日の中央値 | 失敗したデプロイの割合 | `day`（デフォルト）または`month` |
