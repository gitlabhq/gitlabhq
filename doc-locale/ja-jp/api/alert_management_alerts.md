---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アラート管理アラートAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[アラート](../operations/incident_management/alerts.md)のメトリクス画像と対話します。

追加のエンドポイントは、[GraphQL API](graphql/reference/_index.md#alertmanagementalert)で利用できます。

## メトリクスの画像をアップロードする {#upload-metric-image}

指定されたアラートのメトリクス画像をアップロードします。

```plaintext
POST /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `alert_iid` | 整数        | はい      | プロジェクトのアラートの内部ID。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

レスポンス例: 

```json
{
  "id":17,
  "created_at":"2020-11-12T20:07:58.156Z",
  "filename":"sample_2054",
  "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## すべてのメトリクス画像を一覧表示 {#list-all-metric-images}

指定されたアラートのすべてのメトリクス画像を一覧表示します。

```plaintext
GET /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `alert_iid` | 整数        | はい      | プロジェクトのアラートの内部ID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

レスポンス例: 

```json
[
  {
    "id":17,
    "created_at":"2020-11-12T20:07:58.156Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  },
  {
    "id":18,
    "created_at":"2020-11-12T20:14:26.441Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/18/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  }
]
```

## メトリクス画像を更新 {#update-a-metric-image}

指定されたアラートのメトリクス画像を更新します。

```plaintext
PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `alert_iid` | 整数        | はい      | プロジェクトのアラートの内部ID。 |
| `image_id`  | 整数        | はい      | 画像のID。 |
| `url`       | 文字列         | いいえ       | 詳細なメトリクス情報を表示するためのURL。 |
| `url_text`  | 文字列         | いいえ       | 画像またはURLの説明。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

レスポンス例: 

```json
{
  "id":23,
  "created_at":"2020-11-13T00:06:18.084Z",
  "filename":"file.png",
  "file_path":"/uploads/-/system/alert_metric_image/file/23/file.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## メトリクス画像を削除 {#delete-a-metric-image}

指定されたアラートのメトリクス画像を削除します。

```plaintext
DELETE /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `alert_iid` | 整数        | はい      | プロジェクトのアラートの内部ID。 |
| `image_id`  | 整数        | はい      | 画像のID。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url  "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

次のステータスコードを返すことができます。

- `204 No Content`: 画像が正常に削除された場合。
- `422 Unprocessable`: 画像を削除できなかった場合。
