---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 分析ダッシュボード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [実験的機能](../../policy/development_stages_support.md#experiment)としてGitLab 15.9で`combined_analytics_dashboards`という名前の[フラグ付き](../../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。
- `combined_analytics_dashboards` GitLab 16.11で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/389067)になりました。
- `combined_analytics_dashboards`はGitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454350)されました。
- `filters`設定がGitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505317)されました。デフォルトでは無効になっています。
- インラインのビジュアライゼーション設定がGitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/509111)されました。
- 18.2で[移動](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086)しました。

{{< /history >}}

分析ダッシュボードを使用すると、収集されたデータを組み込みのダッシュボードで視覚化できます。

ダッシュボードの拡張されたエクスペリエンスは、[エピック13801](https://gitlab.com/groups/gitlab-org/-/epics/13801)で提案されています。

## データソース {#data-sources}

{{< history >}}

- プロダクト分析とカスタムビジュアライゼーションデータソースは、GitLab 17.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/497577)されました。

{{< /history >}}

データソースとは、ダッシュボードのフィルターとビジュアライゼーションが結果をクエリして取得するために使用できる、データベースまたはデータのコレクションへの接続です。

## 組み込みダッシュボード {#built-in-dashboards}

分析をすぐに開始できるように、GitLabには事前定義されたビジュアライゼーションを備えた組み込みダッシュボードが用意されています。これらのダッシュボードには、**By GitLab**（By GitLab）というラベルが付けられています。組み込みダッシュボードを編集することはできませんが、同様のスタイルでカスタムダッシュボードを作成できます。

次の組み込みダッシュボードを使用できます:

- [**バリューストリームダッシュボード**](value_streams_dashboard.md)は、DevOpsのパフォーマンス、セキュリティの露出、ワークストリームの最適化に関連するメトリクスを表示します。
- [**GitLab Duo and SDLC trends**（GitLab DuoとSDLCのトレンド）](duo_and_sdlc_trends.md)は、プロジェクトまたはグループのソフトウェア開発ライフサイクル（SDLC）メトリクスに対するAIツールの影響を表示します。
- [**DORA Metrics Dashboard**（DORAメトリクスダッシュボード）](dora_metrics_charts.md)は、各DORAメトリクスの時間的変化を表示します。
- [**マージリクエスト分析**](merge_request_analytics.md)は、マージリクエストのスループットとマージまでの平均時間のメトリクスを表示します。

## カスタムダッシュボード {#custom-dashboards}

お客様のケースに最も関連性の高いメトリクスを視覚化するために、[カスタムダッシュボードを作成する](#create-a-dashboard-by-configuration)ことができます。

- 各プロジェクトには、無制限の数のダッシュボードを設定できます。唯一の制限は、[リポジトリサイズの制限](../project/repository/repository_size.md#size-and-storage-limits)である可能性があります。
- 各ダッシュボードは、1つ以上の[ビジュアライゼーション](#define-a-chart-visualization-template)を参照できます。
- ビジュアライゼーションは、ダッシュボード間で共有できます。

プロジェクトのメンテナーは、[コードオーナー](../project/codeowners/_index.md)や[承認ルール](../project/merge_requests/approvals/rules.md)などの機能を使用して、ダッシュボードの変更に対する承認ルールを適用できます。ダッシュボードファイルは、プロジェクトのコードの残りの部分とともに、ソース管理でバージョニングされます。

## プロジェクトダッシュボードを表示 {#view-project-dashboards}

前提要件:

- プロジェクトのレポーターロール以上が必要です。

プロジェクトのダッシュボード（組み込みとカスタムの両方）のリストを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**分析** > **分析ダッシュボード**を選択します。
1. 利用可能なダッシュボードのリストから、表示するダッシュボードを選択します。

## グループダッシュボードを表示 {#view-group-dashboards}

{{< history >}}

- GitLab 16.2で`group_analytics_dashboards`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390542)されました。デフォルトでは無効になっています。
- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/416970)になりました。
- `group_analytics_dashboards`機能フラグはGitLab 16.11で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/439718)されました。

{{< /history >}}

前提要件:

- グループのレポーターロール以上が必要です。

グループのダッシュボード（組み込みとカスタムの両方）のリストを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**分析** > **分析ダッシュボード**を選択します。
1. 利用可能なダッシュボードのリストから、表示するダッシュボードを選択します。

## ダッシュボードの場所を変更 {#change-the-location-of-dashboards}

プロジェクトまたはグループのカスタムダッシュボードの場所を変更できます。

前提要件:

- ダッシュボードが属するプロジェクトまたはグループに対してメンテナーロール以上を持っている必要があります。

### グループダッシュボード {#group-dashboards}

{{< alert type="note" >}}

[イシュー411572](https://gitlab.com/gitlab-org/gitlab/-/issues/411572)は、この機能をグループレベルのダッシュボードに接続することを提案しています。

{{< /alert >}}

グループのカスタムダッシュボードの場所を変更するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択し、ダッシュボードファイルを保存するプロジェクトを見つけます。そのプロジェクトは、ダッシュボードを作成するグループに属している必要があります。
1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **分析**を選択します。
1. **分析ダッシュボード**セクションで、ダッシュボードファイルプロジェクトを選択します。
1. **変更を保存**を選択します。

### プロジェクトダッシュボード {#project-dashboards}

デフォルトでは、カスタムダッシュボードは現在のプロジェクトに保存されます。これは、ダッシュボードが通常、分析データの取得元となるプロジェクトで定義されるためです。ただし、ダッシュボード用に別のプロジェクトを用意することもできます。このセットアップは、ダッシュボード定義に特定のアクセスルールを適用したり、複数のプロジェクト間でダッシュボードを共有したりする場合に推奨されます。

{{< alert type="note" >}}

ダッシュボードを共有できるのは、同じグループ内にあるプロジェクト間のみです。

{{< /alert >}}

プロジェクトのダッシュボードの場所を変更するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択してプロジェクトを見つけるか、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択して、ダッシュボードファイルを保存するプロジェクトを作成します。
1. 左側のサイドバーで、**検索または移動先**を選択して、分析プロジェクトを見つけます。
1. **設定** > **分析**を選択します。
1. **分析ダッシュボード**セクションで、ダッシュボードファイルプロジェクトを選択します。
1. **変更を保存**を選択します。

## 構成によるダッシュボードの作成 {#create-a-dashboard-by-configuration}

設定でダッシュボードを手動で作成できます。

ダッシュボードを定義するには:

1. `.gitlab/analytics/dashboards/`で、ダッシュボードのように名前を付けたディレクトリを作成します。

   各ダッシュボードには、独自のディレクトリが必要です。
1. 新しいディレクトリに、`.yaml`ファイルを作成します（例：`.gitlab/analytics/dashboards/my_dashboard/my_dashboard.yaml`）。

   このファイルには、ダッシュボードの定義が含まれています。これは、`ee/app/validators/json_schemas/analytics_dashboard.json`で定義されたJSONスキーマに準拠している必要があります。
1. オプション。ダッシュボードに追加する新しいビジュアライゼーションを作成するには、[チャートビジュアライゼーションテンプレートの定義](#define-a-chart-visualization-template)を参照してください。

[たとえば](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/dashboards/audience.yaml)、3つのダッシュボードと、すべてのダッシュボードに適用される1つのビジュアライゼーション（折れ線チャート）を作成する場合、ファイル構造は次のようになります:

```plaintext
.gitlab/analytics/dashboards
├── conversion_funnels
│  └── conversion_funnels.yaml
├── demographic_breakdown
│  └── demographic_breakdown.yaml
├── north_star_metrics
|  └── north_star_metrics.yaml
├── visualizations
│  └── example_line_chart.yaml
```

### ダッシュボードフィルター {#dashboard-filters}

ダッシュボードは、次のフィルターをサポートしています:

- **日付範囲**: データを日付でフィルターするための日付セレクター。
- **Anonymous users**（匿名ユーザー）: データセットから匿名ユーザーを含めるか除外する切り替え。

フィルターを有効にするには、`.yaml`設定ファイルで、フィルターの`enabled`オプションを`true`に設定します:

```yaml
title: My dashboard
# ...
filters:
  excludeAnonymousUsers:
    enabled: true
  dateRange:
    enabled: true
```

完全な[ダッシュボード設定の例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/dashboards/audience.yaml)をご覧ください。

### インラインのチャートビジュアライゼーションを定義する {#define-an-inline-chart-visualization}

さまざまなチャートを定義し、次のようなビジュアライゼーションオプションをいくつか追加できます:

- [EChartsドキュメント](https://echarts.apache.org/en/option.html)にリストされているオプションを含む折れ線チャート。
- [EChartsドキュメント](https://echarts.apache.org/en/option.html)にリストされているオプションを含む縦棒チャート。
- データテーブル。
- 単一の統計。設定する唯一のオプションは、`decimalPlaces`です（数値、デフォルト値は0）。このプロセスは、ユーザーが作成したダッシュボードでも実行できます。各ビジュアライゼーションは、次の必須フィールドで記述する必要があります:

- バージョン
- タイプ:
- データ:
- オプション:

### チャートのビジュアライゼーションテンプレートを定義する {#define-a-chart-visualization-template}

{{< alert type="note" >}}

ビジュアライゼーションテンプレートは控えめに使用することをお勧めします。ビジュアライゼーションテンプレートを管理しないと、ダッシュボードエディタのUIに長いビジュアライゼーション選択リストが表示され、ビジュアライゼーションが見落とされたり、複製されたりする可能性があります。一般に、ビジュアライゼーションテンプレートは、複数のダッシュボードで同一に使用されるビジュアライゼーションのために予約する必要があります。

{{< /alert >}}

複数のダッシュボードで使用するビジュアライゼーションが必要な場合は、それらを個別のテンプレートファイルとして保存できます。ダッシュボードに追加すると、ビジュアライゼーションテンプレートがダッシュボードにコピーされます。ダッシュボードにコピーされたビジュアライゼーションテンプレートは、ビジュアライゼーションテンプレートが更新されても更新されません。

ダッシュボードのチャートビジュアライゼーションテンプレートを定義するには:

1. `.gitlab/analytics/dashboards/visualizations/`ディレクトリに、`.yaml`ファイルを作成します。ファイル名は、定義するビジュアライゼーションを説明するものである必要があります。
1. `.yaml`ファイルで、`ee/app/validators/json_schemas/analytics_visualization.json`のスキーマに従って、ビジュアライゼーション設定を定義します。

[たとえば](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/visualizations/events_over_time.yaml)、時間の経過に伴うイベント数を説明する折れ線チャートを作成するには、`visualizations`フォルダーで、次の必須フィールドを含む`line_chart.yaml`ファイルを作成します:

- バージョン
- タイプ:
- データ:
- オプション:

## トラブルシューティング {#troubleshooting}

### `Something went wrong while loading the dashboard.` {#something-went-wrong-while-loading-the-dashboard}

ダッシュボードにデータを読み込むことができなかったというグローバルエラーメッセージが表示された場合は、最初にページをリロードしてみてください。エラーが解決しない場合:

- お客様の設定が、`ee/app/validators/json_schemas/analytics_dashboard.json`で定義されているダッシュボードJSONスキーマと一致していることを確認してください。

### `Invalid dashboard configuration` {#invalid-dashboard-configuration}

ダッシュボードに設定が無効であるというグローバルエラーメッセージが表示された場合は、お客様の設定が、`ee/app/validators/json_schemas/analytics_dashboard.json`で定義されているダッシュボードJSONスキーマと一致していることを確認してください。

### `Invalid visualization configuration` {#invalid-visualization-configuration}

ダッシュボードパネルに、ビジュアライゼーション設定が無効であるというメッセージが表示された場合は、お客様のビジュアライゼーション設定が、`ee/app/validators/json_schemas/analytics_visualization.json`で定義されている[ビジュアライゼーションJSONスキーマ](#define-a-chart-visualization-template)と一致していることを確認してください。

### ダッシュボードパネルエラー {#dashboard-panel-error}

ダッシュボードパネルにエラーメッセージが表示された場合:

- [ビジュアライゼーション](analytics_dashboards.md#define-a-chart-visualization-template)設定が正しく設定されていることを確認してください。
