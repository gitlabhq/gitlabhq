---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedインスタンスのステータスとメンテナンスウィンドウを取得し、設定を更新するためのREST API。
title: スイッチボードカスタマーAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

このAPIを使用して、[GitLab Dedicated](_index.md)インスタンスのステータスとメンテナンスウィンドウを取得し、Switchboardコンソールで編集できる設定を更新します。

このAPIは、テナント管理者アクセス権を持つインスタンスのデータのみを返します。パスにインスタンスを指定しません。APIはアクセス権からインスタンスを取得します。

すべてのエンドポイントは、このベースURLを使用します:

```plaintext
https://console.gitlab-dedicated.com/api/customer/v1
```

Switchboardコンソールが異なるURLを使用している場合は、サインインするコンソールのURLを使用します。クライアントIDとエンドポイントパスは、すべてのコンソールで同じです。

前提条件: 

- Switchboardでインスタンスのテナント管理者アクセス権が必要です。

## 認証 {#authentication}

各リクエストには、`Authorization`ヘッダーにSwitchboard OAuth 2.0アクセストークンが必要です。

SwitchboardはProof Key for Code Exchange（PKCE）を使用したOAuth 2.0認可コードフローを通じてトークンを提供します。パブリッククライアント`switchboard_customer_api_auth`を使用します。このクライアントにはクライアントシークレットがありません。`read_write`スコープをリクエストします。

アクセストークンは24時間後に失効します。トークンレスポンスにはリフレッシュトークンも含まれます。リフレッシュトークンを使用すると、ブラウザでのサインインなしで新しいアクセストークンを取得できます。

### アクセストークンを取得する {#get-an-access-token}

標準に準拠した任意のOAuth 2.0クライアントを使用できます。この例では[oauth2c](https://github.com/cloudentity/oauth2c)を使用します。

アクセストークンを取得するには、次の手順に従います:

1. このコマンドを実行します:

   ```shell
   oauth2c https://console.gitlab-dedicated.com \
     --client-id switchboard_customer_api_auth \
     --grant-type authorization_code \
     --response-types code \
     --response-mode query \
     --auth-method none \
     --scopes read_write \
     --pkce \
     --redirect-url http://localhost:3290/callback \
     --authorization-endpoint https://console.gitlab-dedicated.com/oauth/authorize \
     --token-endpoint https://console.gitlab-dedicated.com/oauth/token
   ```

   このコマンドを実行すると、ブラウザが開きます。
1. Switchboardにサインインします。
1. リクエストを承認します。

このコマンドは`http://localhost:3290/callback`でコールバックを取得し、アクセストークンを表示します。各リクエストでトークンを送信します:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/sla_status"
```

### アクセストークンを更新する {#refresh-an-access-token}

ブラウザでのサインインなしで新しいトークンペアを取得するには、リフレッシュトークンをトークンエンドポイントに送信します:

```shell
curl --request POST \
  --url "https://console.gitlab-dedicated.com/oauth/token" \
  --data "grant_type=refresh_token" \
  --data "client_id=switchboard_customer_api_auth" \
  --data "refresh_token=<your_refresh_token>"
```

更新のたびに、新しいリフレッシュトークンが返されます。最新のリフレッシュトークンを保持してください。

ブラウザでの最初のサインインから最大30日間、トークンを更新できます。30日経過後、またはSwitchboardがトークンを失効させた場合、トークンエンドポイントは`invalid_grant`を返します。続行するには、ブラウザでサインインして新しいアクセストークンを取得します。

## レート制限 {#rate-limits}

Switchboardは、各アクセストークンと各送信元IPアドレスのリクエストを1分間のウィンドウでカウントします。

| 制限 | 1分あたりのリクエスト数 |
|-------|--------------------------|
| 各アクセストークン | 60 |
| 各送信元IPアドレス | 120 |
| トークンエンドポイント（`/oauth/token`）、各送信元IPアドレス | 20 |

制限が適用される場合、レスポンスには最大値に最も近い制限のヘッダーが含まれます:

| ヘッダー | 説明 |
|--------|-------------|
| `RateLimit-Limit` | 現在のウィンドウで制限が許可するリクエスト数。 |
| `RateLimit-Remaining` | 現在のウィンドウで制限がまだ許可しているリクエスト数。 |
| `RateLimit-Reset` | 現在のウィンドウがリセットされるUnix時間（秒単位）。この値は時刻であり、カウントダウンではありません。 |

レスポンスにこれらのヘッダーがない場合、リクエストに制限は適用されていません。ヘッダー内の値を使用してください。表の数値を固定値として使用しないでください。

リクエストが制限を超えた場合、APIは`429 Too Many Requests`を返します。`Retry-After`ヘッダーには、待機する秒数が示されます。制限を超えている間に行ったリクエストも、制限にカウントされます。クライアントがリクエストの送信を続ける場合、ウィンドウがリセットされるまでブロックされたままになります。

## エラー {#errors}

すべてのエンドポイントは、これらのステータスコードを返すことがあります:

| ステータスコード | 説明 |
|-------------|-------------|
| `401 Unauthorized` | アクセストークンが無効であるか、リクエストにアクセストークンがありません。 |
| `403 Forbidden` | 必要なアクセス権がありません。 |
| `404 Not Found` | カスタマーAPIがインスタンスで使用できないか、項目が存在しません。 |
| `422 Unprocessable Entity` | Switchboardが変更を受け入れませんでした。レスポンスボディに問題が示されます。 |
| `429 Too Many Requests` | リクエストがレート制限を超えています。 |

エラーレスポンスには`message`属性があります。エラーによっては、詳細情報を含む`errors`属性もあります。

## ページネーション {#pagination}

リストエンドポイントは、項目の1ページ分を返します。これらの属性を使用してページを選択します:

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `page` | 整数 | いいえ | ページ番号。最初のページは`1`です。 |
| `per_page` | 整数 | いいえ | 各ページの項目数。最大値は`100`です。 |

レスポンスには`items`配列と`meta`オブジェクトが含まれます:

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `meta.current_page` | 整数 | このレスポンスのページ番号。 |
| `meta.total` | 整数 | すべてのページの項目数。 |
| `meta.total_pages` | 整数 | ページ数。 |

## インスタンスの詳細を取得する {#retrieve-instance-details}

インスタンスの詳細を取得します。

```plaintext
GET /tenant
```

成功した場合、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `ever_deployed` | ブール値 | インスタンスが初めてデプロイされた後は`true`です。プロビジョニング解除後も、値は`true`のままです。 |
| `external_url` | 文字列 | GitLabインスタンスのURL。 |
| `gitlab_version` | 文字列 | 現在、インスタンスで使用しているGitLabのバージョン。 |
| `identifier` | 文字列 | インスタンスの安定した識別子。インスタンスについてサポートに問い合わせる際は、この値を使用します。 |
| `name` | 文字列 | インスタンスの表示名。 |
| `prerelease_version` | 文字列 | インスタンスでプレリリースバージョンを実行している場合の、インスタンスのプレリリースバージョン。それ以外の場合は`null`です。 |
| `reference_architecture_label` | 文字列 | インスタンスのサイズ。例: `Up to 10,000 users (XL)`。 |
| `regions` | オブジェクト | インスタンスのクラウドリージョン: `primary`、`backup`、`sites`。インスタンスのクラウドアカウントが設定される前は`null`です。 |

リクエスト例: 

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant"
```

レスポンス例: 

```json
{
  "identifier": "example1a2b3c",
  "name": "Example Corp",
  "external_url": "https://example.gitlab-dedicated.com",
  "gitlab_version": "19.3.3",
  "prerelease_version": null,
  "reference_architecture_label": "Up to 10,000 users (XL)",
  "ever_deployed": true,
  "regions": {
    "primary": "eu-west-1",
    "backup": "eu-central-1",
    "sites": ["eu-west-1"]
  }
}
```

## SLAステータスを取得する {#retrieve-sla-status}

インスタンスの最新の可用性ステータスを取得します。このステータスは、Switchboardの**健全性**ページと同じデータを表示します。

> [!note]
> このステータスは、契約上のサービスレベルアグリーメント（SLA）ではありません。GitLabは月次SLAを個別に計算し、独自の集計と除外事項を適用します。1回の`down`ステータスは、SLAの違反を示すものではありません。このAPIは履歴データを返しません。これをモニタリングフィードやアラートフィードとして使用しないでください。

```plaintext
GET /tenant/sla_status
```

成功した場合、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `covered_experiences` | 配列 | 各対象エクスペリエンスのステータス（例: `web`、`git_operations`、`api`、`package_registry`）。各項目には`covered_experience`、`status`、`data_as_of`があります。`data_available`が`false`の場合は空です。 |
| `data_as_of` | 文字列 | Switchboardが観測した最新の1分間のUTC時刻。`data_available`が`false`の場合は`null`です。 |
| `data_available` | ブール値 | レスポンスにステータスがある場合は`true`です。レスポンスに`reason`がある場合は`false`です。 |
| `reason` | 文字列 | ステータスが利用できない理由。`data_available`が`false`の場合にのみ設定されます。 |
| `status` | 文字列 | Switchboardが観測した最新の1分間のインスタンスのステータス。`data_available`が`false`の場合は`null`です。 |

`status`属性には、次のいずれかの値があります:

| 値 | 説明 |
|-------|-------------|
| `up` | インスタンスに既知の問題はありません。 |
| `down` | インスタンスにサービス障害が発生しています。 |
| `maintenance_window` | インスタンスは計画的なメンテナンス中です。 |
| `insufficient_traffic` | インスタンスのトラフィックが少なすぎて、可用性を計算できません。このステータスは、インスタンスが静かなときによく見られます。これは、障害が発生していることを示すものではありません。 |

`reason`属性には、次のいずれかの値があります:

| 値 | 説明 |
|-------|-------------|
| `not_configured` | インスタンスでSLAレポートが有効になっていません。SLAレポートが必要な場合は、サポートにお問い合わせください。 |
| `no_data` | SLAレポートは有効になっていますが、Switchboardには過去6時間のデータがありません。この値は、新しいインスタンスの場合や、レポートが短時間停止した場合によく見られます。 |
| `upstream_error` | Switchboardはデータの取得時に一時的なエラーが発生しました。しばらくしてから再試行してください。 |

リクエスト例: 

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/sla_status"
```

レスポンス例: 

```json
{
  "data_available": true,
  "status": "up",
  "data_as_of": "2026-10-08T09:41:00.000Z",
  "reason": null,
  "covered_experiences": [
    { "covered_experience": "web", "status": "up", "data_as_of": "2026-10-08T09:41:00.000Z" },
    { "covered_experience": "git_operations", "status": "up", "data_as_of": "2026-10-08T09:41:00.000Z" }
  ]
}
```

## すべてのメンテナンスウィンドウを一覧表示する {#list-all-maintenance-windows}

インスタンスの計画されたすべてのメンテナンスウィンドウを一覧表示します。このリストには、今後のウィンドウと完了したウィンドウが含まれます。

```plaintext
GET /tenant/maintenances
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `page` | 整数 | いいえ | ページ番号。 |
| `per_page` | 整数 | いいえ | 各ページの項目数。最大値は`100`です。 |
| `scope` | 文字列 | いいえ | 返されるウィンドウ: `all`（デフォルト）、`upcoming`、または`past`。`upcoming`では、最も近いウィンドウが最初に表示されます。`all`と`past`では、最新のウィンドウが最初に表示されます。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と`items`配列が返されます。各項目には、次の属性があります:

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `approval_status` | 文字列 | `pending`、`approved`、`rejected`のいずれかを指定します。 |
| `completed_at` | 文字列 | メンテナンスが完了した時刻。メンテナンスが完了するまでは`null`です。 |
| `emergency` | ブール値 | 通常のウィンドウ外の緊急メンテナンスの場合は`true`です。 |
| `end_at` | 文字列 | ウィンドウの予定終了時刻。 |
| `gitlab_version` | 文字列 | メンテナンスでデプロイされるGitLabバージョン。 |
| `gitlab_version_pinned` | ブール値 | インスタンスのGitLabバージョンアップグレードが保留されている場合は`true`です。 |
| `id` | 整数 | メンテナンスウィンドウのID。 |
| `previous_gitlab_version` | 文字列 | メンテナンス前のGitLabバージョン。今後のウィンドウの場合は、現在インスタンスで使用しているバージョン。 |
| `start_at` | 文字列 | ウィンドウの予定開始時刻。 |
| `started_at` | 文字列 | メンテナンスが開始された時刻。メンテナンスが開始されるまでは`null`です。 |
| `status` | 文字列 | `planned`、`running`、`completed`、`failed`、`interrupted`、`not_run`のいずれかを指定します。 |

`scope`の値が不明な場合、APIは`422 Unprocessable Entity`を返します。

リクエスト例: 

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/maintenances?scope=upcoming"
```

レスポンス例: 

```json
{
  "items": [
    {
      "id": 4821,
      "start_at": "2026-10-11T21:00:00.000Z",
      "end_at": "2026-10-12T01:00:00.000Z",
      "started_at": null,
      "completed_at": null,
      "status": "planned",
      "approval_status": "approved",
      "emergency": false,
      "gitlab_version": "19.3.4",
      "previous_gitlab_version": "19.3.3",
      "gitlab_version_pinned": false
    }
  ],
  "meta": { "current_page": 1, "total": 1, "total_pages": 1 }
}
```

## すべての設定変更を一覧表示する {#list-all-configuration-changes}

インスタンスのすべての設定変更を、最新の変更から順に一覧表示します。各変更には、何が、いつ変更されたか、そしてその変更がインスタンスに適用されているかどうかが表示されます。

```plaintext
GET /tenant/config_changes
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `page` | 整数 | いいえ | ページ番号。 |
| `per_page` | 整数 | いいえ | 各ページの項目数。最大値は`100`です。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と`items`配列が返されます。各項目には、次の属性があります:

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `completed_at` | 文字列 | 変更がインスタンスに適用された時刻。それまでは`null`です。 |
| `config_type` | 文字列 | 変更された設定の名前。 |
| `id` | 整数 | 変更のID。 |
| `requested_at` | 文字列 | 変更リクエストの時刻。 |
| `status` | 文字列 | `pending`、`queued`、`deployed`、`failed`のいずれかです。 |

リクエスト例: 

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/config_changes?per_page=20"
```

レスポンス例: 

```json
{
  "items": [
    {
      "id": 912,
      "config_type": "IP allowlist",
      "status": "deployed",
      "requested_at": "2026-10-06T14:02:11.000Z",
      "completed_at": "2026-10-06T14:20:47.000Z"
    }
  ],
  "meta": { "current_page": 1, "total": 1, "total_pages": 1 }
}
```

## 設定 {#configuration}

これらのエンドポイントは、Switchboardコンソールで編集できる設定を取得および更新します。各エンドポイントは、コンソールの1つのセクションに対応します。

`PUT`エンドポイントは、セクション全体を置き換えます。必要な設定全体を送信してください。Switchboardは、送信されなかった項目を削除します。1つの項目を変更するには、セクションを取得し、項目を変更して、セクション全体を送り返します。`PUT`エンドポイントは、関連する`GET`エンドポイントのレスポンスをそのまま受け付けます。これらは、Switchboardが設定する属性を無視します。

Switchboardは、インスタンスの設定変更の各変更を記録します。連絡先情報への変更はこの記録には含まれません。

### IP許可リストを取得する {#retrieve-ip-allowlist}

インスタンスのIP許可リストを取得します。

```plaintext
GET /tenant/ip_allowlist
```

成功した場合、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `addresses` | 配列 | 許可されているアドレス。各項目には`address`、`description`、`status`、`created_at`があります。 |
| `addresses[].address` | 文字列 | IPv4またはIPv6のCIDRブロック。 |
| `addresses[].created_at` | 文字列 | アドレスを追加した時刻。Switchboardがこの値を設定します。 |
| `addresses[].description` | 文字列 | アドレスの説明。 |
| `addresses[].status` | 文字列 | アドレスがインスタンスに適用されているかどうかを示します。Switchboardがこの値を設定します。 |
| `enabled` | ブール値 | インスタンスが許可リストを使用している場合は`true`です。インスタンスがすべての送信元アドレスを許可している場合は`false`です。 |

### IP許可リストを置き換える {#replace-ip-allowlist}

インスタンスのIP許可リストを置き換えます。

```plaintext
PUT /tenant/ip_allowlist
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `addresses` | 配列 | はい | 許可されているアドレスの全リスト。各項目には`address`（必須）と`description`があります。 |
| `enabled` | ブール値 | はい | 許可リストを使用するには`true`にします。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と更新された許可リストが返されます。

リクエスト例: 

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"enabled": true, "addresses": [{"address": "203.0.113.0/24", "description": "Office"}]}' \
  --url "https://console.gitlab-dedicated.com/api/customer/v1/tenant/ip_allowlist"
```

### 連絡先情報を取得する {#retrieve-contact-information}

GitLabがインスタンスに関する連絡に使用する運用メールアドレスを取得します。

```plaintext
GET /tenant/contact_information
```

成功した場合、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `operational_email_addresses` | 文字列の配列 | インスタンスに関する運用通知用のメールアドレス。 |

### 連絡先情報を置き換える {#replace-contact-information}

インスタンスの運用メールアドレスを置き換えます。

```plaintext
PUT /tenant/contact_information
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `operational_email_addresses` | 文字列の配列 | はい | メールアドレスの全リスト。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と更新された連絡先情報が返されます。

GitLabは、内部連絡先および割り当てられたサポートエンジニアを設定します。このAPIでそれらを読み取ったり変更したりすることはできません。

### リソースアクセス設定を取得する {#retrieve-resource-access-settings}

インスタンスのアプリケーションログバケットを読み取ることができるAWSプリンシパルを取得します。

```plaintext
GET /tenant/resource_access
```

成功した場合、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `bucket_read_arns` | 文字列の配列 | アプリケーションログバケットを読み取ることができるAWSプリンシパルARN。 |

### リソースアクセス設定を置き換える {#replace-resource-access-settings}

インスタンスのアプリケーションログバケットを読み取ることができるAWSプリンシパルを置き換えます。

```plaintext
PUT /tenant/resource_access
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `bucket_read_arns` | 文字列の配列 | はい | AWSプリンシパルARNの全リスト。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と更新された設定が返されます。

### すべてのカスタム証明機関を一覧表示する {#list-all-custom-certificate-authorities}

インスタンスが信頼するすべてのカスタム証明機関を一覧表示します。

```plaintext
GET /tenant/custom_certificate_authorities
```

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と配列が返されます。各項目には、次の属性があります:

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `authority` | 文字列 | 発行者。Switchboardは、この値を証明書から取得します。 |
| `certificate` | 文字列 | PEMエンコードされた証明書。 |
| `id` | 整数 | 証明機関のID。 |
| `not_after` | 文字列 | 証明書の有効期間の終了日時。 |
| `not_before` | 文字列 | 証明書の有効期間の開始日時。 |

### カスタム証明機関を置き換える {#replace-custom-certificate-authorities}

インスタンスが信頼するカスタム証明機関を置き換えます。

```plaintext
PUT /tenant/custom_certificate_authorities
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `certificates` | 文字列の配列 | はい | 信頼するPEMエンコードされた証明書の全セット。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と更新されたリストが返されます。

1つの証明書が無効であるか期限切れである場合、Switchboardはリクエストを受け入れません。エラーには証明書のインデックスが表示されます。

### すべてのSAML SSOプロバイダーを一覧表示する {#list-all-saml-sso-providers}

インスタンスのすべてのSAMLシングルサインオン（SSO）プロバイダーを、最も古いものから順に一覧表示します。

```plaintext
GET /tenant/saml_providers
```

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)とプロバイダーの配列が返されます。各プロバイダーには、[プロバイダー属性](#saml-sso-provider-attributes)と`id`があります。

### SAML SSOプロバイダーを取得する {#retrieve-a-saml-sso-provider}

インスタンスのSAML SSOプロバイダーを1つ取得します。

```plaintext
GET /tenant/saml_providers/:id
```

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数 | はい | プロバイダーのID。 |

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)とプロバイダーが返されます。プロバイダーが存在しない場合は`404 Not Found`が返されます。

### SAML SSOプロバイダーを作成する {#create-a-saml-sso-provider}

インスタンスにSAML SSOプロバイダーを作成します。

```plaintext
POST /tenant/saml_providers
```

[プロバイダー属性](#saml-sso-provider-attributes)を送信します。

成功すると、[`201 Created`](../../api/rest/troubleshooting.md#status-codes)と新しいプロバイダーが返されます。

### SAML SSOプロバイダーを置き換える {#replace-a-saml-sso-provider}

インスタンスのSAML SSOプロバイダーを1つ置き換えます。

```plaintext
PUT /tenant/saml_providers/:id
```

プロバイダー全体を送信します。オプションの属性を送信しない場合、Switchboardはその属性をクリアします。たとえば、`admin_groups`を送信しない場合、Switchboardは管理者へのグループのマッピングを削除します。

成功すると、[`200 OK`](../../api/rest/troubleshooting.md#status-codes)と更新されたプロバイダーが返されます。

### SAML SSOプロバイダーを削除する {#delete-a-saml-sso-provider}

インスタンスからSAML SSOプロバイダーを1つ削除します。

```plaintext
DELETE /tenant/saml_providers/:id
```

成功した場合、[`204 No Content`](../../api/rest/troubleshooting.md#status-codes)を返します。

### SAML SSOプロバイダー属性 {#saml-sso-provider-attributes}

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `enabled` | ブール値 | はい | プロバイダーをオンにするには`true`にします。 |
| `idp_cert_fingerprint` | 文字列 | はい | アイデンティティプロバイダー証明書のフィンガープリント。 |
| `idp_sso_target_url` | 文字列 | はい | アイデンティティプロバイダーのSSO URL。 |
| `label` | 文字列 | はい | サインインボタンに表示される名前。 |
| `name_identifier_format` | 文字列 | はい | 名前識別子の形式。 |
| `admin_groups` | 文字列の配列 | いいえ | メンバーが管理者であるグループ。 |
| `attribute_statements` | オブジェクト | いいえ | SAML属性とユーザー属性のマッピング。 |
| `auditor_groups` | 文字列の配列 | いいえ | メンバーが監査担当者であるグループ。 |
| `external_groups` | 文字列の配列 | いいえ | メンバーが外部ユーザーであるグループ。 |
| `force_authn` | ブール値 | いいえ | アイデンティティプロバイダーに再度認証を要求させるには`true`にします。 |
| `groups_attribute` | 文字列 | いいえ | ユーザーのグループを持つSAML属性。 |
| `issuer` | 文字列 | いいえ | 発行者。 |
| `required_groups` | 文字列の配列 | いいえ | サインインするためにユーザーが所属している必要があるグループ。 |
| `security` | オブジェクト | いいえ | SAMLセキュリティ設定。 |
| `upstream_two_factor_authn_contexts` | 文字列の配列 | いいえ | 二要素認証としてカウントされる認証コンテキスト。 |

これらの設定の詳細については、[GitLab Dedicated用SAML SSO](configure_instance/authentication/saml.md)を参照してください。

## 関連トピック {#related-topics}

- [GitLab Dedicatedインスタンスの詳細](tenant_overview.md)
- [GitLab Dedicatedのメンテナンス操作](maintenance.md)
