---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI使用イベント
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21216)されました。

{{< /history >}}

AI使用イベントは、プロジェクトまたはグループ全体でのGitLab Duo機能の使用状況に関する集計メトリクスを提供するデータソースです。

## 許可されるモード {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## 許可されたスコープ {#allowed-scopes}

| スコープ     | 説明                                                                 |
| --------- | --------------------------------------------------------------------------- |
| `project` | 特定のプロジェクトでAI使用イベントをクエリします。                                |
| `group`   | グループ内のすべてのプロジェクト（サブグループを含む）でAI使用イベントをクエリします。  |

詳細については、[スコープ](_index.md#scopes)を参照してください。

## クエリフィールド {#query-fields}

これらのフィールドを`query`パラメータで使用して、結果をフィルタリングします。

| フィールド                                | 名前            | 演算子                 |
| ------------------------------------ | --------------- | ------------------------- |
| [イベント](#event)                      | `event`         | `=`、`in`                 |
| [機能](#feature)                  | `feature`       | `=`、`in`                 |
| [機能数](#features-count)    | `featuresCount` | `>`、`<`、`>=`、`<=`      |
| [タイムスタンプ](#timestamp)              | `timestamp`     | `=`、`>`、`<`、`>=`、`<=` |
| [ユーザー](#user)                        | `user`          | `=`、`in`                 |

### イベント {#event}

**説明**: イベント識別子でフィルタリングします。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### 機能 {#feature}

**説明**: イベントを生成したGitLab Duo機能でフィルタリングします。例えば、code_suggestionsやchatなどです。例: `code_suggestions`、`chat`。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`演算子を使用）

### 機能数 {#features-count}

**説明**: 使用されたユニークな機能の数でフィルタリングします。このフィルターは、`featuresCount`メトリクスも選択されている場合にのみ有効です。

**指定可能な値の型**: `Number`

### タイムスタンプ {#timestamp}

**説明**: イベント発生日時でフィルタリングします。範囲演算子を使用して時間枠を定義します。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式。ここで記号は`+`、`-`、または省略され、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれかです）

**ノート**:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンで00:00から23:59までとみなされます。

### ユーザー {#user}

**説明**: イベントをトリガーしたユーザーでフィルタリングします。

**指定可能な値の型**:

- `Number`（ユーザーID）
- `List`（複数のユーザーIDには`in`演算子を使用）

> [!note]
> ユーザー名によるフィルタリングのサポートは、[イシュー599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750)で追跡されています。

## ディメンション {#dimensions}

| ディメンション | 名前        | 説明                                          |
| --------- | ----------- | ---------------------------------------------------- |
| イベント     | `event`     | イベント識別子でグループ化します。                           |
| 機能   | `feature`   | GitLab Duo機能でグループ化します。                         |
| タイムスタンプ | `timestamp` | 日付でグループ化します。`daily`、`weekly`、または`monthly`（デフォルト: `weekly`）の[`granularity`パラメータ](../_index.md#field-parameters)を受け入れます。例: `timestamp(daily)`。 |
| ユーザー      | `user`      | ユーザーでグループ化します（アバター、名前、ユーザー名を表示）。 |

## メトリクス {#metrics}

| メトリック                      | 名前                      | 説明                                             |
| --------------------------- | ------------------------- | ------------------------------------------------------- |
| 機能数              | `featuresCount`           | 使用されたユニークな機能の数。                         |
| 前期間のユーザー数 | `previousPeriodUsersCount` | 前期間のユニークユーザーの数。         |
| 再利用ユーザー数       | `returningUsersCount`     | 現在および前期間の両方でアクティブなユーザーの数。 |
| 合計数                 | `totalCount`              | イベントの総数。                                 |
| ユーザー数                 | `usersCount`              | ユニークユーザーの数。                                 |

**ノート**:

- `returningUsersCount`および`previousPeriodUsersCount`メトリクスは、`timestamp`ディメンションも選択されている場合にのみ有効です。

## ソートフィールド {#sort-fields}

選択したディメンションまたはメトリクスに含まれる任意のフィールドでソートします。詳細については、[アナリティクスモードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- 過去30日間の機能採用状況:

  ````yaml
  ```glql
  title: "GitLab Duo feature adoption (last 30 days)"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  dimensions: feature as "Feature"
  metrics: totalCount as "Total events", usersCount as "Users"
  sort: usersCount desc
  ```
  ````

- 再利用ユーザーを含む週次使用傾向:

  ````yaml
  ```glql
  title: "Weekly GitLab Duo usage trend"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  dimensions: timestamp(weekly) as "Week"
  metrics: usersCount as "Users", returningUsersCount as "Returning users", previousPeriodUsersCount as "Previous period users"
  sort: timestamp desc
  ```
  ````

- 特定のプロジェクトのユーザーごとのイベント:

  ````yaml
  ```glql
  title: "GitLab Duo events by user"
  display: table
  mode: analytics
  query: type = AiUsageEvent and project = "gitlab-org/gitlab" and timestamp > -30d
  dimensions: user as "User"
  metrics: totalCount as "Total events"
  sort: totalCount desc
  limit: 10
  ```
  ````

- グループ化なしの全体的なユニークユーザー数:

  ````yaml
  ```glql
  title: "Unique GitLab Duo users (last 30 days)"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  metrics: usersCount as "Users"
  ```
  ````
