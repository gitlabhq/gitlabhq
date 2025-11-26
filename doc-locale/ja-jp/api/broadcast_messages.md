---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ブロードキャストメッセージAPI
description: ユーザーロールのターゲティング、パスフィルタリング、およびカスタマイズ可能なテーマを使用して、ブロードキャストメッセージを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `target_access_levels`は、GitLab 14.8で`role_targeted_broadcast_messages`という[フラグ付き](../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/growth/team-tasks/-/issues/461)。デフォルトでは無効になっています。
- `color`パラメータはGitLab 15.6で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95829)。
- `theme`は、GitLab 17.6で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/498900)。

{{< /history >}}

このAPIを使用して、UIに表示されるバナーと通知を操作します。詳細については、[ブロードキャストメッセージ](../administration/broadcast_messages.md)を参照してください。

GETリクエストは認証を必要としません。他のすべてのブロードキャストメッセージAPIエンドポイントは、管理者のみがアクセスできます。Non-GETリクエスト:

- ゲストは`401 Unauthorized`になります。
- 通常のユーザーは`403 Forbidden`になります。

## すべてのブロードキャストメッセージを取得する {#get-all-broadcast-messages}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのブロードキャストメッセージをリストします。

```plaintext
GET /broadcast_messages
```

リクエスト例:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages"
```

レスポンス例:

```json
[
    {
        "message":"Example broadcast message",
        "starts_at":"2016-08-24T23:21:16.078Z",
        "ends_at":"2016-08-26T23:21:16.080Z",
        "font":"#FFFFFF",
        "id":1,
        "active": false,
        "target_access_levels": [10,30],
        "target_path": "*/welcome",
        "broadcast_type": "banner",
        "dismissable": false,
        "theme": "indigo"
    }
]
```

## 特定のブロードキャストメッセージを取得する {#get-a-specific-broadcast-message}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定のブロードキャストメッセージを取得します。

```plaintext
GET /broadcast_messages/:id
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明                          |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 整数 | はい      | 取得するブロードキャストメッセージのID。 |

リクエスト例:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

レスポンス例:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-24T23:21:16.078Z",
    "ends_at":"2016-08-26T23:21:16.080Z",
    "font":"#FFFFFF",
    "id":1,
    "active":false,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "banner",
    "dismissable": false,
    "theme": "indigo"
}
```

## ブロードキャストメッセージを作成する {#create-a-broadcast-message}

{{< alert type="warning" >}}

ブロードキャストメッセージは、ターゲティング設定に関係なく、APIを介して公開でアクセスできます。機密情報や個人的な情報を含めないでください。また、特定のグループまたはプロジェクトに個人的な情報を伝達するためにブロードキャストメッセージを使用しないでください。

{{< /alert >}}

新しいブロードキャストメッセージを作成します。

```plaintext
POST /broadcast_messages
```

パラメータは以下のとおりです:

| 属性              | 型              | 必須 | 説明                                           |
|:-----------------------|:------------------|:---------|:------------------------------------------------------|
| `message`              | 文字列            | はい      | 表示するメッセージ。                                   |
| `starts_at`            | 日時          | いいえ       | 開始時間（デフォルトはUTCの現在時刻）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定してください。 |
| `ends_at`              | 日時          | いいえ       | 終了時間（デフォルトはUTCの現在時刻から1時間）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定してください。 |
| `font`                 | 文字列            | いいえ       | 前景色の16進数コード。                            |
| `target_access_levels` | 整数の配列 | いいえ       | ブロードキャストメッセージのターゲットアクセスレベル（ロール）。|
| `target_path`          | 文字列            | いいえ       | ブロードキャストメッセージのターゲットパス。                 |
| `broadcast_type`       | 文字列            | いいえ       | 外観タイプ（デフォルトはバナー）                  |
| `dismissable`          | ブール値           | いいえ       | ユーザーはメッセージを無視できますか？                     |
| `theme`                | 文字列            | いいえ       | ブロードキャストメッセージの配色テーマ（バナーのみ）。 |

`target_access_levels`は、`Gitlab::Access`モジュールで定義されています。次のレベルが有効です:

- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）

`theme`オプションは、`System::BroadcastMessage`クラスで定義されています。次のテーマが有効です:

- インディゴ（デフォルト）
- ライトインディゴ
- 青
- ライトブルー
- 緑
- ライトグリーン
- 赤
- ライトレッド
- ダーク
- ライト

リクエスト例:

```shell
curl --data "message=Deploy in progress&target_access_levels[]=10&target_access_levels[]=30&theme=red" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages"
```

レスポンス例:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "red"
}
```

## ブロードキャストメッセージを更新する {#update-a-broadcast-message}

{{< alert type="warning" >}}

ブロードキャストメッセージは、ターゲティング設定に関係なく、APIを介して公開でアクセスできます。機密情報や個人的な情報を含めないでください。また、特定のグループまたはプロジェクトに個人的な情報を伝達するためにブロードキャストメッセージを使用しないでください。

{{< /alert >}}

既存のブロードキャストメッセージを更新します。

```plaintext
PUT /broadcast_messages/:id
```

パラメータは以下のとおりです:

| 属性              | 型              | 必須 | 説明                                           |
|:-----------------------|:------------------|:---------|:------------------------------------------------------|
| `id`                   | 整数           | はい      | 更新するブロードキャストメッセージのID。                    |
| `message`              | 文字列            | いいえ       | 表示するメッセージ。                                   |
| `starts_at`            | 日時          | いいえ       | 開始時間（UTC）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定してください。 |
| `ends_at`              | 日時          | いいえ       | 終了時間（UTC）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定してください。 |
| `font`                 | 文字列            | いいえ       | 前景色の16進数コード。                            |
| `target_access_levels` | 整数の配列 | いいえ       | ブロードキャストメッセージのターゲットアクセスレベル（ロール）。|
| `target_path`          | 文字列            | いいえ       | ブロードキャストメッセージのターゲットパス。                 |
| `broadcast_type`       | 文字列            | いいえ       | 外観タイプ（デフォルトはバナー）                  |
| `dismissable`          | ブール値           | いいえ       | ユーザーはメッセージを無視できますか？                     |
| `theme`                | 文字列            | いいえ       | ブロードキャストメッセージの配色テーマ（バナーのみ）。 |

`target_access_levels`は、`Gitlab::Access`モジュールで定義されています。次のレベルが有効です:

- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）

`theme`オプションは、`System::BroadcastMessage`クラスで定義されています。次のテーマが有効です:

- インディゴ（デフォルト）
- ライトインディゴ
- 青
- ライトブルー
- 緑
- ライトグリーン
- 赤
- ライトレッド
- ダーク
- ライト

リクエスト例:

```shell
curl --request PUT \
  --data "message=Update message" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

レスポンス例:

```json
{
    "message":"Update message",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "indigo"
}
```

## ブロードキャストメッセージを削除する {#delete-a-broadcast-message}

ブロードキャストメッセージを削除します。

```plaintext
DELETE /broadcast_messages/:id
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明                        |
|:----------|:--------|:---------|:-----------------------------------|
| `id`      | 整数 | はい      | 削除するブロードキャストメッセージのID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```
