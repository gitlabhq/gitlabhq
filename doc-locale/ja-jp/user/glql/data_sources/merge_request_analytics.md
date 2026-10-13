---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: マージリクエスト分析
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21214)されました。

{{< /history >}}

アナリティクスモードはマージリクエストの集計されたメトリクスを返し、データは通常10分以内に利用可能です。

個々のマージリクエストレコードをクエリするには、[マージリクエスト](merge_requests.md)を使用します。

## 許可されたスコープ {#allowed-scopes}

| スコープ     | 説明                                                               |
| --------- | -------------------------------------------------------------------------- |
| `project` | 特定のプロジェクト内のマージリクエストをクエリします。                               |
| `group`   | サブグループを含むグループ内のすべてのプロジェクトを横断してマージリクエストをクエリします。 |

詳細については、[スコープ](_index.md#scopes)を参照してください。

## クエリフィールド {#query-fields}

これらのフィールドを`query`パラメータで使用して、結果をフィルタリングします。

| フィールド                              | 名前           | 演算子                 |
| ---------------------------------- | -------------- | ------------------------- |
| [作成日](#created-at)          | `created`      | `=`、`>`、`<`、`>=`、`<=` |
| [マージ日](#merged-at)            | `merged`       | `=`、`>`、`<`、`>=`、`<=` |
| [ステータス](#state)                    | `state`        | `=`、`in`                 |
| [ターゲットブランチ](#target-branch)    | `targetBranch` | `=`、`in`                 |

### 作成日 {#created-at}

**説明**: マージリクエストを作成日でフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式。ここで記号は`+`、`-`、または省略され、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれかです）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までとみなされます。

### マージ日 {#merged-at}

**説明**: マージリクエストをマージ日でフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式。ここで記号は`+`、`-`、または省略され、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれかです）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までとみなされます。

### ステータス {#state}

**説明**: マージリクエストをステータス別にフィルタリングします。

**指定可能な値の型**:

- `Enum`。`opened`、`closed`、`merged`、または`locked`のいずれか。
- `List`（複数の値には`in`演算子を使用）

**ノート**:

- `all`値はサポートされていません。すべてのステータスのマージリクエストを含めるには、フィルターを省略します。

### ターゲットブランチ {#target-branch}

**説明**: マージリクエストをターゲットブランチでフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

## ディメンション {#dimensions}

| ディメンション     | 名前           | 説明                              |
| ------------- | -------------- | ---------------------------------------- |
| 作成日    | `created`      | 作成日別にグループ化します。`daily`、`weekly`、または`monthly`（デフォルト: `weekly`）の[`granularity`パラメータ](../_index.md#field-parameters)を受け入れます。例: `created(monthly)`。 |
| マージ日     | `merged`       | マージ日別にグループ化します。`daily`、`weekly`、または`monthly`（デフォルト: `weekly`）の[`granularity`パラメータ](../_index.md#field-parameters)を受け入れます。例: `merged(monthly)`。 |
| ステータス         | `state`        | マージリクエストのステータス別にグループ化します。            |
| ターゲットブランチ | `targetBranch` | ターゲットブランチ別にグループ化します。                  |

## メトリクス {#metrics}

| メトリック                 | 名前                   | 説明                              |
| ---------------------- | ---------------------- | ---------------------------------------- |
| スループット数       | `throughputCount`      | マージされたマージリクエストの数。         |
| マージまでの時間のクオンタイル | `timeToMergeQuantile`  | 作成からマージまでの時間で、期間として表示されます。例: `1d 2h`。`0.01`と`0.99`の間（デフォルト: `0.5`、中央値）の[`quantile`パラメータ](../_index.md#field-parameters)を受け入れます。例: `timeToMergeQuantile(0.95)`。 |
| 合計数            | `totalCount`           | マージリクエストの合計数。          |

## ソートフィールド {#sort-fields}

選択したディメンションまたはメトリクスに含まれる任意のフィールドでソートします。詳細については、[アナリティクスモードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- 過去30日間のマージリクエスト週次スループット傾向:

  ````yaml
  ```glql
  title: "Weekly merge request throughput (last 30 days)"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and merged > -30d
  dimensions: merged(weekly) as "Week"
  metrics: totalCount as "Total", throughputCount as "Merged", timeToMergeQuantile(0.5) as "Median time to merge"
  sort: merged desc
  ```
  ````

- 週ごとのマージまでの中央値とp95時間:

  ````yaml
  ```glql
  title: "Median and p95 time to merge by week"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and merged > -90d
  dimensions: merged(weekly) as "Week"
  metrics: timeToMergeQuantile(0.5) as "Median time to merge", timeToMergeQuantile(0.95) as "p95 time to merge"
  sort: merged desc
  ```
  ````

- ステータス別にグループ化されたマージリクエスト:

  ````yaml
  ```glql
  title: "Merge requests by state (last 30 days)"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and created > -30d
  dimensions: state as "State"
  metrics: totalCount as "Total"
  sort: totalCount desc
  ```
  ````

- グループ全体のターゲットブランチごとのスループット:

  ````yaml
  ```glql
  title: "Merge request throughput by target branch"
  display: table
  mode: analytics
  query: type = MergeRequest and group = "gitlab-org" and merged > -30d
  dimensions: targetBranch as "Target branch"
  metrics: totalCount as "Total", throughputCount as "Merged"
  sort: throughputCount desc
  ```
  ````

- グループ全体の全体のマージリクエスト数（グループ化なし）:

  ````yaml
  ```glql
  title: "Merge requests created in the last 7 days"
  display: table
  mode: analytics
  query: type = MergeRequest and group = "gitlab-org" and created > -7d
  metrics: totalCount as "Total"
  ```
  ````
