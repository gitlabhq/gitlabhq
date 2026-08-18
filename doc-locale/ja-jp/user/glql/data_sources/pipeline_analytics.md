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

- GitLab 19.1で[導入](https://gitlab.com/groups/gitlab-org/-/epics/21212)されました。

{{< /history >}}

アナリティクスモードは、完了したパイプラインの集計メトリクスを返します。データは通常10分以内に利用可能です。

個々のパイプラインレコードをクエリするには、[パイプライン](pipelines.md)を使用します。

## 許可されたスコープ {#allowed-scopes}

| スコープ     | 説明                                                                   |
| --------- | ----------------------------------------------------------------------------- |
| `project` | 特定のプロジェクトで完了したパイプラインをクエリする。                               |
| `group`   | グループ内のすべてのプロジェクト（サブグループを含む）で完了したパイプラインをクエリする。 |

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
- `>=`および`<=`演算子は、クエリ対象の日付を含みますが、`>`および`<`は含みません。

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
- `>=`および`<=`演算子は、クエリ対象の日付を含みますが、`>`および`<`は含みません。

### ステータス {#status}

**説明**: パイプラインをそのCI/CDのステータスでフィルタリングします。

**指定可能な値の型**:

- `Enum`。次のいずれか: `canceled`、`failed`、`skipped`、または`success`
- `List`（複数の値には`in`演算子を使用）

## ディメンション {#dimensions}

| ディメンション   | 名前       | 説明                              |
| ----------- | ---------- | ---------------------------------------- |
| 完了日時 | `finished` | 完了日でグループ化します（週単位）。 |
| プロジェクト     | `project`  | プロジェクトでグループ化します。                        |
| Ref         | `ref`      | Gitブランチまたはタグでグループ化します。        |
| ソース      | `source`   | パイプラインをトリガーしたものでグループ化します。    |
| 開始日時  | `started`  | 開始日でグループ化します（週単位）。  |
| ステータス      | `status`   | パイプラインのステータスでグループ化します。                |

## メトリクス {#metrics}

| メトリック            | 名前               | 説明                                       |
| ----------------- | ------------------ | ------------------------------------------------- |
| キャンセル率     | `canceledRate`     | キャンセルされたパイプラインの、全パイプラインに対する比率。   |
| 期間クォンタイル | `durationQuantile` | パイプライン期間の95パーセンタイル値（秒単位）。 |
| 失敗率      | `failureRate`      | 失敗したパイプラインの、全パイプラインに対する比率。     |
| スキップ率      | `skippedRate`      | スキップされたパイプラインの、全パイプラインに対する比率。    |
| 成功率      | `successRate`      | 成功したパイプラインの、全パイプラインに対する比率。 |
| 合計数       | `totalCount`       | 完了したパイプラインの総数。               |

> [!note]
> 日付ディメンションは固定の`weekly`粒度を使用し、`durationQuantile`は固定の0.95クォンタイルを使用します。設定可能な粒度とクォンタイルに関するサポートは、[GLQLイシュー130](https://gitlab.com/gitlab-org/glql/-/work_items/130)で提案されています。

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
