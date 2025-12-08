---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インサイト
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インサイトは、月ごとのバグ作成数など、アイテム数を表示するインタラクティブな棒チャートです。

インサイトを設定し、プロジェクトとグループのカスタムレポートを作成して、次のようなデータを調査します:

- 指定された期間中に作成およびクローズされたイシュー。
- マージリクエストがマージされるまでの平均時間。
- トリアージの健全性。

## インサイトの表示 {#view-insights}

前提要件: 

- プロジェクトのインサイトの場合、プロジェクトへのアクセス権と、そのマージリクエストとイシューに関する情報を表示する権限が必要です。
- グループのインサイトの場合、グループを表示する権限が必要です。

プロジェクトまたはグループのインサイトを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**分析** > **インサイト**を選択します。
1. レポートを表示するには、**レポートを選択**ドロップダウンリストから、表示するレポートを選択します。注釈を表示するには、チャートの各バーにカーソルを合わせる。
1. オプション。結果をフィルタリングします: 
   - 90日間の範囲のサブセットからのデータのみを表示するには、一時停止アイコン（{{< icon name="status-paused" >}}）を選択し、水平軸に沿ってスライドさせます。
   - チャートからディメンションを除外するには、チャートの下の凡例から、ディメンションの名前を選択します。

### チャートをドリルダウンする {#drill-down-on-charts}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/372215/)されました。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/436704)され、GitLab 16.9のすべての`issuables`チャートへのサポートが拡張されました。

{{< /history >}}

`query.data_source`が`issuables`であるすべてのチャートのデータをドリルダウンできます。

特定の優先度または重大度のデータのドリルダウンレポートを月単位で表示するには:

- チャートで、ドリルダウンするバースタックを選択します。

### レポートディープリンクを作成する {#create-a-report-deep-link}

ディープリンクされたURLを使用して、インサイトの特定のレポートにユーザーを誘導できます。

ディープリンクを作成するには、インサイトレポートのURLの最後にレポートキーを追加します。たとえば、キーが`bugsCharts`のGitLabレポートのディープリンクURLは`https://gitlab.com/gitlab-org/gitlab/insights/#/bugsCharts`です。

## 設定 {#configuration}

### デフォルトファイル {#default-file}

GitLabは、[デフォルトの設定ファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/fixtures/insights/default.yml)からインサイトを読み取ります。

プロジェクトのインサイトは、プロジェクトの[`.gitlab/insights.yml`](#configuration)ファイルで設定されます。プロジェクトに設定ファイルがない場合は、[グループの設定](#for-groups)を使用します。

`.gitlab/insights.yml`ファイルは、次を定義するYAMLファイルです:

- レポート内のチャートの構造と順序。
- プロジェクトまたはグループのレポートに表示されるチャートのスタイル。

`.gitlab/insights.yml`ファイル内:

- [設定パラメータ](#parameters)は、チャートの動作を定義します。
- 各レポートには、一意のキーと、フェッチして表示するチャートのコレクションがあります。
- 各チャート定義は、キー/バリューペアで構成されるハッシュで構成されています。

#### 例 {#example}

次の例は、1つのチャートでレポートを表示する単一の定義を示しています:

```yaml
bugsCharts:
  title: "Charts for bugs"
  charts:
    - title: "Monthly bugs created"
      description: "Open bugs created per month"
      type: bar
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          group_by: month
          period_limit: 24
```

次の例は、3つのチャートを表示する`.gitlab/insights.yml`ファイルの完全な設定を示しています:

```yaml
.projectsOnly: &projectsOnly
  projects:
    only:
      - 3
      - groupA/projectA
      - groupA/subgroupB/projectC

bugsCharts:
  title: "Charts for bugs"
  charts:
    - title: "Monthly bugs created"
      description: "Open bugs created per month"
      type: bar
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          group_by: month
          period_limit: 24

    - title: "Weekly bugs by severity"
      type: stacked-bar
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          collection_labels:
            - S1
            - S2
            - S3
            - S4
          group_by: week
          period_limit: 104

    - title: "Monthly bugs by team"
      type: line
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: merge_request
          issuable_state: opened
          filter_labels:
            - bug
          collection_labels:
            - Manage
            - Plan
            - Create
          group_by: month
          period_limit: 24
```

### パラメータ {#parameters}

次の表に、チャートのパラメータを示します:

| キーワード                                            | 説明 |
|:---------------------------------------------------|:------------|
| [`title`](#title)                                  | このチャートのタイトル。これはインサイトページに表示されます。 |
| [`description`](#description)                      | 個々のチャートの説明。これは、関連するチャートの上に表示されます。 |
| [`type`](#type)                                    | チャートの種類：`bar`、`line`または`stacked-bar`。 |
| [`query`](#query)                                  | チャートのデータソースとフィルタリング条件を定義するハッシュ。 |

#### `title` {#title}

チャートのタイトルを更新するには、`title`を使用します。タイトルは、インサイトレポートに表示されます。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
```

#### `description` {#description}

チャートの説明を追加するには、`description`を使用します。説明はチャートの上に、タイトルの下に表示されます。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
```

#### `type` {#type}

チャートの種類を定義するには、`type`を使用します。

**Supported values**（サポートされている値）: 

| 名前  | 例:  |
| ----- | ------- |
| `bar` | ![インサイトの棒チャートの例](img/insights_example_bar_chart_v11_10.png) |
| `bar` （`group_by`を使用した時系列） | ![インサイトの棒時系列チャートの例](img/insights_example_bar_time_series_chart_v11_10.png) |
| `line` | ![インサイトの積み上げ棒チャートの例](img/insights_example_line_chart_v11_10.png) |
| `stacked-bar` | ![インサイトの積み上げ棒チャートの例](img/insights_example_stacked_bar_chart_v11_10.png) |

`dora`データソースは、`bar`および`line` [チャートの種類](#type)をサポートしています。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  type: bar
```

#### `query` {#query}

チャートのデータソースとフィルタリング条件を定義するには、`query`を使用します。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
      collection_labels:
        - S1
        - S2
        - S3
        - S4
      group_by: week
      period_limit: 104
```

`data_source`パラメータのない従来の形式は、引き続きサポートされています:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    issuable_type: issue
    issuable_state: opened
    filter_labels:
      - bug
    collection_labels:
      - S1
      - S2
      - S3
      - S4
    group_by: week
    period_limit: 104
```

##### `query.data_source` {#querydata_source}

データを公開するデータソースを定義するには、`data_source`を使用します。

**Supported values**（サポートされている値）: 

- `issuables`: マージリクエストまたはイシューデータを公開します。
- `dora`: DORAメトリクスを公開します。

##### `issuable`クエリパラメータ {#issuable-query-parameters}

###### `query.params.issuable_type` {#queryparamsissuable_type}

チャートを作成するイシュアブルの種類を定義するには、`query.params.issuable_type`を使用します。

**Supported values**（サポートされている値）: 

- `issue`: チャートには、イシューのデータが表示されます。
- `merge_request`: チャートには、マージリクエストのデータが表示されます。

###### `query.params.issuable_state` {#queryparamsissuable_state}

クエリされたイシュアブルの現在の状態でフィルタリングするには、`query.params.issuable_state`を使用します。

デフォルトでは、`opened`状態フィルターが適用されます。

**Supported values**（サポートされている値）: 

- `opened`: 開いているイシューまたはマージリクエスト。
- `closed`: クローズされたイシューまたはマージリクエスト。
- `locked`: ディスカッションがロックされているイシューまたはマージリクエスト。
- `merged`: マージリクエストをマージしました。
- `all`: すべての状態のイシューまたはマージリクエスト。

###### `query.params.filter_labels` {#queryparamsfilter_labels}

クエリされたイシュアブルに適用されたラベルでフィルタリングするには、`query.params.filter_labels`を使用します。

デフォルトでは、ラベルフィルターは適用されません。選択するには、定義されているすべてのラベルをイシュアブルに適用する必要があります。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly regressions created"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
        - regression
```

###### `query.params.collection_labels` {#queryparamscollection_labels}

構成されたラベルでイシュアブルをグループ化するには、`query.params.collection_labels`を使用します。グループ化はデフォルトでは適用されません。

**例**: 

```yaml
weeklyBugsBySeverity:
  title: "Weekly bugs by severity"
  type: stacked-bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
      collection_labels:
        - S1
        - S2
        - S3
        - S4
```

###### `query.group_by` {#querygroup_by}

チャートのX軸を定義するには、`query.group_by`を使用します。

**Supported values**（サポートされている値）: 

- `day`: 1日あたりのデータをグループ化します。
- `week`: 1週間あたりのデータをグループ化します。
- `month`: 1か月あたりのデータをグループ化します。

###### `query.period_limit` {#queryperiod_limit}

イシュアブルをクエリするために、過去にさかのぼってどれだけ遡るかを定義するには、`query.period_limit`を使用します（`query.period_field`を使用）。

ユニットは、`query.group_by`で定義された値に関連しています。たとえば、`query.group_by: 'day'`と`query.period_limit: 365`を定義した場合、チャートには過去365日間のデータが表示されます。

デフォルトでは、定義した`query.group_by`に応じて、デフォルト値が適用されます。

| `query.group_by` | デフォルト値 |
| ---------------- | ------------- |
| `day`            | 30            |
| `week`           | 4             |
| `month`          | 12            |

##### `query.period_field` {#queryperiod_field}

イシュアブルをグループ化するタイムスタンプフィールドを定義するには、`query.period_field`を使用します。

**Supported values**（サポートされている値）: 

- `created_at`（デフォルト）: `created_at`フィールドを使用してデータをグループ化します。
- `closed_at`: `closed_at`フィールドを使用してデータをグループ化します（イシューのみ）。
- `merged_at`: `merged_at`フィールドを使用してデータをグループ化します（マージリクエストのみ）。

`period_field`は自動的に次のように設定されます:

- `closed_at`は、`query.issuable_state`が`closed`の場合に設定されます。
- `merged_at`は、`query.issuable_state`が`merged`の場合に設定されます。
- それ以外の場合は`created_at`

{{< alert type="note" >}}

[このバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/26911)が解決されるまで、`created_at`が`merged_at`の代わりに表示される場合があります。`created_at`が代わりに使用されます。

{{< /alert >}}

##### `DORA`クエリパラメータ {#dora-query-parameters}

DORAチャート定義を作成するには、`dora`データソースでDORA固有のクエリを使用します。

**例**: 

```yaml
dora:
  title: "DORA charts"
  charts:
    - title: "DORA deployment frequency"
      type: bar # or line
      query:
        data_source: dora
        params:
          metric: deployment_frequency
          group_by: day
          period_limit: 10
      projects:
        only:
          - 38
    - title: "DORA lead time for changes"
      description: "DORA lead time for changes"
      type: bar
      query:
        data_source: dora
        params:
          metric: lead_time_for_changes
          group_by: day
          environment_tiers:
            - staging
          period_limit: 30
```

###### `query.metric` {#querymetric}

クエリする[DORAメトリクス](../../../api/dora/metrics.md#the-value-field)を定義するには、`query.metric`を使用します。

**Supported values**（サポートされている値）: 

- `deployment_frequency`（デフォルト）
- `lead_time_for_changes`
- `time_to_restore_service`
- `change_failure_rate`

###### `query.group_by` {#querygroup_by-1}

チャートのX軸を定義するには、`query.group_by`を使用します。

**Supported values**（サポートされている値）: 

- `day`（デフォルト）: 1日あたりのデータをグループ化します。
- `month`: 1か月あたりのデータをグループ化します。

###### `query.period_limit` {#queryperiod_limit-1}

メトリクスを過去に遡ってどれだけクエリするかを定義するには、`query.period_limit`を使用します（デフォルト: 15最長期間は180日または6か月です。

###### `query.environment_tiers` {#queryenvironment_tiers}

計算に含める環境の配列を定義するには、`query.environment_tiers`を使用します。

**Supported values**（サポートされている値）: 

- `production`（デフォルト）
- `staging`
- `testing`
- `development`
- `other`

#### `projects` {#projects}

イシュアブルのクエリ元を制限するには、`projects`を使用します:

- `.gitlab/insights.yml`がグループのインサイトに使用されている場合は、イシュアブルのクエリ元のプロジェクトを定義するために`projects`を使用します。デフォルトでは、グループのすべてのプロジェクトが使用されます。
- `.gitlab/insights.yml`がプロジェクトのインサイトに使用されている場合、他のプロジェクトを指定しても結果は得られません。デフォルトでは、プロジェクトが使用されます。

##### `projects.only` {#projectsonly}

イシュアブルのクエリ元のプロジェクトを指定するには、`projects.only`を使用します。

このパラメータにリストされているプロジェクトは、次の場合に無視されます:

- 存在しない。
- 現在のユーザーには、それらを読み取りるための十分な権限がありません。
- グループの外部にある。

**例**: 

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
  projects:
    only:
      - 3                         # You can use the project ID
      - groupA/projectA           # Or full project path
      - groupA/subgroupB/projectC # Projects in subgroups can be included
      - groupB/project            # Projects outside the group will be ignored
```

### インサイトを設定する {#configure-insights}

プロジェクトとグループのインサイトを設定できます。プロジェクトで`.gitlab/insights.yml`ファイルを作成した後、プロジェクトのグループにも使用できます。

{{< alert type="note" >}}

カスタム`.gitlab/insights.yml`ファイルは、デフォルトの設定をオーバーライドします。元の設定を保持するには、[デフォルトの設定ファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/fixtures/insights/default.yml)の内容をベースとしてコピーします。

{{< /alert >}}

#### プロジェクトの場合 {#for-projects}

前提要件: 

- プロジェクトのデベロッパーロール以上を持っている必要があります。

プロジェクトのインサイトを設定するには、ファイル`.gitlab/insights.yml`を作成します:

- ローカルで、プロジェクトのルートディレクトリに配置し、変更をプッシュします。
- UIから:
  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. ファイルリストの上で、コミットするブランチを選択し、プラスアイコンを選択して、**新しいファイル**を選択します。
  1. **ファイル名**に、`.gitlab/insights.yml`を入力します。
  1. エディタで、設定を入力します。[設定例](#example)を参照してください。
  1. **変更をコミットする**を選択します。

#### グループの場合 {#for-groups}

前提要件: 

- グループ内のプロジェクトには、`.gitlab/insights.yml`ファイルが必要です。

グループインサイトを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **分析**を選択します。
1. **インサイト**セクションで、`.gitlab/insights.yml`設定ファイルを含むプロジェクトを選択します。
1. **変更を保存**を選択します。
