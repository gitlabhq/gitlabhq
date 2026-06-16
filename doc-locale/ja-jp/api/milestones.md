---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトマイルストーンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[プロジェクトマイルストーン](../user/project/milestones/_index.md)を管理します。

グループマイルストーンについては、[グループマイルストーンAPI](group_milestones.md)を使用します。

## すべてのプロジェクトマイルストーンを一覧表示 {#list-all-project-milestones}

プロジェクトのすべてのマイルストーンを一覧表示します。

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
| `iids[]`                          | 整数の配列 | いいえ | 指定された`iid`を持つマイルストーンのみを返します。`include_ancestors`が`true`の場合、無視されます。  |
| `state`                           | 文字列 | いいえ | `active`または`closed`のマイルストーンのみを返します。 |
| `title`                           | 文字列 | いいえ | 指定された`title`を持つマイルストーンのみを返します。 |
| `search`                          | 文字列 | いいえ | 指定された文字列に一致するタイトルまたは説明を持つマイルストーンのみを返します。 |
| `include_parent_milestones`       | ブール値 | いいえ | GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/433298)になりました。代わりに`include_ancestors`を使用してください。 |
| `include_ancestors`               | ブール値 | いいえ | すべての親グループからのマイルストーンを含めます。 |
| `updated_before`                  | 日時 | いいえ | 指定された日時より前に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |
| `updated_after`                   | 日時 | いいえ | 指定された日時より後に更新されたマイルストーンのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で導入されました。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/milestones"
```

応答例:

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

## マイルストーンを取得する {#retrieve-a-milestone}

指定されたプロジェクトマイルストーンを取得します。

```plaintext
GET /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |

## マイルストーンを作成する {#create-a-milestone}

プロジェクトマイルストーンを作成します。

```plaintext
POST /projects/:id/milestones
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `title`       | 文字列         | はい      | マイルストーンのタイトル                                                                                        |
| `description` | 文字列         | いいえ       | マイルストーンの説明                                                                                |
| `due_date`    | 文字列         | いいえ       | マイルストーンの期日 (`YYYY-MM-DD`)                                                                    |
| `start_date`  | 文字列         | いいえ       | マイルストーンの開始日 (`YYYY-MM-DD`)                                                                  |

## マイルストーンを更新 {#update-a-milestone}

指定されたプロジェクトマイルストーンを更新します。

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |
| `title`        | 文字列         | いいえ       | マイルストーンのタイトル                                                                                        |
| `description`  | 文字列         | いいえ       | マイルストーンの説明                                                                                |
| `due_date`     | 文字列         | いいえ       | マイルストーンの期日 (`YYYY-MM-DD`)                                                                    |
| `start_date`   | 文字列         | いいえ       | マイルストーンの開始日 (`YYYY-MM-DD`)                                                                  |
| `state_event`  | 文字列         | いいえ       | マイルストーンの状態イベント（クローズまたはアクティブ化）                                                            |

## マイルストーンを削除する {#delete-a-milestone}

{{< history >}}

- GitLab 15.0で、最小ユーザーロールがデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

指定されたプロジェクトマイルストーンを削除します。

プロジェクトのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみが対象です。

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |

## マイルストーンのすべてのイシューを一覧表示 {#list-all-issues-for-a-milestone}

指定されたプロジェクトマイルストーンに割り当てられたすべてのイシューを一覧表示します。

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |

## マイルストーンのすべてのマージリクエストを一覧表示 {#list-all-merge-requests-for-a-milestone}

指定されたプロジェクトマイルストーンに割り当てられたすべてのマージリクエストを一覧表示します。

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |

## マイルストーンをグループマイルストーンにプロモート {#promote-a-milestone-to-group-milestone}

{{< history >}}

- GitLab 15.0で、最小ユーザーロールがデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/343889)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

プロジェクトマイルストーンをグループマイルストーンにプロモートします。

グループのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみが対象です。

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |

## マイルストーンのすべてのバーンダウンチャートイベントを一覧表示 {#list-all-burndown-chart-events-for-a-milestone}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定されたマイルストーンのすべてのバーンダウンチャートイベントを一覧表示します。

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `milestone_id` | 整数        | はい      | プロジェクトのマイルストーンのID                                                                               |
