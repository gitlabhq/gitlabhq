---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Cubeを使用してGitLabプロダクト分析APIをクエリする。クエリを送信し、アクセストークンを生成し、分析メタデータを取得する。
title: プロダクト分析API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 15.4で、`cube_api_proxy`という名前の[フラグ](../administration/feature_flags/_index.md)と共に導入されました。デフォルトでは無効になっています。
- GitLab 15.10で、`cube_api_proxy`が削除され、`product_analytics_internal_preview`に置き換えられました。
- GitLab 15.11で、`product_analytics_internal_preview`が`product_analytics_dashboards`に置き換えられました。
- GitLab 16.11で、`product_analytics_dashboards`が[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/398653)されました。デフォルトで有効です。
- 機能フラグ`product_analytics_dashboards`がGitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454059)されました。
- GitLab 17.5で[ベータ版](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167296)に変更され、`product_analytics_features`という名前の[フラグ](../administration/feature_flags/_index.md)と共に導入されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能は本番環境での使用には対応していません。

このAPIを使用して、ユーザーの行動とアプリケーションの使用状況を追跡します。

> [!note]
> 最初に[API](settings.md)を使用して、`cube_api_base_url`と`cube_api_key`のアプリケーション設定を定義してください。

## Cubeクエリリクエストを作成する {#create-a-cube-query-request}

Cube APIへのクエリリクエストを作成し、アクセストークンを生成します。

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| 属性       | 型             | 必須 | 説明                                                                                 |
|-----------------|------------------| -------- |---------------------------------------------------------------------------------------------|
| `id`            | 整数          | はい      | 現在のユーザーが読み取りアクセス権を持つプロジェクトのID。                               |
| `include_token` | ブール値          | いいえ       | アクセストークンをレスポンスに含めるかどうか。（ファネル生成にのみ必要です。） |

### リクエスト本文 {#request-body}

読み込みリクエストの本文は、有効なCubeクエリである必要があります。

> [!note]
> `TrackedEvents`を測定する場合、`dimensions`と`timeDimensions`には`TrackedEvents.*`を使用する必要があります。`Sessions`を測定する場合も同じルールが適用されます。

#### 追跡されたイベントの例 {#tracked-events-example}

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

## Cubeメタデータを取得する {#retrieve-cube-metadata}

分析データ用のCubeメタデータを取得します。

```plaintext
GET /projects/:id/product_analytics/request/meta
```

| 属性 | 型             | 必須 | 説明                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | 整数          | はい      | 現在のユーザーが読み取りアクセス権を持つプロジェクトのID。 |
