---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスアカウントAPI
description: GitLabサービスアカウントAPIは、インスタンスまたはグループレベルでサービスアカウントを管理し、堅牢なトークンとアカウント管理コントロールを備えています。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[サービスアカウント](../user/profile/service_accounts.md)を操作します。

[ユーザーAPI](users.md)を介してサービスアカウントを操作することもできます。

## インスタンスサービスアカウント {#instance-service-accounts}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンスサービスアカウントは、GitLabインスタンス全体で利用できますが、ヒューマンユーザーと同様に、グループやプロジェクトに追加する必要があります。

インスタンスサービスアカウントのパーソナルアクセストークンを管理するには、[パーソナルアクセストークンAPI](personal_access_tokens.md)を使用します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

### すべてのインスタンスサービスアカウントをリスト表示 {#list-all-instance-service-accounts}

{{< history >}}

- GitLab 17.1で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)すべてのサービスアカウントをリスト表示します。

{{< /history >}}

すべてのインスタンスサービスアカウントをリスト表示します。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /service_accounts
```

サポートされている属性は以下のとおりです:

| 属性  | 型   | 必須 | 説明 |
| ---------- | ------ | -------- | ----------- |
| `order_by` | 文字列 | いいえ       | 結果を並べ替える属性。使用可能な値: `id`または`username`。デフォルト値: `id`。 |
| `sort`     | 文字列 | いいえ       | 結果をソートする方向。使用可能な値: `desc`または`asc`。デフォルト値: `desc`。 |

リクエスト例:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts"
```

レスポンス例:

```json
[
  {
    "id": 114,
    "username": "service_account_33",
    "name": "Service account user"
  },
  {
    "id": 137,
    "username": "service_account_34",
    "name": "john doe"
  }
]
```

### インスタンスサービスアカウントを作成 {#create-an-instance-service-account}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406782) GitLab 16.1
- `username`属性と`name`属性がGitLab 16.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)されました。
- GitLab 17.9で`email`属性が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178689)されました。

{{< /history >}}

インスタンスサービスアカウントを作成します。

```plaintext
POST /service_accounts
POST /service_accounts?email=custom_email@gitlab.example.com
```

サポートされている属性は以下のとおりです:

| 属性  | 型   | 必須 | 説明 |
| ---------- | ------ | -------- | ----------- |
| `name`     | 文字列 | いいえ       | ユーザー名。設定されていない場合は、`Service account user`を使用します。 |
| `username` | 文字列 | いいえ       | ユーザーアカウントのユーザー名。未定義の場合、`service_account_`が前に付いた名前が生成されます。 |
| `email`    | 文字列 | いいえ       | ユーザーアカウントのメール。未定義の場合、応答不要のメールアドレスが生成されます。メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、カスタムメールアドレスには確認が必要です。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts"
```

レスポンス例:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "service_account_6018816a18e515214e0c34c2b33523fc@noreply.gitlab.example.com"
}
```

`email`属性で定義されたメールアドレスが別のユーザーによって既に使用されている場合、`400 Bad request`エラーが返されます。

### インスタンスサービスアカウントを更新 {#update-an-instance-service-account}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309/)されました。

{{< /history >}}

指定されたインスタンスサービスアカウントを更新します。

```plaintext
PATCH /service_accounts/:id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明                                                                                                                                                                                                               |
|:-----------|:---------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数        | はい      | サービスアカウントのID。  |
| `name`     | 文字列         | いいえ       | ユーザー名。  |
| `username` | 文字列         | いいえ       | ユーザーアカウントのユーザー名。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメール。メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、カスタムメールアドレスには確認が必要です。 |

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts/57" --data "name=Updated Service Account email=updated_email@example.com"
```

レスポンス例:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

## グループのサービスアカウント {#group-service-accounts}

グループサービスアカウントは特定のトップレベルグループが所有しており、ヒューマンユーザーと同様にサブグループおよびプロジェクトへのメンバーシップを継承できます。

前提要件: 

- GitLab.comの場合、グループのオーナーロールが必要です。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次の条件を満たす必要があります:
  - インスタンスの管理者である。
  - トップレベルグループでオーナーロールを持ち、[サービスアカウントの作成を許可されている](../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

### すべてのグループサービスアカウントをリスト表示 {#list-all-group-service-accounts}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)されました。

{{< /history >}}

指定されたトップレベルグループ内のすべてのサービスアカウントをリスト表示します。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /groups/:id/service_accounts
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列         | いいえ       | `username`または`id`でユーザーのリストを注文します。デフォルトは`id`です。 |
| `sort`     | 文字列         | いいえ       | `asc`または`desc`でのソートを指定します。デフォルトは`desc`です。 |

リクエスト例:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

レスポンス例:

```json
[

  {
    "id": 57,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_group_346_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_346_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### グループサービスアカウントを作成 {#create-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/407775)されました。
- `username`属性と`name`属性がGitLab 16.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)されました。
- GitLab 17.9で`email`[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181456)されました([フラグ](../administration/feature_flags/_index.md)の名前は`group_service_account_custom_email`)。
- GitLab 17.11で`email`属性が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186476)になりました。機能フラグ`group_service_account_custom_email`は削除されました。

{{< /history >}}

指定されたトップレベルグループにサービスアカウントを作成します。

{{< alert type="note" >}}

このエンドポイントは、トップレベルグループでのみ機能します。

{{< /alert >}}

```plaintext
POST /groups/:id/service_accounts
```

サポートされている属性は以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`     | 文字列         | いいえ       | ユーザーアカウント名。指定されていない場合は、`Service account user`を使用します。 |
| `username` | 文字列         | いいえ       | ユーザーアカウントのユーザー名。指定しない場合、`service_account_group_`が前に付加された名前が生成されます。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメール。指定しない場合、`service_account_group_`が前に付加されたメールが生成されます。グループに一致する[確認済みのドメイン](../user/enterprise_user/_index.md#manage-group-domains)がない限り、またはメール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、カスタムメールアドレスには確認が必要です。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts" --data "email=custom_email@example.com"
```

レスポンス例:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### グループサービスアカウントを更新 {#update-a-group-service-account}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182607/)されました。
- カスタムメールアドレスの追加は、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309)されました。

{{< /history >}}

指定されたトップレベルグループ内のサービスアカウントを更新します。

{{< alert type="note" >}}

このエンドポイントは、トップレベルグループでのみ機能します。

{{< /alert >}}

```plaintext
PATCH /groups/:id/service_accounts/:user_id
```

パラメータ:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`  | 整数        | はい      | サービスアカウントのID。 |
| `name`     | 文字列         | いいえ       | ユーザーの名前。 |
| `username` | 文字列         | いいえ       | ユーザーのユーザー名。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメール。[検証済みのドメイン](../user/enterprise_user/_index.md#manage-group-domains)がグループに一致するか、メール確認設定が[オフになっている](../administration/settings/sign_up_restrictions.md#confirm-user-email)場合を除き、カスタムメールアドレスには確認が必要です。 |

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/57" --data "name=Updated Service Account email=updated_email@example.com"
```

レスポンス例:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### グループサービスアカウントを削除 {#delete-a-group-service-account}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)されました。

{{< /history >}}

指定されたトップレベルグループからサービスアカウントを削除します。

{{< alert type="note" >}}

このエンドポイントは、トップレベルグループでのみ機能します。

{{< /alert >}}

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

パラメータ:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `hard_delete` | ブール値        | いいえ       | trueの場合、通常は[Ghostユーザーに移動](../user/profile/account/delete_account.md#associated-records)されるコントリビュートは、代わりに削除されます。また、このサービスアカウントのみが所有するグループも削除されます。 |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

### グループサービスアカウントのすべてのパーソナルアクセストークンをリスト表示 {#list-all-personal-access-tokens-for-a-group-service-account}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/526924)されました。

{{< /history >}}

トップレベルグループ内のサービスアカウントのすべてのパーソナルアクセストークンをリストします。

```plaintext
GET /groups/:id/service_accounts/:user_id/personal_access_tokens
```

サポートされている属性は以下のとおりです:

| 属性          | 型                | 必須 | 説明 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 整数または文字列      | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`          | 整数             | はい      | サービスアカウントのID。 |
| `created_after`    | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に作成されたトークンを返します。 |
| `created_before`   | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に作成されたトークンを返します。 |
| `expires_after`    | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より後に有効期限が切れるトークンを返します。 |
| `expires_before`   | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より前に有効期限が切れるトークンを返します。 |
| `last_used_after`  | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に最終使用されたトークンを返します。 |
| `last_used_before` | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に最終使用されたトークンを返します。 |
| `revoked`          | ブール値             | いいえ       | `true`の場合、失効したトークンのみを返します。 |
| `search`           | 文字列              | いいえ       | 定義されている場合、指定された値が名前に含まれたトークンを返します。 |
| `sort`             | 文字列              | いいえ       | 定義されている場合、指定された値で結果を並べ替えます。使用できる値は、`created_asc`、`created_desc`、`expires_asc`、`expires_desc`、`last_used_asc`、`last_used_desc`、`name_asc`、`name_desc`です。 |
| `state`            | 文字列              | いいえ       | 定義されている場合、指定された状態のトークンを返します。使用できる値は、`active`と`inactive`です。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

レスポンス例:

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

失敗したレスポンスの例:

- `401: Unauthorized`
- `404 Group Not Found`

### グループのサービスアカウントのパーソナルアクセス・トークンを作成するには: {#create-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406781)されました。

{{< /history >}}

指定されたトップレベルグループ内の既存のサービスアカウントのパーソナルアクセストークンを作成します。

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `name`        | 文字列         | はい      | パーソナルアクセストークンの名前。 |
| `description` | 文字列         | いいえ       | パーソナルアクセストークンの説明。 |
| `scopes`      | 配列          | はい      | 承認されたスコープの配列。使用可能な値のリストについては、[パーソナルアクセストークンスコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を参照してください。 |
| `expires_at`  | 日付           | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。未指定の場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
```

レスポンス例:

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

### グループのサービスアカウントのパーソナルアクセストークンを失効するには: {#revoke-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184287) GitLab 17.11

{{< /history >}}

指定されたトップレベルグループ内の既存のサービスアカウントのパーソナルアクセストークンを失効します。

{{< alert type="note" >}}

このエンドポイントは、トップレベルグループでのみ機能します。

{{< /alert >}}

```plaintext
DELETE /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

パラメータ:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`  | 整数        | はい      | サービスアカウントのID。 |
| `token_id` | 整数        | はい      | トークンのID。 |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6"
```

成功した場合、`204: No Content`を返します。

その他の発生しうる応答:

- 正常に失効しなかった場合は`400: Bad Request`。
- リクエストが承認されていない場合は`401: Unauthorized`。
- リクエストが許可されていない場合は`403: Forbidden`。
- アクセストークンが存在しない場合は`404: Not Found`。

### グループのサービスアカウントのパーソナルアクセストークンをローテーションするには: {#rotate-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406781)されました。

{{< /history >}}

指定されたトップレベルグループ内の既存のサービスアカウントのパーソナルアクセストークンをローテーションします。これにより、1週間有効な新しいトークンが作成され、既存のトークンはすべて失効されます。

{{< alert type="note" >}}

このエンドポイントは、トップレベルグループでのみ機能します。

{{< /alert >}}

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

パラメータ:

| 属性    | 型           | 必須 | 説明 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`    | 整数        | はい      | サービスアカウントのID。 |
| `token_id`   | 整数        | はい      | トークンのID。 |
| `expires_at` | 日付           | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)されました。トークンに有効期限が必要な場合、デフォルトは1週間です。不要な場合、デフォルトは[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)になります。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6/rotate"
```

レスポンス例:

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```
