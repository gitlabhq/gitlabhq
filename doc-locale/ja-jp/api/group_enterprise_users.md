---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループエンタープライズユーザーAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

これらのAPIエンドポイントを使用して、エンタープライズユーザーアカウントを操作します。詳細については、[エンタープライズユーザー](../user/enterprise_user/_index.md)を参照してください。

これらのAPIエンドポイントは、トップレベルグループでのみ機能します。ユーザーはグループのメンバーである必要はありません。

前提要件:

- トップレベルグループのオーナーロールを持っている必要があります。

## すべてのエンタープライズユーザーをリストする {#list-all-enterprise-users}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438366)されました。

{{< /history >}}

指定されたトップレベルグループのすべてのエンタープライズユーザーをリストします。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /groups/:id/enterprise_users
```

サポートされている属性は以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `username`       | 文字列         | いいえ       | 指定されたユーザー名のユーザーを返します。 |
| `search`         | 文字列         | いいえ       | 一致する名前、メール、またはユーザー名を持つユーザーを返します。部分的な値を使用すると、結果が増えます。 |
| `active`         | ブール値        | いいえ       | アクティブユーザーのみを返します。 |
| `blocked`        | ブール値        | いいえ       | ブロックされたユーザーのみを返します。 |
| `created_after`  | 日時       | いいえ       | 指定された時刻以降に作成されたユーザーを返します。形式は、: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）です。 |
| `created_before` | 日時       | いいえ       | 指定された時刻よりも前に作成されたユーザーを返します。形式は、: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）です。 |
| `two_factor`     | 文字列         | いいえ       | 2要素認証（2FA）の登録ステータスに基づいてユーザーを返します。使用可能な値：`enabled`、`disabled`。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users"
```

レスポンス例:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

## エンタープライズユーザーの詳細を取得 {#get-details-on-an-enterprise-user}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176328)されました。

{{< /history >}}

指定されたエンタープライズユーザーの詳細を取得します。

```plaintext
GET /groups/:id/enterprise_users/:user_id
```

サポートされている属性は以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数        | はい      | ユーザーアカウントのID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

レスポンス例:

```json
{
  "id": 66,
  "username": "user22",
  "name": "Sidney Jones22",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "user22@example.org",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

## エンタープライズユーザーを修正する {#modify-an-enterprise-user}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199248)されたのはGitLab 18.6です。

{{< /history >}}

指定されたエンタープライズユーザーの属性を更新します。

```plaintext
PATCH /groups/:id/enterprise_users/:user_id
```

サポートされている属性は以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数        | はい      | ユーザーアカウントのID。 |
| `name`           | 文字列         | いいえ       | ユーザーアカウントの名前。 |
| `email`          | 文字列         | いいえ       | ユーザーアカウントのメールアドレス。確認済みの[グループドメイン](../user/enterprise_user/_index.md#manage-group-domains)からのものでなければなりません。 |

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" --data "email=new-email@example.com" --data "name=New name" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

成功した場合、`200 OK`を返します。

成功したレスポンスの例:

```json
{
  "id": 66,
  "username": "user22",
  "name": "New name",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "new-email@example.com",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

その他の発生しうる応答:

- `400 Bad Request`: 検証エラー。
- `403 Forbidden`: 認証済みのユーザーはオーナーではありません。
- `404 Not found`: ユーザーが見つかりません。

## エンタープライズユーザーを削除する {#delete-an-enterprise-user}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199646)されました。

{{</ history >}}

指定されたエンタープライズユーザーを削除します。

```plaintext
DELETE /groups/:id/enterprise_users/:user_id
```

サポートされている属性は以下のとおりです:

| 属性     | 型           | 必須 | 説明                                                                                                                                                                                                                                                                              |
|:--------------|:---------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                                                                                                                                                                          |
| `user_id`     | 整数        | はい      | ユーザーアカウントのID。                                                                                                                                                                                                                                                                      |
| `hard_delete` | ブール値        | いいえ       | `false`の場合、ユーザーを削除し、コントリビューションを[システム全体の「Ghostユーザー」](../user/profile/account/delete_account.md#associated-records)に移動します。`true`の場合、ユーザー、関連するコントリビューション、およびユーザーのみがオーナーになっているグループを削除します。デフォルト値: `false`。  |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

成功した場合、`204 No content`を返します。

その他の発生しうる応答:

- `403 Forbidden`: 認証済みのユーザーはオーナーではありません。
- `404 Not found`: ユーザーが見つかりません。
- `409 Conflict`: グループの唯一のオーナーであるユーザーは削除できません。

## エンタープライズユーザーの2要素認証を無効にする {#disable-two-factor-authentication-for-an-enterprise-user}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177943)されました。

{{< /history >}}

指定されたエンタープライズユーザーの2要素認証（2FA）を無効にします。

```plaintext
PATCH /groups/:id/enterprise_users/:user_id/disable_two_factor
```

サポートされている属性は以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数        | はい      | ユーザーアカウントのID。 |

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id/disable_two_factor"
```

成功した場合、`204 No content`を返します。

その他の発生しうる応答:

- `400 Bad request`: 指定されたユーザーに対して2FAが有効になっていません。
- `403 Forbidden`: 認証済みのユーザーはオーナーではありません。
- `404 Not found`: ユーザーが見つかりません。
