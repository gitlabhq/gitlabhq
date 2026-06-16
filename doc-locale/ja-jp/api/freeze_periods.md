---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: フリーズ期間API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、デプロイ[フリーズ期間](../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)を操作します。

## フリーズ期間を一覧表示 {#list-freeze-periods}

フリーズ期間を昇順にソートしたページ分けされたリスト`created_at`

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/freeze_periods
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
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

## フリーズ期間を取得する {#retrieve-a-freeze-period}

指定された`freeze_period_id`のフリーズ期間を取得します。

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `freeze_period_id`    | 整数         | はい      | フリーズ期間のID。                                     |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
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

## フリーズ期間を作成 {#create-a-freeze-period}

指定されたプロジェクトのフリーズ期間を作成します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
POST /projects/:id/freeze_periods
```

| 属性          | 型            | 必須                    | 説明                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 整数または文字列  | はい                         | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                              |
| `freeze_start`     | 文字列          | はい                         | [cron](https://crontab.guru/)形式のフリーズ期間の開始時刻。                                                              |
| `freeze_end`       | 文字列          | はい                         | [cron](https://crontab.guru/)形式のフリーズ期間の終了時刻。                                                                |
| `cron_timezone`    | 文字列          | いいえ                          | cronフィールドのタイムゾーン。指定しない場合はUTCにデフォルト設定されます。                                                               |

リクエストの例:

```shell
curl --request POST \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
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

## フリーズ期間を更新 {#update-a-freeze-period}

指定された`freeze_period_id`のフリーズ期間を更新します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型            | 必須 | 説明                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                         |
| `freeze_period_id`    | 整数          | はい      | フリーズ期間のID。                                                              |
| `freeze_start`     | 文字列          | いいえ                         | [cron](https://crontab.guru/)形式のフリーズ期間の開始時刻。                                                              |
| `freeze_end`       | 文字列          | いいえ                         | [cron](https://crontab.guru/)形式のフリーズ期間の終了時刻。                                                                |
| `cron_timezone`    | 文字列          | いいえ                          | cronフィールドのタイムゾーン。                                                               |

リクエストの例:

```shell
curl --request PUT \
  --header 'Content-Type: application/json' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{ "freeze_end": "0 8 * * 1" }' \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
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

## フリーズ期間を削除 {#delete-a-freeze-period}

指定された`freeze_period_id`のフリーズ期間を削除します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `freeze_period_id`    | 整数         | はい      | フリーズ期間のID。                                     |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```
