---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ブロードキャストメッセージAPI
description: ユーザーロールのターゲティング、パスフィルタリング、カスタマイズ可能なテーマでブロードキャストメッセージを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `target_access_levels`はGitLab 14.8で[導入され](https://gitlab.com/gitlab-org/growth/team-tasks/-/issues/461)、`role_targeted_broadcast_messages`という[フラグ](../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- `color`パラメータはGitLab 15.6で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95829)。
- `theme`はGitLab 17.6で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/498900)。

{{< /history >}}

UIに表示されるバナーおよび通知を操作するには、このAPIを使用します。詳細については、[ブロードキャストメッセージ](../administration/broadcast_messages.md)を参照してください。

GETリクエストは認証を必要としません。その他のすべてのブロードキャストメッセージAPIエンドポイントは、管理者のみがアクセスできます。GET以外のリクエストが次の場合:

- ゲストの場合、`401 Unauthorized`となります。
- 一般ユーザーの場合、`403 Forbidden`となります。

## すべてのブロードキャストメッセージを一覧表示 {#list-all-broadcast-messages}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのブロードキャストメッセージを一覧表示します。

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

## ブロードキャストメッセージを取得する {#retrieve-a-broadcast-message}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定されたブロードキャストメッセージを取得する。

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

## ブロードキャストメッセージを作成 {#create-a-broadcast-message}

> [!warning]
> ブロードキャストメッセージは、ターゲティング設定に関係なく、APIを通じて公開されます。機密情報や個人情報を含めたり、特定のグループやプロジェクトに個人情報を伝えるためにブロードキャストメッセージを使用したりしないでください。

ブロードキャストメッセージを作成します。

```plaintext
POST /broadcast_messages
```

パラメータは以下のとおりです:

| 属性              | 型              | 必須 | 説明 |
|:-----------------------|:------------------|:---------|:------------|
| `message`              | 文字列            | はい      | 表示するメッセージ。 |
| `starts_at`            | 日時          | いいえ       | 開始時刻（UTCの現在時刻がデフォルトです）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `ends_at`              | 日時          | いいえ       | 終了時刻（UTCの現在時刻から1時間後がデフォルトです）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `font`                 | 文字列            | いいえ       | 前景色（16進数コード）。 |
| `target_access_levels` | 整数の配列 | いいえ       | ブロードキャストメッセージのターゲットアクセスレベル（ロール）。 |
| `target_path`          | 文字列            | いいえ       | ブロードキャストメッセージのターゲットパス。 |
| `broadcast_type`       | 文字列            | いいえ       | 表示タイプ（バナーがデフォルト）。 |
| `dismissable`          | ブール値           | いいえ       | ユーザーはメッセージを却下できますか？ |
| `theme`                | 文字列            | いいえ       | ブロードキャストメッセージのカラーテーマ（バナーのみ）。 |

`target_access_levels`は`Gitlab::Access`モジュールで定義されています。以下のレベルが有効です:

- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- セキュリティマネージャー（`25`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）

`theme`オプションは`System::BroadcastMessage`クラスで定義されています。以下のテーマが有効です:

- `indigo`（デフォルト）
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

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

## ブロードキャストメッセージを更新 {#update-a-broadcast-message}

> [!warning]
> ブロードキャストメッセージは、ターゲティング設定に関係なく、APIを通じて公開されます。機密情報や個人情報を含めたり、特定のグループやプロジェクトに個人情報を伝えるためにブロードキャストメッセージを使用したりしないでください。

指定されたブロードキャストメッセージを更新します。

```plaintext
PUT /broadcast_messages/:id
```

パラメータは以下のとおりです:

| 属性              | 型              | 必須 | 説明 |
|:-----------------------|:------------------|:---------|:------------|
| `id`                   | 整数           | はい      | 更新するブロードキャストメッセージのID。 |
| `message`              | 文字列            | いいえ       | 表示するメッセージ。 |
| `starts_at`            | 日時          | いいえ       | 開始時刻（UTC）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `ends_at`              | 日時          | いいえ       | 終了時刻（UTC）。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `font`                 | 文字列            | いいえ       | 前景色（16進数コード）。 |
| `target_access_levels` | 整数の配列 | いいえ       | ブロードキャストメッセージのターゲットアクセスレベル（ロール）。 |
| `target_path`          | 文字列            | いいえ       | ブロードキャストメッセージのターゲットパス。 |
| `broadcast_type`       | 文字列            | いいえ       | 表示タイプ（バナーがデフォルト）。 |
| `dismissable`          | ブール値           | いいえ       | ユーザーはメッセージを却下できますか？ |
| `theme`                | 文字列            | いいえ       | ブロードキャストメッセージのカラーテーマ（バナーのみ）。 |

`target_access_levels`は`Gitlab::Access`モジュールで定義されています。以下のレベルが有効です:

- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）

`theme`オプションは`System::BroadcastMessage`クラスで定義されています。以下のテーマが有効です:

- `indigo`（デフォルト）
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

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

## ブロードキャストメッセージを削除 {#delete-a-broadcast-message}

指定されたブロードキャストメッセージを削除します。

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
