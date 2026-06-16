---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabにおけるイシュー統計に関するREST APIのドキュメント。
title: イシュー統計API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[イシュー](../user/project/issues/_index.md)に関する統計を取得することができます。このAPIへのすべての呼び出しには認証が必要です。

ユーザーがプロジェクトのメンバーではなく、プロジェクトがプライベートである場合、そのプロジェクトに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

## ユーザーのイシュー統計を取得する {#retrieve-issues-statistics-for-a-user}

現在のユーザーがアクセスできるイシューの統計を取得します。デフォルトでは、現在のユーザーが作成したイシューのみが返されます。すべてのイシューを取得するには、`scope`属性を`all`に設定します。

```plaintext
GET /issues_statistics
GET /issues_statistics?labels=foo
GET /issues_statistics?labels=foo,bar
GET /issues_statistics?labels=foo,bar&state=opened
GET /issues_statistics?milestone=1.0.0
GET /issues_statistics?milestone=1.0.0&state=opened
GET /issues_statistics?iids[]=42&iids[]=43
GET /issues_statistics?author_id=5
GET /issues_statistics?assignee_id=5
GET /issues_statistics?my_reaction_emoji=star
GET /issues_statistics?search=foo&in=title
GET /issues_statistics?confidential=true
```

| 属性           | 型             | 必須   | 説明                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `labels`            | 文字列           | いいえ         | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。 |
| `milestone`         | 文字列           | いいえ         | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。                             |
| `scope`             | 文字列           | いいえ         | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。デフォルトは`created_by_me`です。 |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `assignee_id`       | 整数          | いいえ         | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username` | 文字列配列     | いいえ         | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab CEでは、`assignee_username`配列には単一の値のみを含める必要があり、そうでない場合は無効なパラメータエラーが返されます。 |
| `epic_id`           | 整数      | いいえ         | 指定されたエピックIDに関連付けられているイシューを返します。`None`は、エピックに関連付けられていないイシューを返します。`Any`は、エピックに関連付けられているイシューを返します。PremiumおよびUltimateのみです。 |
| `my_reaction_emoji` | 文字列           | いいえ         | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `iids[]`            | 整数の配列    | いいえ         | 指定された`iid`を持つイシューのみを返します。                                                                                                       |
| `search`            | 文字列           | いいえ         | イシューをその`title`と`description`に対して検索します。                                                                                               |
| `in`                | 文字列           | いいえ         | `search`属性のスコープを変更します（`title`、`description`、またはこれらをカンマで結合した文字列）。デフォルトは`title,description`です。             |
| `created_after`     | 日時         | いいえ         | 指定時刻以降に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `created_before`    | 日時         | いいえ         | 指定時刻以前に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_after`     | 日時         | いいえ         | 指定時刻以降に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_before`    | 日時         | いいえ         | 指定時刻以前に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `confidential`      | ブール値          | いいえ         | 非公開イシューまたは公開イシューをフィルタリングします。                                                                                                               |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues_statistics"
```

レスポンス例: 

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## グループのイシュー統計を取得する {#retrieve-issues-statistics-for-a-group}

指定されたグループのイシューの統計を取得します。

```plaintext
GET /groups/:id/issues_statistics
GET /groups/:id/issues_statistics?labels=foo
GET /groups/:id/issues_statistics?labels=foo,bar
GET /groups/:id/issues_statistics?labels=foo,bar&state=opened
GET /groups/:id/issues_statistics?milestone=1.0.0
GET /groups/:id/issues_statistics?milestone=1.0.0&state=opened
GET /groups/:id/issues_statistics?iids[]=42&iids[]=43
GET /groups/:id/issues_statistics?search=issue+title+or+description
GET /groups/:id/issues_statistics?author_id=5
GET /groups/:id/issues_statistics?assignee_id=5
GET /groups/:id/issues_statistics?my_reaction_emoji=star
GET /groups/:id/issues_statistics?confidential=true
```

| 属性           | 型             | 必須   | 説明                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                 |
| `labels`            | 文字列           | いいえ         | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。 |
| `iids[]`            | 整数の配列    | いいえ         | 指定された`iid`を持つイシューのみを返します。                                                                                 |
| `milestone`         | 文字列           | いいえ         | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。       |
| `scope`             | 文字列           | いいえ         | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。 |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `assignee_id`       | 整数          | いいえ         | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username` | 文字列配列     | いいえ         | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab CEでは、`assignee_username`配列には単一の値のみを含める必要があり、そうでない場合は無効なパラメータエラーが返されます。 |
| `my_reaction_emoji` | 文字列           | いいえ         | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `search`            | 文字列           | いいえ         | グループイシューをその`title`と`description`に対して検索します。                                                                   |
| `created_after`     | 日時         | いいえ         | 指定時刻以降に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `created_before`    | 日時         | いいえ         | 指定時刻以前に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_after`     | 日時         | いいえ         | 指定時刻以降に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_before`    | 日時         | いいえ         | 指定時刻以前に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `confidential`      | ブール値          | いいえ         | 非公開イシューまたは公開イシューをフィルタリングします。                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues_statistics"
```

レスポンス例: 

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## プロジェクトのイシュー統計を取得する {#retrieve-issues-statistics-for-a-project}

指定されたプロジェクトのイシューの統計を取得します。

```plaintext
GET /projects/:id/issues_statistics
GET /projects/:id/issues_statistics?labels=foo
GET /projects/:id/issues_statistics?labels=foo,bar
GET /projects/:id/issues_statistics?labels=foo,bar&state=opened
GET /projects/:id/issues_statistics?milestone=1.0.0
GET /projects/:id/issues_statistics?milestone=1.0.0&state=opened
GET /projects/:id/issues_statistics?iids[]=42&iids[]=43
GET /projects/:id/issues_statistics?search=issue+title+or+description
GET /projects/:id/issues_statistics?author_id=5
GET /projects/:id/issues_statistics?assignee_id=5
GET /projects/:id/issues_statistics?my_reaction_emoji=star
GET /projects/:id/issues_statistics?confidential=true
```

| 属性           | 型             | 必須   | 説明                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)               |
| `iids[]`            | 整数の配列    | いいえ         | 指定された`iid`を持つイシューのみを返します。                                                                              |
| `labels`            | 文字列           | いいえ         | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。 |
| `milestone`         | 文字列           | いいえ         | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。       |
| `scope`             | 文字列           | いいえ         | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。 |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `assignee_id`       | 整数          | いいえ         | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username` | 文字列配列     | いいえ         | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab CEでは、`assignee_username`配列には単一の値のみを含める必要があり、そうでない場合は無効なパラメータエラーが返されます。 |
| `my_reaction_emoji` | 文字列           | いいえ         | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `search`            | 文字列           | いいえ         | プロジェクトイシューをその`title`と`description`に対して検索します。                                                                 |
| `created_after`     | 日時         | いいえ         | 指定時刻以降に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `created_before`    | 日時         | いいえ         | 指定時刻以前に作成されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_after`     | 日時         | いいえ         | 指定時刻以降に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `updated_before`    | 日時         | いいえ         | 指定時刻以前に更新されたイシューを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）が予期されます。 |
| `confidential`      | ブール値          | いいえ         | 非公開イシューまたは公開イシューをフィルタリングします。                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues_statistics"
```

レスポンス例: 

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```
