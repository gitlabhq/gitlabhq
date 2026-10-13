---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: バッチバックグラウンド移行を一覧表示、取得、一時停止、再開するためのREST API。
title: バッチバックグラウンド移行API
ignore_in_report: true
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIを使用して、[バッチバックグラウンド移行](../../update/background_migrations.md)を監視および管理します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## 過去20件のバッチバックグラウンド移行を一覧表示 {#list-the-last-20-batched-background-migrations}

すべてのバッチバックグラウンド移行を一覧表示します。

```plaintext
GET /api/v4/admin/batched_background_migrations
```

サポートされている属性は以下のとおりです: 

| 属性        | タイプ   | 必須 | 説明 |
|------------------|--------|----------|-------------|
| `database`       | 文字列 | いいえ       | データベース名。`main`がデフォルトです。 |
| `job_class_name` | 文字列 | いいえ       | ジョブクラス名で移行をフィルタリングします。 |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                  | タイプ     | 説明 |
|----------------------------|----------|-------------|
| `column_name`              | 文字列   | 移行が処理するカラムの名称。 |
| `created_at`               | 日時 | 移行が作成されたタイムスタンプ。 |
| `estimated_time_remaining` | 文字列   | 移行が完了するまでの推定時間。nullの場合があります |
| `id`                       | 整数  | バッチバックグラウンド移行のID。 |
| `job_class_name`           | 文字列   | 移行ジョブクラスの名称。 |
| `progress`                 | 浮動小数点数    | 移行の完了割合。 |
| `status`                   | 文字列   | 移行のステータス。`paused`、`active`、`finished`、`failed`、`finalizing`、または`finalized`のいずれかです。 |
| `table_name`               | 文字列   | 移行が処理するテーブルの名称。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations"
```

レスポンス例: 

```json
[
  {
    "id": 1234,
    "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
    "table_name": "events",
    "column_name": "id",
    "status": "active",
    "progress": 50.0,
    "created_at": "2022-11-28T16:26:39+02:00",
    "estimated_time_remaining": "1 day"
  }
]
```

## バッチバックグラウンド移行を取得する {#retrieve-a-batched-background-migration}

バッチバックグラウンド移行を取得します。

```plaintext
GET /api/v4/admin/batched_background_migrations/:id
```

サポートされている属性は以下のとおりです: 

| 属性  | タイプ    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `id`       | 整数 | はい      | バッチバックグラウンド移行のID。 |
| `database` | 文字列  | いいえ       | データベース名。`main`がデフォルトです。 |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                  | タイプ     | 説明 |
|----------------------------|----------|-------------|
| `column_name`              | 文字列   | 移行が処理するカラムの名称。 |
| `created_at`               | 日時 | 移行が作成されたタイムスタンプ。 |
| `estimated_time_remaining` | 文字列   | 移行が完了するまでの推定時間。 |
| `id`                       | 整数  | バッチバックグラウンド移行のID。 |
| `job_class_name`           | 文字列   | 移行ジョブクラスの名称。 |
| `progress`                 | 浮動小数点数    | 移行の完了割合。 |
| `status`                   | 文字列   | 移行のステータス。`paused`、`active`、`finished`、`failed`、`finalizing`、または`finalized`のいずれかです。 |
| `table_name`               | 文字列   | 移行が処理するテーブルの名称。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234"
```

レスポンス例: 

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "active",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```

## バッチバックグラウンド移行を一時停止する {#pause-a-batched-background-migration}

バッチバックグラウンド移行を一時停止します。`active`ステータスの移行のみ一時停止できます。

```plaintext
PUT /api/v4/admin/batched_background_migrations/:id/pause
```

サポートされている属性は以下のとおりです: 

| 属性  | タイプ    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `id`       | 整数 | はい      | バッチバックグラウンド移行のID。 |
| `database` | 文字列  | いいえ       | データベース名。`main`がデフォルトです。 |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                  | タイプ     | 説明 |
|----------------------------|----------|-------------|
| `column_name`              | 文字列   | 移行が処理するカラムの名称。 |
| `created_at`               | 日時 | 移行が作成されたタイムスタンプ。 |
| `estimated_time_remaining` | 文字列   | 移行が完了するまでの推定時間。 |
| `id`                       | 整数  | バッチバックグラウンド移行のID。 |
| `job_class_name`           | 文字列   | 移行ジョブクラスの名称。 |
| `progress`                 | 浮動小数点数    | 移行の完了割合。 |
| `status`                   | 文字列   | 移行のステータス。`paused`、`active`、`finished`、`failed`、`finalizing`、または`finalized`のいずれかです。 |
| `table_name`               | 文字列   | 移行が処理するテーブルの名称。 |

移行が`active`ステータスでない場合、[`422 Unprocessable Entity`](../rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234/pause"
```

レスポンス例: 

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "paused",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```

## バッチバックグラウンド移行を再開する {#resume-a-batched-background-migration}

バッチバックグラウンド移行を再開します。`paused`ステータスの移行のみ再開できます。

```plaintext
PUT /api/v4/admin/batched_background_migrations/:id/resume
```

サポートされている属性は以下のとおりです: 

| 属性  | タイプ    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `id`       | 整数 | はい      | バッチバックグラウンド移行のID。 |
| `database` | 文字列  | いいえ       | データベース名。`main`がデフォルトです。 |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                  | タイプ     | 説明 |
|----------------------------|----------|-------------|
| `column_name`              | 文字列   | 移行が処理するカラムの名称。 |
| `created_at`               | 日時 | 移行が作成されたタイムスタンプ。 |
| `estimated_time_remaining` | 文字列   | 移行が完了するまでの推定時間。 |
| `id`                       | 整数  | バッチバックグラウンド移行のID。 |
| `job_class_name`           | 文字列   | 移行ジョブクラスの名称。 |
| `progress`                 | 浮動小数点数    | 移行の完了割合。 |
| `status`                   | 文字列   | 移行のステータス。`paused`、`active`、`finished`、`failed`、`finalizing`、または`finalized`のいずれかです。 |
| `table_name`               | 文字列   | 移行が処理するテーブルの名称。 |

移行が`paused`ステータスでない場合、[`422 Unprocessable Entity`](../rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234/resume"
```

レスポンス例: 

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "active",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```
