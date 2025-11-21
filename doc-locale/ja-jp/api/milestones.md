---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトマイルストーンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[project milestones](../user/project/milestones/_index.md)を管理します。

グループマイルストーンには、[group milestones API](group_milestones.md)を使用します。

## プロジェクトマイルストーンの一覧 {#list-project-milestones}

プロジェクトマイルストーンのリストを返します。

```plaintext
GET /projects/:id/milestones
GET /projects/:id/milestones?iids[]=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?title=1.0
GET /projects/:id/milestones?search=version
GET /projects/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
```

パラメータは以下のとおりです:

| 属性                         | 型   | 必須 | 説明 |
| ----------------------------      | ------ | -------- | ----------- |
| `id`                              | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `iids[]`                          | 整数の配列 | いいえ | 指定された`iid`IDを持つマイルストーンのみを返します。`include_ancestors`が`true`の場合、無視されます。  |
| `state`                           | 文字列 | いいえ | `active`または`closed`のマイルストーンのみを返します |
| `title`                           | 文字列 | いいえ | 指定された`title`を持つマイルストーンのみを返します |
| `search`                          | 文字列 | いいえ | 指定された文字列に一致するタイトルまたは説明を持つマイルストーンのみを返します |
| `include_parent_milestones`       | ブール値 | いいえ | GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/433298)になりました。代わりに`include_ancestors`を使用してください。 |
| `include_ancestors`               | ブール値 | いいえ | すべての親グループからのマイルストーンを含めます。 |
| `updated_before`                  | 日時 | いいえ | 指定された日時より前に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |
| `updated_after`                   | 日時 | いいえ | 指定された日時より後に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/milestones"
```

レスポンス例:

```json
[
  {
    "id": 12,
    "iid": 3,
    "project_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false
  }
]
```

## 単一のマイルストーンを取得 {#get-single-milestone}

単一のプロジェクトマイルストーンを取得します。

```plaintext
GET /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |

## 新しいマイルストーンを作成 {#create-new-milestone}

新しいプロジェクトマイルストーンを作成します。

```plaintext
POST /projects/:id/milestones
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `title`       | 文字列         | はい      | マイルストーンのタイトル                                                                                        |
| `description` | 文字列         | いいえ       | マイルストーンの説明                                                                                |
| `due_date`    | 文字列         | いいえ       | マイルストーンの期日（`YYYY-MM-DD`）                                                                    |
| `start_date`  | 文字列         | いいえ       | マイルストーンの開始日（`YYYY-MM-DD`）                                                                  |

## マイルストーンを編集 {#edit-milestone}

既存のプロジェクトマイルストーンを更新します。

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |
| `title`        | 文字列         | いいえ       | マイルストーンのタイトル                                                                                        |
| `description`  | 文字列         | いいえ       | マイルストーンの説明                                                                                |
| `due_date`     | 文字列         | いいえ       | マイルストーンの期日（`YYYY-MM-DD`）                                                                    |
| `start_date`   | 文字列         | いいえ       | マイルストーンの開始日（`YYYY-MM-DD`）                                                                  |
| `state_event`  | 文字列         | いいえ       | マイルストーンの状態イベント（closeまたはactivate）                                                            |

## プロジェクトマイルストーンを削除 {#delete-project-milestone}

{{< history >}}

- GitLab 15.0で、最小ユーザーロールがデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

プロジェクトのプランナーロール以上のユーザーのみが対象です。

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |

## 単一のマイルストーンに割り当てられたすべてのイシューを取得 {#get-all-issues-assigned-to-a-single-milestone}

単一のプロジェクトマイルストーンに割り当てられたすべてのイシューを取得します。

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |

## 単一のマイルストーンに割り当てられたすべてのマージリクエストを取得 {#get-all-merge-requests-assigned-to-a-single-milestone}

単一のプロジェクトマイルストーンに割り当てられたすべてのマージリクエストを取得します。

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |

## プロジェクトマイルストーンをグループマイルストーンにプロモートする {#promote-project-milestone-to-a-group-milestone}

{{< history >}}

- GitLab 15.0で、最小ユーザーロールがデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

グループのプランナーロール以上のユーザーのみが対象です。

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |

## 単一のマイルストーンのすべてのバーンダウンチャートイベントを取得 {#get-all-burndown-chart-events-for-a-single-milestone}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

単一のマイルストーンのすべてのバーンダウンチャートイベントを取得します。

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンID                                                                               |
