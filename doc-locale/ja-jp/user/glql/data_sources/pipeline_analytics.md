---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パイプラインアナリティクス
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21212)されました。
- [変更](https://gitlab.com/gitlab-org/glql/-/merge_requests/416)され、GitLab 19.2で進行中のパイプラインを含むすべての状態のパイプラインをカバーするようになりました。
- GitLab 19.3で設定可能な`granularity`および`quantile`パラメータが[導入](https://gitlab.com/gitlab-org/glql/-/issues/130)されました。

{{< /history >}}

アナリティクスモードは、進行中のパイプラインを含むすべての状態のパイプラインに対して集約されたメトリクスを返し、データは通常10分以内に利用可能です。

個々のパイプラインレコードをクエリするには、[パイプライン](pipelines.md)を使用します。

## 許可されたスコープ {#allowed-scopes}

| スコープ     | 説明                                                          |
| --------- | -------------------------------------------------------------------- |
| `project` | 特定のプロジェクトのパイプラインをクエリします。                               |
| `group`   | サブグループを含むグループ内のすべてのプロジェクトのパイプラインをクエリします。 |

## クエリフィールド {#query-fields}

| フィールド                                  | 名前       | 演算子                 |
| -------------------------------------- | ---------- | ------------------------- |
| [完了日時](#finished-at)         | `finished` | `=`、`>`、`<`、`>=`、`<=` |
| [Ref](#ref)                         | `ref`      | `=`、`in`                 |
| [ソース](#source)                   | `source`   | `=`、`in`                 |
| [開始日時](#started-at)           | `started`  | `=`、`>`、`<`、`>=`、`<=` |
| [ステータス](#status)                   | `status`   | `=`、`in`                 |

### 完了日時 {#finished-at}

**説明**: パイプラインを完了日でフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式で、signは`+`、`-`、または省略され、digitは整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれか）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。

### Ref {#ref}

**説明**: パイプラインを、実行されたGitブランチまたはタグ名でフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### ソース {#source}

**説明**: パイプラインをトリガーイベントでフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### 開始日時 {#started-at}

**説明**: パイプラインを開始日でフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式で、signは`+`、`-`、または省略され、digitは整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれか）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。

### ステータス {#status}

**説明**: パイプラインをそのCI/CDのステータスでフィルタリングします。

**指定可能な値の型**:

- `Enum`（`canceled`、`canceling`、`created`、`failed`、`manual`、`pending`、`preparing`、`running`、`scheduled`、`skipped`、`success`、`waiting_for_callback`、または`waiting_for_resource`）のいずれか。
- `List`（複数の値には`in`演算子を使用）

## ディメンション {#dimensions}

| ディメンション   | 名前       | 説明                              |
| ----------- | ---------- | ---------------------------------------- |
| 完了日時 | `finished` | 終了日でグループ化します。`daily`、`weekly`、または`monthly`（デフォルト: `weekly`）の[`granularity`パラメータ](../_index.md#field-parameters)を受け入れます。例: `finished(daily)`。 |
| プロジェクト     | `project`  | プロジェクトでグループ化します。                        |
| Ref         | `ref`      | Gitブランチまたはタグでグループ化します。        |
| ソース      | `source`   | パイプラインをトリガーしたものでグループ化します。    |
| 開始日時  | `started`  | 開始日でグループ化します。`daily`、`weekly`、または`monthly`（デフォルト: `weekly`）の[`granularity`パラメータ](../_index.md#field-parameters)を受け入れます。例: `started(daily)`。 |
| ステータス      | `status`   | パイプラインのステータスでグループ化します。                |

## メトリクス {#metrics}

パイプラインは、処理を完了し、成功、失敗した、キャンセル済み、またはスキップ済みの最終状態に達したときに完了と見なされます。

| メトリック            | 名前               | 説明                                            |
| ----------------- | ------------------ | ------------------------------------------------------ |
| キャンセル率     | `canceledRate`     | キャンセルされたパイプラインの、完了したパイプラインに対する比率。    |
| 期間クォンタイル | `durationQuantile` | パイプラインの継続時間のクォンタイル（秒単位）。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け入れます（デフォルト: `0.95`）。例: `durationQuantile(0.5)`。 |
| 失敗率      | `failureRate`      | 失敗したパイプラインの、完了したパイプラインに対する比率。      |
| スキップ率      | `skippedRate`      | スキップされたパイプラインの、完了したパイプラインに対する比率。     |
| 成功率      | `successRate`      | 成功したパイプラインの、完了したパイプラインに対する比率。  |
| 合計数       | `totalCount`       | 進行中のものを含む、パイプラインの合計数。 |

## ソートフィールド {#sort-fields}

選択したディメンションまたはメトリクスに含まれる任意のフィールドでソートします。詳細については、[アナリティクスモードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- 過去30日間のRefごとのパイプラインの成功率と失敗率:

  ````yaml
  ```glql
  title: "Pipeline success and failure rates by branch (last 30 days)"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= -30d
  dimensions: ref as "Ref"
  metrics: totalCount as "Total", successRate as "Success rate", failureRate as "Failure rate"
  sort: totalCount desc
  ```
  ````

- 特定のRefに関する週ごとのパイプライン期間トレンド:

  ````yaml
  ```glql
  title: "Weekly pipeline duration trend for master"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and ref = "master" and finished >= -90d
  dimensions: finished as "Week"
  metrics: totalCount as "Total", durationQuantile as "p95 duration (s)"
  sort: finished desc
  ```
  ````

- 週ごとのメディアンおよびp95パイプライン継続時間:

  ````yaml
  ```glql
  title: "Median and p95 pipeline duration by week"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= -90d
  dimensions: finished(weekly) as "Week", status as "Status"
  metrics: durationQuantile(0.5) as "Median", durationQuantile(0.95) as "p95", totalCount as "Total"
  sort: Median desc
  ```
  ````

- グループの全体的なパイプラインメトリクス（グループ化なし）:

  ````yaml
  ```glql
  title: "Overall pipeline metrics for gitlab-org"
  display: table
  mode: analytics
  query: type = Pipeline and group = "gitlab-org" and finished >= -7d
  metrics: totalCount as "Total", successRate as "Success rate", failureRate as "Failure rate", canceledRate as "Canceled rate"
  ```
  ````

- ソースとステータスでグループ化され、日付範囲でフィルタリングされたパイプライン:

  ````yaml
  ```glql
  title: "Pipelines by source and status (Q1 2026)"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= "2026-01-01" and finished <= "2026-03-31"
  dimensions: source as "Source", status as "Status"
  metrics: totalCount as "Total"
  sort: totalCount desc
  ```
  ````

- グループ全体の特定のrefsとステータスにフィルタリング:

  ````yaml
  ```glql
  title: "Default branch pipeline outcomes across gitlab-org"
  display: table
  mode: analytics
  query: type = Pipeline and group = "gitlab-org" and finished >= -14d and ref in ("master", "main") and status in ("success", "failed")
  dimensions: project as "Project", status as "Status"
  metrics: totalCount as "Total", successRate as "Success rate"
  sort: totalCount desc
  limit: 20
  ```
  ````
