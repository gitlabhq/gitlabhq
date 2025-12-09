---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロダクト分析API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 15.4で[フラグ](../administration/feature_flags/_index.md)とともに`cube_api_proxy`という名前で導入されました。デフォルトでは無効になっています。
- `cube_api_proxy`は削除され、GitLab 15.10で`product_analytics_internal_preview`に置き換えられました。
- `product_analytics_internal_preview`はGitLab 15.11で`product_analytics_dashboards`に置き換えられました。
- `product_analytics_dashboards`は、GitLab 16.11でデフォルトで[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/398653)になりました。
- GitLab 17.1で機能フラグ`product_analytics_dashboards`は[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454059)されました。
- GitLab 17.5で、ベータ版に[フラグ](../administration/feature_flags/_index.md)名`product_analytics_features`で[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167296)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能は本番環境での使用には対応していません。

{{< /alert >}}

このAPIを使用して、ユーザーの行動とアプリケーションの使用状況を追跡します。

{{< alert type="note" >}}

[API](settings.md)を使用して、最初に`cube_api_base_url`および`cube_api_key`アプリケーションの設定を定義してください。

{{< /alert >}}

## Cubeにクエリリクエストを送信する {#send-query-request-to-cube}

Cube APIにクエリするために使用できるアクセストークンを生成します。例: 

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| 属性       | 型             | 必須 | 説明                                                                                 |
|-----------------|------------------| -------- |---------------------------------------------------------------------------------------------|
| `id`            | 整数          | はい      | 現在のユーザーが読み取りアクセスできるプロジェクトのID。                               |
| `include_token` | ブール値          | いいえ       | レスポンスにアクセストークンを含めるかどうか。（ファンネルの生成にのみ必要）。 |

### リクエストボディ {#request-body}

ロードリクエストの本文は、有効なCubeクエリである必要があります。

{{< alert type="note" >}}

`TrackedEvents`を測定する場合は、`dimensions`と`timeDimensions`に`TrackedEvents.*`を使用する必要があります。同じルールは`Sessions`を測定する場合にも適用されます。

{{< /alert >}}

#### 追跡イベントの例 {#tracked-events-example}

```json
{
  "query": {
    "measures": [
      "TrackedEvents.count"
    ],
    "timeDimensions": [
      {
        "dimension": "TrackedEvents.utcTime",
        "dateRange": "This week"
      }
    ],
    "order": [
      [
        "TrackedEvents.count",
        "desc"
      ],
      [
        "TrackedEvents.docPath",
        "desc"
      ],
      [
        "TrackedEvents.utcTime",
        "asc"
      ]
    ],
    "dimensions": [
      "TrackedEvents.docPath"
    ],
    "limit": 23
  },
  "queryType": "multi"
}
```

#### セッションの例 {#sessions-example}

```json
{
  "query": {
    "measures": [
      "Sessions.count"
    ],
    "timeDimensions": [
      {
        "dimension": "Sessions.startAt",
        "granularity": "day"
      }
    ],
    "order": {
      "Sessions.startAt": "asc"
    },
    "limit": 100
  },
  "queryType": "multi"
}
```

## Cubeにメタデータリクエストを送信する {#send-metadata-request-to-cube}

分析データのCubeメタデータを返します。例: 

```plaintext
GET /projects/:id/product_analytics/request/meta
```

| 属性 | 型             | 必須 | 説明                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | 整数          | はい      | 現在のユーザーが読み取りアクセスできるプロジェクトのID。 |
