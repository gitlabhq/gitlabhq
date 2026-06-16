---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コード提案
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/groups/gitlab-org/-/epics/21212)されました。

{{< /history >}}

コード提案は、プロジェクトまたはグループ全体での[GitLab Duoコード提案](../../project/repository/code_suggestions/_index.md)の利用状況に関する集計メトリクスを提供するデータソースです。

## 許可されるモード {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## 許可されるスコープ {#allowed-scopes}

| スコープ     | 説明                                                                 |
| --------- | --------------------------------------------------------------------------- |
| `project` | 特定のプロジェクトでコード提案をクエリします。                               |
| `group`   | サブグループを含むグループ内のすべてのプロジェクトでコード提案をクエリします。 |

## クエリフィールド {#query-fields}

| フィールド                                      | 名前（およびエイリアス） | オペレーター                 |
| ------------------------------------------ | ---------------- | ------------------------- |
| [IDE名](#cs-ide-name)                   | `ideName`        | `=`、`in`                 |
| [言語](#cs-language)                    | `language`       | `=`、`in`                 |
| [タイムスタンプ](#cs-timestamp)                 | `timestamp`      | `=`、`>`、`<`、`>=`、`<=` |
| [ユーザー](#cs-user)                           | `user`           | `=`、`in`                 |

### IDE名 {#cs-ide-name}

**説明**: 提案の生成に使用されたIDEでフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### 言語 {#cs-language}

**説明**: 提案のプログラミング言語でフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### タイムスタンプ {#cs-timestamp}

**説明**: 提案が生成された日時でフィルタリングします。範囲演算子を使用して時間枠を定義します。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式で、signは`+`、`-`、または省略され、digitは整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれか）

### ユーザー {#cs-user}

**説明**: 提案を受け取ったユーザーでフィルタリングします。

**指定可能な値の型**:

- `Number`（ユーザーID）
- `List`（複数のユーザーIDには`in`演算子を使用）

> [!note]
> ユーザー名フィルタリングのサポートは、[イシュー599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750)で追跡されています。

## ディメンション {#dimensions}

以下のディメンションがサポートされています:

| ディメンション | 名前（およびエイリアス） | 説明                                          |
|-----------|------------------|------------------------------------------------------|
| IDE名  | `ideName`        | 使用されたIDE（例: VSCode、JetBrains）でグループ化します。  |
| 言語  | `language`       | プログラミング言語でグループ化します。                       |
| タイムスタンプ | `timestamp`      | 日付でグループ化します。                                       |
| ユーザー      | `user`           | ユーザーでグループ化します（アバター、名前、ユーザー名を表示）。 |

## メトリクス {#metrics}

以下のメトリクスがサポートされています:

| メトリック              | 名前（およびエイリアス）    | 説明                             |
|---------------------|---------------------|-----------------------------------------|
| 承認率     | `acceptanceRate`    | 表示された提案に対する承認された提案の比率。 |
| 承認数      | `acceptedCount`     | 承認された提案の数。         |
| 却下数      | `rejectedCount`     | 却下された提案の数。         |
| 表示数         | `shownCount`        | ユーザーに表示された提案の数。   |
| 提案サイズ合計 | `suggestionSizeSum` | 提案の総量。            |
| 合計数         | `totalCount`        | 提案の合計数。            |
| ユーザー数         | `usersCount`        | ユニークユーザー数。                 |

## 例 {#examples}

- 過去30日間の言語別の承認率:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  dimensions: language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: acceptanceRate desc
  ```
  ````

- IDE別の使用状況:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  dimensions: ideName as "IDE"
  metrics: totalCount as "Total Suggestions", usersCount as "Active Users"
  sort: totalCount desc
  ```
  ````

- グループ化なしの全体メトリクス:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  metrics: totalCount as "Total", acceptedCount as "Accepted", rejectedCount as "Rejected", shownCount as "Shown", acceptanceRate as "Acceptance Rate"
  ```
  ````

- 特定のプロジェクトでのユーザーごとの提案（Rubyでフィルタリング）:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d and language = "ruby"
  dimensions: user as "User"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: totalCount desc
  limit: 10
  ```
  ````

- 日付範囲内の言語別経時提案:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= "2026-01-01" and timestamp <= "2026-03-31"
  dimensions: timestamp as "Date", language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: timestamp desc
  ```
  ````

- 特定のIDEと言語にフィルタリング:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -7d and ideName in ("Visual Studio Code", "RubyMine") and language in ("ruby", "python")
  dimensions: ideName as "IDE", language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Rate"
  sort: totalCount desc
  ```
  ````
