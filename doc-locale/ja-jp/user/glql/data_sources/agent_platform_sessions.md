---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エージェントプラットフォームセッション
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/592423)されました。

{{< /history >}}

このデータソースは、プロジェクトまたはグループ全体でのGitLab Duo Agent Platformセッション使用状況に関する集計メトリクスを提供します。

## 許可されるモード {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## 許可されたスコープ {#allowed-scopes}

| スコープ     | 説明 |
|-----------|-------------|
| `project` | 特定のプロジェクトでGitLab Duo Agent Platformセッションをクエリします。 |
| `group`   | グループ内のすべてのプロジェクト（サブグループを含む）でGitLab Duo Agent Platformセッションをクエリします。 |

詳細については、[スコープ](_index.md#scopes)を参照してください。

## クエリフィールド {#query-fields}

これらのフィールドを`query`パラメータで使用して、結果をフィルタリングします。

| フィールド                   | 名前（およびエイリアス）                                | 演算子                 |
| ----------------------- | ----------------------------------------------- | ------------------------- |
| [作成済み](#created)     | `created`（`opened`、`openedAt`、`createdAt`）   | `=`、`>`、`<`、`>=`、`<=` |
| [フロータイプ](#flow-type) | `flowType`                                      | `=`、`in`                 |
| [ユーザー](#user)           | `user`                                          | `=`、`in`                 |

### 作成済み {#created}

**説明**: セッションが作成された日時でフィルタリングします。範囲演算子を使用して時間枠を定義します。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式。符号は`+`、`-`、または省略、数値は整数、`unit`は`d`（日）、`w`（週）、`m`（月）、または`y`（年）のいずれか）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までとみなされます。

### フロータイプ {#flow-type}

**説明**: セッションのフロータイプでフィルタリングします。例: `chat`、`code_review/v1`。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### ユーザー {#user}

**説明**: セッションを所有するユーザーでフィルタリングします。

**指定可能な値の型**:

- `Number`（ユーザーID）
- `List`（複数のユーザーIDには`in`演算子を使用）

> [!note]
> ユーザー名によるフィルタリングのサポートは、[イシュー599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750)で追跡されています。

## ディメンション {#dimensions}

| ディメンション | 名前       | 説明 |
|-----------|------------|-------------|
| 作成済み   | `created`  | 日付でグループ化します。[`granularity`パラメータ](../_index.md#field-parameters)には`weekly`または`monthly`を指定できます（デフォルト: `weekly`）。例: `created(monthly)`。 |
| フロータイプ | `flowType` | セッションのフロータイプでグループ化します。 |
| プロジェクト   | `project`  | プロジェクトでグループ化します。プロジェクトにスコープされていないセッションは、プロジェクトなしで単一の行にグループ化されます。 |
| ユーザー      | `user`     | ユーザーでグループ化します（アバター、名前、ユーザー名を表示）。 |

## メトリクス {#metrics}

| メトリック            | 名前               | 説明 |
|-------------------|--------------------|-------------|
| 完了率   | `completionRate`   | 完了したセッションの割合（0から1の値）。 |
| 最大期間      | `durationMax`      | 完了したセッションの最長期間（秒単位）。 |
| 平均期間     | `durationMean`     | 完了したセッションの平均期間（秒単位）。 |
| 最小期間      | `durationMin`      | 完了したセッションの最短期間（秒単位）。 |
| 期間分位 | `durationQuantile` | 指定された分位における完了したセッションの期間（秒単位）。[`quantile`パラメータ](../_index.md#field-parameters)には`0.01`から`0.99`の値を指定できます（デフォルト: `0.5`）。例: `durationQuantile(0.95)`。 |
| 期間合計      | `durationSum`      | 完了したセッションの総期間（秒単位）。 |
| 完了数    | `finishedCount`    | 完了したセッションの数。 |
| 合計数       | `totalCount`       | セッションの総数。 |
| ユーザー数       | `usersCount`       | ユニークユーザーの数。 |

## ソートフィールド {#sort-fields}

任意のディメンション、または以下のメトリクスでソートします:

- `totalCount`
- `finishedCount`
- `usersCount`
- `completionRate`
- `durationQuantile`。

これらのメトリクスはソートできません:

- `durationMean`
- `durationMin`
- `durationMax`
- `durationSum`

詳細については、[アナリティクスモードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- 過去30日間のフロータイプ別セッション:

  ````yaml
  ```glql
  title: "Agent Platform sessions by flow (last 30 days)"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  dimensions: flowType as "Flow"
  metrics: totalCount as "Total", finishedCount as "Finished", completionRate as "Completion rate"
  sort: totalCount desc
  ```
  ````

- 週次セッショントレンド:

  ````yaml
  ```glql
  title: "Weekly Agent Platform session trend"
  display: columnChart
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -90d
  dimensions: created(weekly) as "Week"
  metrics: totalCount as "Total", usersCount as "Users"
  sort: created desc
  ```
  ````

- ユーザーごとのセッション、平均期間を含む:

  ````yaml
  ```glql
  title: "Agent Platform sessions by user"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  dimensions: user as "User"
  metrics: totalCount as "Total", durationMean as "Avg duration"
  sort: totalCount desc
  limit: 10
  ```
  ````

- グループ化なしの全体的な完了率と中央値期間:

  ````yaml
  ```glql
  title: "Agent Platform session completion (last 30 days)"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  metrics: totalCount as "Total", completionRate as "Completion rate", durationQuantile(0.5) as "Median duration"
  ```
  ````
