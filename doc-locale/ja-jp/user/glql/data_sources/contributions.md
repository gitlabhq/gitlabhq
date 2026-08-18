---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コントリビュート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21212)されました。

{{< /history >}}

コントリビュートは、プロジェクトまたはグループ全体のコントリビュートアクティビティ（コミット、イシュー、マージリクエストなど）に関する集計メトリクスを提供するデータソースです。

## 許可されるモード {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## 許可されるスコープ {#allowed-scopes}

| スコープ     | 説明                                                              |
| --------- | ------------------------------------------------------------------------ |
| `project` | 特定のプロジェクトにおけるコントリビュートをクエリする。                               |
| `group`   | サブグループを含むグループ内のすべてのプロジェクトにおけるコントリビュートをクエリする。 |

## クエリフィールド {#query-fields}

| フィールド                      | 名前      | 演算子                 |
| -------------------------- | --------- | ------------------------- |
| [作成日](#created-at)  | `created` | `=`、`>`、`<`、`>=`、`<=` |
| [ユーザー](#user)              | `user`    | `=`、`in`                 |

### 作成日 {#created-at}

**説明**: コントリビュートが作成された日付でコントリビュートをフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate`（`YYYY-MM-DD`の形式）
- `RelativeDate`（`<sign><digit><unit>`の形式。`+`、`-`、または省略された記号で、桁は整数であり、`unit`は`d`（日）、`w`（週）、`m`（月）、`y`（年）のいずれかです）

**ノート**:

- `=`演算子の場合、GitLab Query Languageはユーザーのタイムゾーンで00:00から23:59までの時間範囲を考慮します。

### ユーザー {#user}

**説明**: コントリビュートを行ったユーザーでフィルタリングします。

**指定可能な値の型**:

- `Number`（ユーザーID）
- `List`（複数のユーザーIDには`in`演算子を使用）

> [!note]
> ユーザー名フィルタリングのサポートは、[GLQLイシュー143](https://gitlab.com/gitlab-org/glql/-/work_items/143)で追跡されています。

## ディメンション {#dimensions}

| ディメンション  | 名前      | 説明                                          |
| ---------- | --------- | ----------------------------------------------------- |
| 作成日 | `created` | コントリビュートの作成日で月ごとのバケットにグループ化します。 |

## メトリクス {#metrics}

| メトリック      | 名前         | 説明                    |
| ----------- | ------------ | ------------------------------- |
| 合計数 | `totalCount` | コントリビュートの合計数。 |
| ユーザー数 | `usersCount` | ユニークコントリビューターの数。 |

## ソートフィールド {#sort-fields}

選択したディメンションまたはメトリクスに含まれる任意のフィールドでソートします。詳細については、[アナリティクスモードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- プロジェクトの月ごとのコントリビュートトレンド:

  ````yaml
  ```glql
  title: "Monthly contributions"
  display: table
  mode: analytics
  query: type = Contribution and project = "gitlab-org/gitlab"
  dimensions: created as "Month"
  metrics: totalCount as "Total", usersCount as "Contributors"
  sort: created desc
  ```
  ````

- 一連のユーザーのコントリビュートトレンド:

  ````yaml
  ```glql
  title: "Contributions from a set of users"
  display: table
  mode: analytics
  query: type = Contribution and project = "gitlab-org/gitlab" and user in (1234567, 2345678) and created >= -90d
  dimensions: created as "Month"
  metrics: totalCount as "Total"
  sort: created desc
  ```
  ````

- 過去1年間の特定ユーザーの月ごとのコントリビュート:

  ````yaml
  ```glql
  title: "User contribution history"
  display: table
  mode: analytics
  query: type = Contribution and group = "gitlab-org" and user = 1234567 and created >= -365d
  dimensions: created as "Month"
  metrics: totalCount as "Total"
  sort: created asc
  ```
  ````

- グループ全体のコントリビュートメトリクス（グループ化なし）:

  ````yaml
  ```glql
  title: "Overall contribution metrics"
  display: table
  mode: analytics
  query: type = Contribution and group = "gitlab-org" and created >= -90d
  metrics: totalCount as "Total", usersCount as "Contributors"
  ```
  ````
