---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プッシュ通知のためにモバイルデバイスを登録および登録解除するためのREST API。
title: モバイルプッシュサブスクリプションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.3で`mobile_push_registration_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248023)されました。デフォルトでは無効になっています。
- GitLab 19.3で`mobile_push_notifications_dispatch`および`mobile_push_notifications`[フラグ](../administration/feature_flags/_index.md)とともに、通知の配信が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248026)されました。デフォルトでは無効になっています。

{{< /history >}}

認証済みユーザーの[To-Doアイテム](todos.md)のプッシュ通知を受け取るためにモバイルデバイスを登録します。すべてのプッシュ通知は、To-Doアイテムに対応しています。デバイスを登録しても、通知自体は配信されません。`mobile_push_notifications_dispatch`機能フラグをインスタンスに対して、`mobile_push_notifications`機能フラグを各ユーザーに対してそれぞれ有効にすることで、配信が有効になります。

## デバイスを登録する {#register-a-device}

認証済みユーザーのデバイストークンを登録します。このエンドポイントは冪等なアップサートです。既存のトークンを再度登録すると、その属性と`last_seen_at`タイムスタンプが更新され、クライアントはアプリケーションの起動ごとに再登録します。リクエストから省略された属性は、トークンがすでに登録されている場合、格納されている値を保持します。別のユーザーに属するトークンを登録すると、認証済みユーザーに再割り当てされます。

各ユーザーは最大20台のデバイスを登録できます。90日間参照されていないサブスクリプションは自動的に削除されます。

```plaintext
POST /user/push_subscriptions
```

サポートされている属性は以下のとおりです: 

| 属性          | タイプ   | 必須 | 説明 |
|--------------------|--------|----------|-------------|
| `device_token`     | 文字列 | はい      | 16進数のAPNsデバイストークン。 |
| `platform`         | 文字列 | いいえ       | デバイスプラットフォーム。`ios`または`macos`のいずれか。新規登録はデフォルトで`ios`になります。 |
| `apns_environment` | 文字列 | いいえ       | トークンが発行されたAPNs環境: `production`または`sandbox`。デフォルト: `production`。 |
| `bundle_id`        | 文字列 | いいえ       | アプリケーションのバンドル識別子。 |
| `device_name`      | 文字列 | いいえ       | 人間が読める形式のデバイス名。 |
| `app_version`      | 文字列 | いいえ       | インストールされているアプリケーションのバージョン。 |
| `locale`           | 文字列 | いいえ       | デバイスのロケール。 |
| `payload_mode`     | 文字列 | いいえ       | `full`はプッシュペイロードで通知コンテンツを送信します。`id_only`は、コンテンツのないペイロードのためにレコード識別子のみを送信します。新規登録はデフォルトで`full`になります。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "device_token=abcdef0123456789abcdef0123456789" \
  --data "apns_environment=sandbox" \
  --url "https://gitlab.example.com/api/v4/user/push_subscriptions"
```

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | タイプ    | 説明 |
|--------------|---------|-------------|
| `id`         | 整数 | サブスクリプションのID。 |
| `created_at` | 文字列  | サブスクリプションが作成された日時（ISO 8601形式）。 |

レスポンス例: 

```json
{
  "id": 1,
  "created_at": "2026-07-30T18:15:31.189Z"
}
```

## デバイスの登録を解除する {#unregister-a-device}

認証済みユーザーのデバイストークンのサブスクリプションを削除します。例えば、サインアウト時などです。トークンはURLではなくリクエストボディで渡されるため、アクセスログには表示されません。成功すると`204 No Content`を返し、一致するサブスクリプションがない場合は`404 Not Found`を返します。

```plaintext
DELETE /user/push_subscriptions
```

サポートされている属性は以下のとおりです: 

| 属性      | タイプ   | 必須 | 説明 |
|----------------|--------|----------|-------------|
| `device_token` | 文字列 | はい      | 16進数のAPNsデバイストークン。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "device_token=abcdef0123456789abcdef0123456789" \
  --url "https://gitlab.example.com/api/v4/user/push_subscriptions"
```
