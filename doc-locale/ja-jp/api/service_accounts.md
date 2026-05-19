---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: サービスアカウントAPI
description: GitLabのサービスアカウントAPIは、堅牢なトークンおよびアカウント管理機能により、インスタンスまたはグループレベルでサービスアカウントを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10でFreeティアに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225913)され、`service_accounts_available_on_free_or_unlicensed`という名前の[フラグ](../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- GitLab 18.11でFreeティアにて[一般提供が開始](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227910)されました。機能フラグ`service_accounts_available_on_free_or_unlicensed`は削除されました。

{{< /history >}}

このAPIを使用して、[サービスアカウント](../user/profile/service_accounts.md)とやり取りします。

作成できるサービスアカウントの数は、サブスクリプションと提供形態によって異なります:

- PremiumとUltimateでは、すべての提供形態で無制限のサービスアカウントを作成できます。
- GitLab Freeでは、提供形態によって制限が異なります:
  - GitLab.comでは、各トップレベルグループにつき最大100個のサービスアカウントを作成できます。これには、サブグループまたはプロジェクトで作成されたサービスアカウントが含まれます。
  - GitLab Self-Managedでは、インスタンスごとに最大100個のサービスアカウントを作成できます。これには、プロビジョニングされた方法（インスタンス、グループ、またはプロジェクトレベル）に関係なく、すべてのサービスアカウントが含まれます。

サービスアカウントは、[ユーザーAPI](users.md)を通じて操作することもできます。

## インスタンスサービスアカウント {#instance-service-accounts}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンスサービスアカウントはGitLabインスタンス全体で利用できますが、人間のユーザーと同様にグループやプロジェクトに追加する必要があります。

インスタンスサービスアカウントのパーソナルアクセストークンを管理するには、[パーソナルアクセストークンAPI](personal_access_tokens.md)を使用します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

### すべてのインスタンスサービスアカウントをリストする {#list-all-instance-service-accounts}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)されたすべてのサービスアカウントをリストします。

{{< /history >}}

すべてのインスタンスサービスアカウントをリストします。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /service_accounts
```

サポートされている属性: 

| 属性  | 型   | 必須 | 説明 |
| ---------- | ------ | -------- | ----------- |
| `order_by` | 文字列 | いいえ       | 結果の並び替えに使用する属性。指定可能な値: `id`または`username`。デフォルト値: `id`。 |
| `sort`     | 文字列 | いいえ       | 結果をソートする方向。指定可能な値: `desc`または`asc`。デフォルト値: `desc`。 |

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

### インスタンスサービスアカウントを作成する {#create-an-instance-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406782)されました。
- `username`と`name`の属性がGitLab 16.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)されました。
- `email`属性がGitLab 17.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178689)されました。

{{< /history >}}

インスタンスサービスアカウントを作成します。

```plaintext
POST /service_accounts
POST /service_accounts?email=custom_email@gitlab.example.com
```

サポートされている属性: 

| 属性  | 型   | 必須 | 説明 |
| ---------- | ------ | -------- | ----------- |
| `name`     | 文字列 | いいえ       | ユーザーの名前。設定されていない場合、`Service account user`を使用します。 |
| `username` | 文字列 | いいえ       | ユーザーアカウントのユーザー名。未定義の場合、`service_account_`で始まる名前が生成されます。 |
| `email`    | 文字列 | いいえ       | ユーザーアカウントのメールアドレス。未定義の場合、返信不可のメールアドレスが生成されます。カスタムメールアドレスは、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

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

`email`属性によって定義されたメールアドレスが他のユーザーによって既に使用されている場合、`400 Bad request`エラーが返されます。

### インスタンスサービスアカウントを更新する {#update-an-instance-service-account}

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
| `name`     | 文字列         | いいえ       | ユーザーの名前。  |
| `username` | 文字列         | いいえ       | ユーザーアカウントのユーザー名。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。カスタムメールアドレスは、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts/57" --data "name=Updated Service Account&email=updated_email@example.com"
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

## グループサービスアカウント {#group-service-accounts}

{{< history >}}

- サブグループサービスアカウントは、GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/585513)され、`allow_subgroups_to_create_service_accounts`という名前の[機能フラグ](../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- サブグループサービスアカウントはGitLab 18.11で[一般提供が開始](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/)されました。機能フラグ`allow_subgroups_to_create_service_accounts`は削除されました。

{{< /history >}}

グループサービスアカウントは特定のグループによって所有され、作成されたグループ、または子孫のサブグループやプロジェクトに招待できます。祖先グループには招待できません。

前提条件: 

- GitLab.comでは、グループのオーナーロールが必要です。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次のいずれかが必要です:
  - インスタンスの管理者である。
  - グループでオーナーロールを持ち、[サービスアカウントの作成が許可されている](../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)こと。

### すべてのグループサービスアカウントをリストする {#list-all-group-service-accounts}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)されました。

{{< /history >}}

指定されたグループ内のすべてのサービスアカウントをリストします。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /groups/:id/service_accounts
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列         | いいえ       | ユーザーのリストを`username`または`id`で並べ替えます。デフォルトは`id`です。 |
| `sort`     | 文字列         | いいえ       | `asc`または`desc`によるソートを指定します。デフォルトは`desc`です。 |

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
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### グループサービスアカウントを作成する {#create-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/407775)されました。
- `username`と`name`の属性がGitLab 16.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)されました。
- `email`属性がGitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181456)され、`group_service_account_custom_email`という名前の[機能フラグ](../administration/feature_flags/_index.md)が付けられました。
- `email`属性はGitLab 17.11で[一般提供が開始](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186476)されました。機能フラグ`group_service_account_custom_email`は削除されました。

{{< /history >}}

指定されたグループ内にサービスアカウントを作成します。

```plaintext
POST /groups/:id/service_accounts
```

サポートされている属性: 

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`     | 文字列         | いいえ       | ユーザーアカウント名。指定されていない場合、`Service account user`を使用します。 |
| `username` | 文字列         | いいえ       | ユーザーアカウントのユーザー名。指定されていない場合、`service_account_group_`で始まる名前が生成されます。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。指定されていない場合、`service_account_group_`で始まるメールアドレスが生成されます。カスタムメールアドレスは、グループが一致する[検証済みドメイン](../user/enterprise_user/_index.md#manage-group-domains)を持つか、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

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

### グループサービスアカウントを更新する {#update-a-group-service-account}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182607/)されました。
- カスタムメールアドレスの追加はGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309)されました。
- 複合IDを持つサービスアカウントのユーザー名制限がGitLab 18.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/581050)されました。

{{< /history >}}

指定されたグループ内のサービスアカウントを更新します。

> [!note]
>
> - [複合ID](../user/duo_agent_platform/composite_identity.md)に関連付けられたサービスアカウントのユーザー名は更新できません。

```plaintext
PATCH /groups/:id/service_accounts/:user_id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`  | 整数        | はい      | サービスアカウントのID。 |
| `name`     | 文字列         | いいえ       | ユーザーの名前。 |
| `username` | 文字列         | いいえ       | ユーザーのユーザー名。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。カスタムメールアドレスは、グループが一致する[検証済みドメイン](../user/enterprise_user/_index.md#manage-group-domains)を持つか、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/57" --data "name=Updated Service Account&email=updated_email@example.com"
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

### グループサービスアカウントを削除する {#delete-a-group-service-account}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)されました。

{{< /history >}}

指定されたグループからサービスアカウントを削除します。

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `hard_delete` | ブール値        | いいえ       | trueの場合、通常[ゴーストユーザー](../user/profile/account/delete_account.md#associated-records)にコントリビュートが移動される代わりに、コントリビュートが削除されます。また、このサービスアカウントのみが所有するグループも削除されます。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

### グループサービスアカウントのすべてのパーソナルアクセストークンをリストする {#list-all-personal-access-tokens-for-a-group-service-account}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/526924)されました。

{{< /history >}}

指定されたグループ内のサービスアカウントのすべてのパーソナルアクセストークンをリストします。

```plaintext
GET /groups/:id/service_accounts/:user_id/personal_access_tokens
```

サポートされている属性: 

| 属性          | 型                | 必須 | 説明 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 整数または文字列      | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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

失敗した応答の例:

- `401: Unauthorized`
- `404 Group Not Found`

### グループサービスアカウントのパーソナルアクセストークンを作成する {#create-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406781)されました。

{{< /history >}}

指定されたグループ内の既存のサービスアカウントのパーソナルアクセストークンを作成します。

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `name`        | 文字列         | はい      | パーソナルアクセストークンの名前。 |
| `description` | 文字列         | いいえ       | パーソナルアクセストークンの説明。 |
| `scopes`      | 配列          | はい      | 承認されたスコープの配列。指定可能な値のリストについては、[パーソナルアクセストークンのスコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を参照してください。 |
| `expires_at`  | 日付           | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。指定されていない場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |

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

### グループサービスアカウントのパーソナルアクセストークンを失効する {#revoke-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184287)されました。

{{< /history >}}

指定されたグループ内の既存のサービスアカウントの指定されたパーソナルアクセストークンを失効します。

```plaintext
DELETE /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

パラメータは以下のとおりです:

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

### グループサービスアカウントのパーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/406781)されました。

{{< /history >}}

指定されたグループ内の既存のサービスアカウントの指定されたパーソナルアクセストークンをローテーションします。これにより、既存のトークンを失効し、同じ名前、説明、スコープを持つ新しいトークンが作成されます。

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

パラメータは以下のとおりです:

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

## プロジェクトサービスアカウント {#project-service-accounts}

{{< history >}}

- GitLab 18.9で`allow_projects_to_create_service_accounts`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/585509)されました。デフォルトでは無効になっています。
- プロジェクトサービスアカウントはGitLab 18.11で[一般提供が開始](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/)されました。機能フラグ`allow_projects_to_create_service_accounts`は削除されました。

{{< /history >}}

プロジェクトサービスアカウントは特定のプロジェクトによって所有され、関連付けられたプロジェクトのみで利用できます。

前提条件: 

- GitLab.comでは、プロジェクトのオーナーまたはメンテナーロールが必要です。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次のいずれかが必要です:
  - インスタンスの管理者である。
  - プロジェクトでオーナーまたはメンテナーロールを持っていること。

### すべてのプロジェクトサービスアカウントをリストする {#list-all-project-service-accounts}

指定されたプロジェクト内のすべてのサービスアカウントをリストします。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /projects/:id/service_accounts
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列         | いいえ       | ユーザーのリストを`username`または`id`で並べ替えます。デフォルトは`id`です。 |
| `sort`     | 文字列         | いいえ       | `asc`または`desc`によるソートを指定します。デフォルトは`desc`です。 |

リクエスト例: 

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/345/service_accounts"
```

レスポンス例: 

```json
[

  {
    "id": 57,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### プロジェクトサービスアカウントを作成する {#create-a-project-service-account}

指定されたプロジェクト内にサービスアカウントを作成します。

```plaintext
POST /projects/:id/service_accounts
```

サポートされている属性: 

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`     | 文字列         | いいえ       | ユーザーアカウント名。指定されていない場合、`Service account user`を使用します。 |
| `username` | 文字列         | いいえ       | ユーザーアカウントのユーザー名。指定されていない場合、`service_account_project_`で始まる名前が生成されます。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。指定されていない場合、`service_account_project_`で始まるメールアドレスが生成されます。カスタムメールアドレスは、グループが一致する[検証済みドメイン](../user/enterprise_user/_index.md#manage-group-domains)を持つか、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/345/service_accounts" --data "email=custom_email@example.com"
```

レスポンス例: 

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### プロジェクトサービスアカウントを更新する {#update-a-project-service-account}

指定されたプロジェクト内のサービスアカウントを更新します。

```plaintext
PATCH /projects/:id/service_accounts/:user_id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`  | 整数        | はい      | サービスアカウントのID。 |
| `name`     | 文字列         | いいえ       | ユーザーの名前。 |
| `username` | 文字列         | いいえ       | ユーザーのユーザー名。 |
| `email`    | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。カスタムメールアドレスは、グループが一致する[検証済みドメイン](../user/enterprise_user/_index.md#manage-group-domains)を持つか、メール確認設定が[オフ](../administration/settings/sign_up_restrictions.md#confirm-user-email)になっていない限り、確認が必要です。 |

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/345/service_accounts/57" --data "name=Updated Service Account&email=updated_email@example.com"
```

レスポンス例: 

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### プロジェクトサービスアカウントを削除する {#delete-a-project-service-account}

指定されたプロジェクトからサービスアカウントを削除します。

```plaintext
DELETE /projects/:id/service_accounts/:user_id
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | ターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `hard_delete` | ブール値        | いいえ       | trueの場合、通常[ゴーストユーザー](../user/profile/account/delete_account.md#associated-records)にコントリビュートが移動される代わりに、コントリビュートが削除されます。また、このサービスアカウントのみが所有するグループも削除されます。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/345/service_accounts/181"
```

### プロジェクトサービスアカウントのすべてのパーソナルアクセストークンをリストする {#list-all-personal-access-tokens-for-a-project-service-account}

プロジェクト内のサービスアカウントのすべてのパーソナルアクセストークンをリストします。

```plaintext
GET /projects/:id/service_accounts/:user_id/personal_access_tokens
```

サポートされている属性: 

| 属性          | 型                | 必須 | 説明 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 整数または文字列      | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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
  --url "https://gitlab.example.com/api/v4/projects/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
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

失敗した応答の例:

- `401: Unauthorized`
- `404 Project Not Found`

### プロジェクトサービスアカウントのパーソナルアクセストークンを作成する {#create-a-personal-access-token-for-a-project-service-account}

指定されたプロジェクト内の既存のサービスアカウントのパーソナルアクセストークンを作成します。

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens
```

パラメータは以下のとおりです:

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`     | 整数        | はい      | サービスアカウントのID。 |
| `name`        | 文字列         | はい      | パーソナルアクセストークンの名前。 |
| `description` | 文字列         | いいえ       | パーソナルアクセストークンの説明。 |
| `scopes`      | 配列          | はい      | 承認されたスコープの配列。指定可能な値のリストについては、[パーソナルアクセストークンのスコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を参照してください。 |
| `expires_at`  | 日付           | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。指定されていない場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
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

### プロジェクトサービスアカウントのパーソナルアクセストークンを失効する {#revoke-a-personal-access-token-for-a-project-service-account}

指定されたプロジェクト内の既存のサービスアカウントのパーソナルアクセストークンを失効します。

```plaintext
DELETE /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | ターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`  | 整数        | はい      | サービスアカウントのID。 |
| `token_id` | 整数        | はい      | トークンのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6"
```

成功した場合、`204: No Content`を返します。

その他の発生しうる応答:

- 正常に失効しなかった場合は`400: Bad Request`。
- リクエストが承認されていない場合は`401: Unauthorized`。
- リクエストが許可されていない場合は`403: Forbidden`。
- アクセストークンが存在しない場合は`404: Not Found`。

### プロジェクトサービスアカウントのパーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token-for-a-project-service-account}

指定されたプロジェクト内の既存のサービスアカウントのパーソナルアクセストークンをローテーションします。これにより、1週間有効な新しいトークンが作成され、既存のトークンはすべて失効します。

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

パラメータは以下のとおりです:

| 属性    | 型           | 必須 | 説明 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 整数または文字列 | はい      | ターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`    | 整数        | はい      | サービスアカウントのID。 |
| `token_id`   | 整数        | はい      | トークンのID。 |
| `expires_at` | 日付           | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)されました。トークンに有効期限が必要な場合、デフォルトは1週間です。不要な場合、デフォルトは[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)になります。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6/rotate"
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
