---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: カスタマイズ可能なダッシュボードで、組織全体のDevSecOpsメトリクス（DORAメトリクスや脆弱性など）を表示します。
title: バリューストリームダッシュボード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `group_analytics_dashboards_page`という名前の[フラグ付き](../../administration/feature_flags/_index.md)のクローズド[ベータ](../../policy/development_stages_support.md#beta)機能としてGitLab 15.8で導入されました。デフォルトでは無効になっています。
- `group_analytics_dashboards_page`という名前のオープン[フラグ付き](../../administration/feature_flags/_index.md)の[ベータ](../../policy/development_stages_support.md#beta)機能としてGitLab 15.11でリリースされました。デフォルトでは有効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/392734)になりました。機能フラグ`group_analytics_dashboards_page`は削除されました。
- 18.2でGitLab UltimateからGitLab Premiumに[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086)しました。

{{< /history >}}

Value Streams Dashboardは、デジタル変革の改善のためのトレンド、パターン、および機会を特定するために使用できる、カスタマイズ可能なダッシュボードです。Value Streams Dashboardの一元化されたUIは、すべての関係者が組織に関連する同じメトリクスセットにアクセスして表示できる、single source of truth（SSOT）として機能します。Value Streams Dashboardには、次のメトリクスを視覚化するパネルが含まれています:

- [DORAメトリクス](dora_metrics.md)
- [バリューストリーム分析 (VSA) - フローメトリクス](../group/value_stream_analytics/_index.md)
- [脆弱性](../application_security/vulnerability_report/_index.md)
- [GitLab Duoコード提案](../project/repository/code_suggestions/_index.md)

Value Streams Dashboardを使用すると、次のことができます:

- 以前にリストされたメトリクスを、一定期間にわたって追跡および比較します。
- 下降トレンドを早期に特定します。
- セキュリティの露出を理解します。
- 個々のプロジェクトまたはメトリクスにドリルダウンして、改善のためのアクションを実行します。
- ソフトウェア開発ライフサイクル（SDLC）へのAIの追加の影響を理解し、GitLab Duoへの投資のROIを実証します。

クリックスルーデモについては、[バリューストリーム管理製品ツアー](https://gitlab.navattic.com/vsm)を参照してください。

Value Streams Dashboardをグループの分析ダッシュボードとして表示するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **分析** > **分析ダッシュボード**を選択します。
1. 使用可能なダッシュボードのリストから、**バリューストリームダッシュボード**を選択します。

{{< alert type="note" >}}

Value Streams Dashboardに表示されるデータは、バックエンドで継続的に処理されます。Ultimateにアップグレードすると、履歴データにアクセスでき、過去のGitLabの使用状況とパフォーマンスに関するメトリクスを表示できます。

{{< /alert >}}

## パネル {#panels}

Value Streams Dashboardパネルにはデフォルトの設定がありますが、ダッシュボードパネルをカスタマイズすることもできます。

### 概要 {#overview}

{{< history >}}

- GitLab 16.7で`group_analytics_dashboard_dynamic_vsd`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439699)されました。デフォルトでは無効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)になりました。
- GitLab 17.0で機能フラグ`group_analytics_dashboard_dynamic_vsd`は[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/441206)されました。

{{< /history >}}

概要パネルは、主要なDevOpsメトリクスを視覚化することにより、トップレベルネームスペースのアクティビティーの全体像を提供します。パネルには、次のメトリクスが表示されます:

- サブグループ
- プロジェクト
- ユーザー
- イシュー
- マージリクエスト
- パイプライン

概要パネルに表示されるデータは、バッチ処理によって収集されます。GitLabは、データベース内の各サブグループのレコード数を格納し、レコード数を集計して、トップレベルのメトリクスを提供します。データは毎月、月末頃に、GitLabシステムの負荷に応じて、可能な限り集計されます。

詳細については、[エピック](https://gitlab.com/groups/gitlab-org/-/epics/10417#iterations-path)10417を参照してください。

### DevSecOpsメトリクスの比較 {#devsecops-metrics-comparison}

{{< history >}}

- GitLab.comのグループレベルでのコントリビューター数のメトリクスがGitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433353)されました。
- GitLab.comのプロジェクトレベルでのコントリビューター数のメトリクスがGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/474119)されました。
- DevSecOpsメトリクス比較テーブルがGitLab 18.5の`ai_impact_table`ビジュアライゼーションに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/541489)されました。

{{< /history >}}

DevSecOpsメトリクス比較パネルには、過去6か月間のグループまたはプロジェクトのメトリクスが表示されます。これらのビジュアライゼーションは、主要なDevSecOpsメトリクスが前月比で改善されているかどうかを理解するのに役立ちます。Value Stream Dashboardには、3つのDevSecOpsメトリクス比較パネルが表示されます:

- ライフサイクルメトリクス
- DORAメトリクス（Ultimateのみ）
- セキュリティメトリクス（Ultimateのみ、少なくとも**デベロッパー**ロール）

各比較パネルでは、次のことができます:

- グループ、プロジェクト、チーム間のパフォーマンスをひとめで比較します。
- 最大のバリューストリームコントリビューター、オーバーパフォームしている、またはアンダーパフォームしているチームとプロジェクトを特定します。
- 詳細な分析のためにメトリクスをドリルダウンします。

メトリクスにカーソルを合わせると、メトリクスの説明と、関連するドキュメントページへのリンクがツールチップに表示されます。

**Change %**列は、前月からのメトリクス値の増加または減少率も示します（6か月前と比較）。

**トレンド**列にはスパークラインが表示され、時間の経過に伴うメトリクスのトレンドのパターンを識別するのに役立ちます。スパークラインの色は青から緑の範囲で、緑は正のトレンドを示し、青は負のトレンドを示します。

### DORAパフォーマーズスコア {#dora-performers-score}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- GitLab 16.3で`dora_performers_score_panel`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386843)されました。デフォルトでは無効になっています。
- GitLab 16.9の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/439737)になりました。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/440694)になりました。機能フラグ`dora_performers_score_panel`は削除されました。

{{< /history >}}

DORAパフォーマーズスコアパネルは、グループレベルの棒チャートであり、組織のDevOpsパフォーマンスレベルのステータスを、最後の完全なカレンダー月のさまざまなプロジェクト全体で視覚化します。

![グループのDORAメトリクスを使用した棒チャート](img/vsd_dora_performers_score_v17_7.png)

このチャートは、プロジェクトのDORAスコアの内訳であり、高、中、または低として[分類](https://cloud.google.com/blog/products/devops-sre/dora-2022-accelerate-state-of-devops-report-now-out)されています。このチャートは、グループ内のすべての子プロジェクトを集計します。

このチャートのバーには、スコアカテゴリごとのプロジェクトの合計数が表示され、毎月計算されます。チャートからデータ（たとえば、**含まれていません**）を除外するには、凡例で除外するシリーズを選択します。各バーにカーソルを合わせると、スコアの定義を説明するダイアログが表示されます。

たとえば、プロジェクトのデプロイ頻度（開発速度）が高い場合、そのプロジェクトは1日に1回以上本番環境にデプロイしていることを意味します。

| メトリック                  | 高 | 中程度  | 低  | 説明 |
|-------------------------|------|---------|------|-------------|
| デプロイ頻度    | ≧30  | 1～29    | 1未満  | 1日あたりの本番環境へのデプロイ数 |
| 変更のリード時間   | ≤7   | 8～29    | ≧30  | コードのコミットから本番環境で正常に実行されるコードになるまでの日数 |
| サービス復旧時間 | ≤1   | 2～6     | ≧7   | サービスインシデントまたはユーザーに影響を与える欠陥が発生した場合のサービス復元までの日数 |
| 変更失敗率     | ≤15% | 16%～44% | ≧45% | 本番環境への変更の結果、サービスが低下した割合 |

詳細については、ブログ投稿「[GitLab Value Streams DashboardのDORAパフォーマーズスコアの内側](https://about.gitlab.com/blog/2024/01/18/inside-dora-performers-score-in-gitlab-value-streams-dashboard/)」を参照してください。

#### プロジェクトトピックでパネルをフィルタリングする {#filter-the-panel-by-project-topic}

YAML設定ファイルでダッシュボードをカスタマイズすると、割り当てられた[トピック](../project/project_topics.md)で表示されるプロジェクトをフィルタリングできます。

```yaml
panels:
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-custom-group
      filters:
        projectTopics:
          - JavaScript
          - Vue.js
```

複数のトピックが指定されている場合、プロジェクトが結果に含まれるためには、すべてのトピックが一致する必要があります。

### DORAメトリクス別のプロジェクト {#projects-by-dora-metric}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)されました。

{{< /history >}}

**Projects by DORA metric**（DORAメトリクス別のプロジェクト）パネルは、プロジェクト全体の組織のDevOpsパフォーマンスレベルのステータスをリストするグループレベルのテーブルです。

このテーブルには、グループおよびサブグループの子プロジェクトからデータを集計して、すべてのプロジェクトがDORAメトリクスとともにリストされます。このメトリクスは、最後の完全なカレンダー月について集計されます。

メトリクス値でプロジェクトをソートして、パフォーマンスの高いプロジェクト、中程度のパフォーマンスのプロジェクト、およびパフォーマンスの低いプロジェクトを特定できます。さらに調査するために、プロジェクト名を選択して、そのプロジェクトのページにドリルダウンできます。

![さまざまなプロジェクトのDORAメトリクスを含むテーブル](img/vsd_projects_dora_metrics_v17_7.png)

## 概要バックグラウンド集計の有効化または無効化 {#enable-or-disable-overview-background-aggregation}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で`value_stream_dashboard_on_off_setting`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120610)されました。デフォルトでは無効になっています。
- GitLab 16.4の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130704)になりました。
- GitLab 16.6で[機能フラグ`value_stream_dashboard_on_off_setting`が削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134619)されました。

{{< /history >}}

Value Streams Dashboardの概要カウント集計を有効または無効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **分析**を選択します。
1. **バリューストリームダッシュボード**で、**バリューストリームダッシュボードの概要画面のバックグラウンドでの集計を有効にする**の概要画面のバックグラウンドでの集計を有効にする]チェックボックスを選択またはクリアします。

グループ内の集計された使用状況カウントを取得するには、[GraphQL API](../../api/graphql/reference/_index.md#groupvaluestreamdashboardusageoverview)を使用します。

## Value Streams Dashboardの表示 {#view-the-value-streams-dashboard}

前提要件:

- グループまたはプロジェクトに対するレポーター以上のロールが必要です。
- 概要バックグラウンド集計を有効にする必要があります。
- 比較パネルでコントリビューター数のメトリクスを表示するには、[ClickHouseを設定](../../integration/clickhouse.md)する必要があります。
- 本番環境へのデプロイを追跡するには、グループまたはプロジェクトに[本番環境へのデプロイ階層](../../ci/environments/_index.md#deployment-tier-of-environments)の環境が必要です。
- サイクルタイムを測定するには、[イシューがコミットメッセージからクロスリンクされている](../../user/project/issues/crosslinking_issues.md#from-commit-messages)必要があります。

### グループの場合 {#for-groups}

グループのValue Streams Dashboardを表示するには:

- 分析ダッシュボードから:

  1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
  1. **分析** > **分析ダッシュボード**を選択します。

- バリューストリーム分析から:

  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
  1. **分析** > **バリューストリーム分析**を選択します。
  1. **結果をフィルタリング**テキストボックスの下の**ライフサイクルメトリクス**行で、**Value Streams Dashboard / DORA**（バリューストリームダッシュボード） / DORA]を選択します。
  1. オプション。新しいページを開くには、このパス`/analytics/dashboards/value_streams_dashboard`をグループURL（たとえば、`https://gitlab.com/groups/gitlab-org/-/analytics/dashboards/value_streams_dashboard`）に追加します。

### プロジェクトの場合 {#for-projects}

{{< history >}}

- GitLab 16.7で`project_analytics_dashboard_dynamic_vsd`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137483)されました。デフォルトでは無効になっています。
- 機能フラグ`project_analytics_dashboard_dynamic_vsd`は、GitLab 17.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/441207)されました。

{{< /history >}}

Value Streams Dashboardをプロジェクトの分析ダッシュボードとして表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **分析** > **分析ダッシュボード**を選択します。
1. 使用可能なダッシュボードのリストから、**バリューストリームダッシュボード**を選択します。

## レポートのスケジュール {#schedule-reports}

CI/CDコンポーネント[バリューストリームダッシュボードスケジュールされたレポートツール](https://gitlab.com/components/vsd-reports-generator)を使用して、レポートをスケジュールできます。このツールを使用すると、関連データを含む適切なダッシュボードを手動で検索する必要がなくなるため、時間と労力を節約し、インサイトの分析に集中できます。レポートをスケジュールすることで、組織の意思決定者が、プロアクティブでタイムリーかつ関連性の高い情報を受け取ることができるようにします。

スケジュールされたレポートツールは、パブリックGitLab GraphQL APIを介してプロジェクトまたはグループからメトリクスを収集し、GitLab Flavored Markdownを使用してレポートをビルドし、指定されたプロジェクトでイシューを開きます。このイシューには、Markdown形式の比較メトリクステーブルが含まれています。

[スケジュールされたレポートの例](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report)を参照してください。詳細については、ブログ記事「[新しいスケジュールされたレポート生成ツールがバリューストリーム管理を簡素化](https://about.gitlab.com/blog/2024/06/20/new-scheduled-reports-generation-tool-simplifies-value-stream-management/)」を参照してください。

## ダッシュボードパネルのカスタマイズ {#customize-dashboard-panels}

Value Streams Dashboardをカスタマイズして、ページに含めるサブグループとプロジェクトを設定できます。

ページのデフォルトコンテンツをカスタマイズするには、選択したプロジェクトでYAML設定ファイルを作成する必要があります。このファイルでは、タイトル、説明、パネル数など、さまざまな設定とパラメータを定義できます。このファイルは、スキーマ駆動型であり、Gitなどのバージョン管理システムで管理されます。これにより、設定変更の履歴の追跡と維持、必要に応じて以前のバージョンへの復元、およびチームメンバーとの効果的なコラボレーションが可能になります。クエリパラメータを使用して、YAML設定をオーバーライドすることもできます。

ダッシュボードパネルをカスタマイズする前に、YAML設定ファイルを格納するプロジェクトを選択する必要があります。

前提要件:

- グループのメンテナーロール以上を持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **分析**を選択します。
1. YAML設定ファイルを保存するプロジェクトを選択します。
1. **変更を保存**を選択します。

プロジェクトを設定したら、設定ファイルを設定します:

1. 左側のサイドバーで、**検索または移動先**を選択し、前の手順で選択したプロジェクトを見つけます。
1. デフォルトのブランチに、設定ファイル`.gitlab/analytics/dashboards/value_streams/value_streams.yaml`を作成します。
1. `value_streams.yaml`設定ファイルで、設定オプションを入力します:

| フィールド                                      | 説明 |
|--------------------------------------------|-------------|
| `title`                                    | パネルのカスタム名 |
| `queryOverrides`（以前は`data`）         | 各ビジュアライゼーションに固有のデータクエリパラメータをオーバーライドします。 |
| `namespace`（`queryOverrides`のサブフィールド） | パネルに使用するグループまたはプロジェクトパス |
| `filters`（`queryOverrides`のサブフィールド）   | サポートされている各ビジュアライゼーションタイプのクエリをフィルタリングします。 |
| `visualization`                            | レンダリングされるビジュアライゼーションのタイプ。サポートされているオプションは、`ai_impact_table`、`dora_performers_score`、および`usage_overview`です。 |
| `gridAttributes`                           | パネルのサイズと配置 |
| `xPos`（`gridAttributes`のサブフィールド）      | パネルの水平方向の位置 |
| `yPos`（`gridAttributes`のサブフィールド）      | パネルの垂直方向の位置 |
| `width`（`gridAttributes`のサブフィールド）     | パネルの幅（最大12） |
| `height`（`gridAttributes`のサブフィールド）    | パネルの高さ |

```yaml
# version - The latest version of the analytics dashboard schema
version: '2'

# title - Change the title of the Value Streams Dashboard.
title: 'Custom Dashboard title'

# description - Change the description of the Value Streams Dashboard. [optional]
description: 'Custom description'

# panels - List of panels that contain panel settings.
#   title - Change the title of the panel.
#   visualization - The type of visualization to be rendered
#   gridAttributes - The size and positioning of the panel
#   queryOverrides.namespace - The Group or Project path to use for the chart panel
#   queryOverrides.filters.excludeMetrics - Hide rows by metric ID from the chart panel.
panels:
  - title: 'Group usage overview'
    visualization: usage_overview
    queryOverrides:
      namespace: group
      filters:
        include:
          - groups
          - projects
    gridAttributes:
      yPos: 1
      xPos: 1
      height: 1
      width: 12
  - title: 'Group dora and issue metrics'
    visualization: ai_impact_table
    queryOverrides:
      namespace: group
      filters:
        excludeMetrics:
          - deployment_frequency
          - deploys
    gridAttributes:
      yPos: 2
      xPos: 1
      height: 12
      width: 12
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-project
      filters:
        projectTopics:
          - ruby
          - javascript
    gridAttributes:
      yPos: 26
      xPos: 1
      height: 12
      width: 12
```

### サポートされているビジュアライゼーションフィルター {#supported-visualization-filters}

`queryOverrides`フィールドの`filters`サブフィールドを使用して、パネルに表示されるデータをカスタマイズできます。

#### DevSecOpsメトリクス比較パネルフィルター {#devsecops-metrics-comparison-panel-filters}

`ai_impact_table`ビジュアライゼーションのフィルター。

| フィルター           | 説明                                  | サポートされている値: |
|------------------|----------------------------------------------|------------------|
| `excludeMetrics` | チャートパネルからメトリクスIDで列を非表示にします | `deployment_frequency`、`lead_time_for_changes`、`time_to_restore_service`、`change_failure_rate`、`lead_time`、`cycle_time`、`issues`、`issues_completed`、`deploys`、`merge_request_throughput`、`median_time_to_merge`、`contributor_count`、`vulnerability_critical`、`vulnerability_high`、`pipeline_count`、`pipeline_success_rate`、`pipeline_failed_rate`、`pipeline_duration_median`、`code_suggestions_usage_rate`、`code_suggestions_acceptance_rate`、`duo_chat_usage_rate`、`duo_rca_usage_rate` |

#### DORAパフォーマーズスコアパネルフィルター {#dora-performers-score-panel-filters}

`dora_performers_score`ビジュアライゼーションのフィルター。

| フィルター          | 説明                                                                               | サポートされている値: |
|-----------------|-------------------------------------------------------------------------------------------|------------------|
| `projectTopics` | 割り当てられたトピックに基づいて表示されるプロジェクトをフィルタリングします | 利用可能なグループトピック |

#### 使用状況の概要パネルフィルター {#usage-overview-panel-filters}

`usage_overview`ビジュアライゼーションのフィルター。

##### グループおよびサブグループのネームスペース {#group-and-subgroup-namespaces}

| フィルター    | 説明                                                    | サポートされている値: |
|-----------|----------------------------------------------------------------|------------------|
| `include` | 返されるメトリクスを制限します。デフォルトでは、利用可能なすべてのメトリクスが表示されます | `groups`、`projects`、`issues`、`merge_requests`、`pipelines`、`users` |

##### プロジェクトネームスペース {#project-namespaces}

| フィルター    | 説明                                                    | サポートされている値: |
|-----------|----------------------------------------------------------------|------------------|
| `include` | 返されるメトリクスを制限します。デフォルトでは、利用可能なすべてのメトリクスが表示されます | `issues`、`merge_requests`、`pipelines` |

#### 追加のパネルフィルター（非推奨） {#additional-panel-filters-deprecated}

{{< alert type="warning" >}}

`dora_chart`の可視化は、GitLab 18.5で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206417)になりました。

{{< /alert >}}

`dora_chart`の可視化のためのフィルター。

| フィルター   | 説明                                  | サポートされている値: |
|----------|----------------------------------------------|------------------|
| `labels` | ラベルでデータをフィルター                       | 利用可能な任意のグルーラベルプ。ラベルによるフィルタリングは、次のメトリクスでサポートされています：`lead_time`、`cycle_time`、`issues`、`issues_completed`、`merge_request_throughput`、`median_time_to_merge`。 |

## ダッシュボードのメトリクスとドリルダウンレポート {#dashboard-metrics-and-drill-down-reports}

次の表は、バリューストリームダッシュボードで利用可能なメトリクスの概要と、説明、ドリルダウンレポートの名前を示しています。

| メトリック | 説明 | ドリルダウンレポート | ID |
| ------ | ----------- | ----------------- | -- |
| デプロイ頻度 | 1日あたりの本番環境へのデプロイの平均数。このメトリクスは、エンドユーザーにどのくらいの頻度で価値が提供されているかを測定します。 | **デプロイ頻度**タブ | `deployment_frequency` |
| 変更のリード時間 | コミットを本番環境に正常にデプロイするまでの時間。このメトリクスは、CI/CDパイプラインの効率性を反映しています。 | **リードタイム**タブ | `lead_time_for_changes` |
| サービス復旧時間 | 本番環境での障害から組織が回復するまでにかかる時間。 | **平均復旧時間**タブ | `time_to_restore_service` |
| 変更失敗率 | 本番環境でインシデントを引き起こすデプロイの割合。 | **変更失敗率**タブ | `change_failure_rate` |
| リードタイム | イシューの作成からクローズまでの中央値時間。 | バリューストリーム分析 | `lead_time` |
| サイクルタイム | リンクされたイシューのマージリクエストの最初のコミットから、そのイシューがクローズされるまでの中央値時間。 | **ライフサイクルメトリクス**の「ライフサイクルメトリクス」セクション | `cycle_time` |
| イシューの作成 | 作成された新しいイシューの数。 | イシュー分析 | `issues` |
| イシューのクローズ | 月ごとのイシューのクローズ数。 | イシュー分析 | `issues_completed` |
| デプロイ数 | 本番環境へのデプロイの総数。 | マージリクエスト分析 | `deploys` |
| マージリクエストスループット | 月ごとのマージリクエストのマージ数。 | 生産性分析 | `merge_request_throughput` |
| マージまでの中央値時間 | マージリクエストの作成からマージリクエストのマージまでの中央値時間。 | 生産性分析 | `median_time_to_merge` |
| コントリビューター数 | グループ内でコントリビュートしている月間ユニークユーザー数。 | コントリビュート分析 | `contributor_count` |
| 経時的なクリティカルな脆弱性 | プロジェクトまたはグループにおける、経時的なクリティカルな脆弱性 | 脆弱性レポート | `vulnerability_critical` |
| 経時的な高い脆弱性 | プロジェクトまたはグループにおける、経時的な高い脆弱性 | 脆弱性レポート | `vulnerability_high` |
| 合計パイプライン実行数 | 選択した期間に実行されたパイプラインの合計数。 | CI/CDの分析 | `pipeline_count` |
| パイプラインの中央値期間 | パイプラインが完了するまでにかかる中央値時間。 | CI/CDの分析 | `pipeline_duration_median` |
| パイプラインの成功率 | 正常に完了したパイプラインの割合。 | CI/CDの分析 | `pipeline_success_rate` |
| パイプラインの失敗率 | 失敗したパイプラインの割合。 | CI/CDの分析 | `pipeline_failed_rate` |
| コード提案の利用状況 | 少なくとも1つのDuo機能を使用した、割り当てられたDuoシートを持つユーザー。 |  | `code_suggestions_usage_rate` |
| コード提案の承認率 | 生成されたコード提案の合計数から承認されたコード提案数。 |  | `code_suggestions_acceptance_rate` |
| Duoチャットの利用状況 | Duoチャットを使用した、割り当てられたDuoシートを持つユーザー。 |  | `duo_chat_usage_rate` |
| Duo根本原因分析の利用状況 | 根本原因分析を使用した、割り当てられたDuoシートを持つユーザー。 |  | `duo_rca_usage_rate` |

## Jiraとのメトリクス {#metrics-with-jira}

次のメトリクスは、Jiraの使用に依存しません:

- デプロイ頻度
- 変更のリードタイム
- デプロイ数
- マージリクエストスループット
- マージまでの中央値時間
- 脆弱性
