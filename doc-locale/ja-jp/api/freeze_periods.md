---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フリーズ期間API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、デプロイメント[freeze periods](../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)を操作します。

## パーミッションとセキュリティ {#permissions-and-security}

レポーター以上の[パーミッション](../user/permissions.md)を持つユーザーは、Freeze Period APIエンドポイントを読み取り可能です。メンテナーロールを持つユーザーのみが、Freeze Periodを変更できます。

## Freeze periodの一覧表示 {#list-freeze-periods}

昇順で`created_at`でソートされた、freeze periodのページ分割されたリスト。

```plaintext
GET /projects/:id/freeze_periods
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

レスポンス例:

```json
[
   {
      "id":1,
      "freeze_start":"0 23 * * 5",
      "freeze_end":"0 8 * * 1",
      "cron_timezone":"UTC",
      "created_at":"2020-05-15T17:03:35.702Z",
      "updated_at":"2020-05-15T17:06:41.566Z"
   }
]
```

## Freeze periodの取得 {#get-a-freeze-period}

指定された`freeze_period_id`のfreeze periodを取得します。

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `freeze_period_id`    | 整数         | はい      | Freeze periodのID。                                     |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

レスポンス例:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Freeze periodの作成 {#create-a-freeze-period}

Freeze periodを作成します。

```plaintext
POST /projects/:id/freeze_periods
```

| 属性          | 型            | 必須                    | 説明                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 整数または文字列  | はい                         | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                              |
| `freeze_start`     | 文字列          | はい                         | [cron](https://crontab.guru/)形式でのフリーズ期間の開始。                                                              |
| `freeze_end`       | 文字列          | はい                         | [cron](https://crontab.guru/)形式でのフリーズ期間の終了。                                                                |
| `cron_timezone`    | 文字列          | いいえ                          | cronフィールドのタイムゾーン。指定しない場合のデフォルトはUTCです。                                                               |

リクエスト例:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
     --request POST "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

レスポンス例:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 7 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:03:35.702Z"
}
```

## Freeze periodの更新 {#update-a-freeze-period}

指定された`freeze_period_id`のfreeze periodを更新します。

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型            | 必須 | 説明                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                         |
| `freeze_period_id`    | 整数          | はい      | Freeze periodのID。                                                              |
| `freeze_start`     | 文字列          | いいえ                         | [cron](https://crontab.guru/)形式でのフリーズ期間の開始。                                                              |
| `freeze_end`       | 文字列          | いいえ                         | [cron](https://crontab.guru/)形式でのフリーズ期間の終了。                                                                |
| `cron_timezone`    | 文字列          | いいえ                          | cronフィールドのタイムゾーン。                                                               |

リクエスト例:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_end": "0 8 * * 1" }' \
     --request PUT "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

レスポンス例:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Freeze periodの削除 {#delete-a-freeze-period}

指定された`freeze_period_id`のfreeze periodを削除します。

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `freeze_period_id`    | 整数         | はい      | Freeze periodのID。                                     |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"

```
