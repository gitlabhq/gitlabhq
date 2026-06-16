---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループマイルストーンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループマイルストーン](../user/project/milestones/_index.md)を管理します。

プロジェクトマイルストーンには、[プロジェクトマイルストーンAPI](milestones.md)を使用してください。

## グループマイルストーンのリスト {#list-group-milestones}

グループマイルストーンのリストを返します。

```plaintext
GET /groups/:id/milestones
GET /groups/:id/milestones?iids[]=42
GET /groups/:id/milestones?iids[]=42&iids[]=43
GET /groups/:id/milestones?state=active
GET /groups/:id/milestones?state=closed
GET /groups/:id/milestones?title=1.0
GET /groups/:id/milestones?search=version
GET /groups/:id/milestones?search_title=17.3+17.4
GET /groups/:id/milestones?search_title=17.3%2017.4
GET /groups/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?containing_date=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?start_date=2013-10-02T09%3A24%3A18Z&end_date=2013-11-02T09%3A24%3A18Z
```

パラメータは以下のとおりです:

| 属性                   | 型   | 必須 | 説明 |
| ---------                   | ------ | -------- | ----------- |
| `id`                        | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `iids[]`                    | 整数の配列 | いいえ | 指定された`iid`を持つマイルストーンのみを返します。`include_ancestors`が`true`の場合、無視されます。 |
| `state`                     | 文字列 | いいえ | `active`または`closed`のマイルストーンのみを返します。 |
| `title`                     | 文字列 | いいえ | 指定された`title`を持つマイルストーンのみを返します（大文字小文字を区別します）。 |
| `search`                    | 文字列 | いいえ | 指定された文字列に一致するタイトルまたは説明を持つマイルストーンのみを返します（大文字小文字を区別しません）。 |
| `search_title`              | 文字列 | いいえ | 指定された文字列に一致するタイトルを持つマイルストーンのみを返します（大文字小文字を区別しません）。複数の用語は、エスケープされたスペース（`+`または`%20`）で区切って指定できます。これらの用語はANDで結合されます。たとえば`17.4+17.5`は、部分文字列`17.4`および`17.5`（順不同）に一致します。GitLab 11.8で導入されました。 |
| `include_parent_milestones` | ブール値 | いいえ | GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/433298)になりました。代わりに`include_ancestors`を使用してください。 |
| `include_ancestors`         | ブール値 | いいえ | すべての親グループのマイルストーンを含めます。 |
| `include_descendants`       | ブール値 | いいえ | グループとその子孫のマイルストーンを含めます。GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421030)されました。 |
| `updated_before`            | 日時 | いいえ | 指定された日時より前に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |
| `updated_after`             | 日時 | いいえ | 指定された日時より後に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |
| `containing_date`           | 日時 | いいえ | `start_date <= containing_date <= due_date`のマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 13.5で導入されました。 |
| `start_date`                | 日時 | いいえ | 指定された`start_date`が`due_date >=`であるマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。注: `end_date`も指定されている場合にのみ有効です。GitLab 12.8で導入されました。 |
| `end_date`                  | 日時 | いいえ | 指定された`end_date`が`start_date <=`であるマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。注: `start_date`も指定されている場合にのみ有効です。GitLab 12.8で導入されました。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/milestones"
```

応答例:

```json
[
  {
    "id": 12,
    "iid": 3,
    "group_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false,
    "web_url": "https://gitlab.com/groups/gitlab-org/-/milestones/42"
  }
]
```

## 単一のマイルストーンを取得 {#get-single-milestone}

単一のグループマイルストーンを取得します。

```plaintext
GET /groups/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |

## 新しいマイルストーンを作成 {#create-new-milestone}

新しいグループマイルストーンを作成します。

```plaintext
POST /groups/:id/milestones
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `title` | 文字列 | はい | マイルストーンのタイトル |
| `description` | 文字列 | いいえ | マイルストーンの説明 |
| `due_date` | 日付 | いいえ | マイルストーンの期日。ISO 8601形式（`YYYY-MM-DD`） |
| `start_date` | 日付 | いいえ | マイルストーンの開始日。ISO 8601形式（`YYYY-MM-DD`） |

## マイルストーンを編集 {#edit-milestone}

既存のグループマイルストーンを更新します。

```plaintext
PUT /groups/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |
| `title` | 文字列 | いいえ | マイルストーンのタイトル |
| `description` | 文字列 | いいえ | マイルストーンの説明 |
| `due_date` | 日付 | いいえ | マイルストーンの期日。ISO 8601形式（`YYYY-MM-DD`） |
| `start_date` | 日付 | いいえ | マイルストーンの開始日。ISO 8601形式（`YYYY-MM-DD`） |
| `state_event` | 文字列 | いいえ | マイルストーンの状態イベント_(`close`または`activate`)_ |

## グループマイルストーンを削除 {#delete-group-milestone}

グループのデベロッパーロールを持つユーザーのみ。

```plaintext
DELETE /groups/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |

## 単一のマイルストーンに割り当てられたすべてのイシューを取得 {#get-all-issues-assigned-to-a-single-milestone}

単一のグループマイルストーンに割り当てられたすべてのイシューを取得します。

```plaintext
GET /groups/:id/milestones/:milestone_id/issues
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |

現在、このAPIエンドポイントは、サブグループからのイシューを返しません。すべてのマイルストーンのイシューを取得したい場合は、代わりに[イシューのリストAPI](issues.md#list-all-issues)を使用して、特定のマイルストーンでフィルタリングできます（例: `GET /issues?milestone=1.0.0&state=opened`）。

## 単一のマイルストーンに割り当てられたすべてのマージリクエストを取得 {#get-all-merge-requests-assigned-to-a-single-milestone}

単一のグループマイルストーンに割り当てられたすべてのマージリクエストを取得します。

```plaintext
GET /groups/:id/milestones/:milestone_id/merge_requests
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |

## 単一のマイルストーンのすべてのバーンダウンチャートイベントを取得 {#get-all-burndown-chart-events-for-a-single-milestone}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

単一のマイルストーンのすべてのバーンダウンチャートイベントを取得します。

```plaintext
GET /groups/:id/milestones/:milestone_id/burndown_events
```

パラメータは以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数 | はい | グループマイルストーンのID |
