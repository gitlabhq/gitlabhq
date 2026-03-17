---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SAML API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)。

{{< /history >}}

このAPIを使用してSAML機能を操作します。

## GitLab.comエンドポイント {#gitlabcom-endpoints}

### グループのすべてのSAMLIDをリストする {#list-all-saml-identities-for-a-group}

```plaintext
GET /groups/:id/saml/identities
```

グループのすべてのSAMLIDをリストします。

サポートされている属性は以下のとおりです: 

| 属性         | 型    | 必須 | 説明           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | 型   | 説明               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | 文字列 | ユーザーの外部UID |
| `user_id`    | 文字列 | ユーザーのID           |

リクエスト例: 

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/identities"
```

レスポンス例: 

```json
[
    {
        "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
        "user_id": 48
    }
]
```

### 単一のSAMLIDを取得する {#retrieve-a-single-saml-identity}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591)されました。

{{< /history >}}

単一のSAMLIDを取得します。

```plaintext
GET /groups/:id/saml/:uid
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列         | はい      | ユーザーの外部UID。 |

リクエスト例: 

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd"
```

レスポンス例: 

```json
{
    "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
    "user_id": 48
}
```

### SAMLIDの`extern_uid`フィールドを更新する {#update-extern_uid-field-for-a-saml-identity}

SAMLIDの`extern_uid`フィールドを更新します:

| SAML IdP属性 | GitLabフィールド |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

サポートされている属性は以下のとおりです: 

| 属性 | 型   | 必須 | 説明               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列 | はい      | ユーザーの外部UID。 |

リクエスト例: 

```shell
curl --request PATCH \
  --location \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
  --form "extern_uid=be20d8dcc028677c931e04f387"
```

### 単一のSAMLIDを削除する {#delete-a-single-saml-identity}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)されました。

{{< /history >}}

```plaintext
DELETE /groups/:id/saml/:uid
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 整数 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `uid`     | 文字列  | はい      | ユーザーの外部UID。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/be20d8dcc028677c931e04f387"
```

レスポンス例: 

```json
{
    "message" : "204 No Content"
}
```

## GitLab Self-Managedエンドポイント {#gitlab-self-managed-endpoints}

### 単一のSAMLIDを取得する {#retrieve-a-single-saml-identity-1}

Users APIを使用して、[単一のSAMLIDを取得します](users.md#as-an-administrator)。

### SAMLIDの`extern_uid`フィールドを更新する {#update-extern_uid-field-for-a-saml-identity-1}

Users APIを使用して、[ユーザーの`extern_uid`フィールドを更新します](users.md#modify-a-user)。

### 単一のSAMLIDを削除する {#delete-a-single-saml-identity-1}

Users APIを使用して、[ユーザーの単一のIDを削除します](users.md#delete-authentication-identity-from-a-user)。

## SAMLグループリンク {#saml-group-links}

{{< history >}}

- GitLab 15.3.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/290367)。
- GitLab 15.3.3で、`access_level`タイプが`string`から`integer`に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607)。
- GitLab 16.7で、`member_role_id`タイプが`custom_roles_for_saml_group_links`という名前の[フラグとともに](../administration/feature_flags/_index.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)。デフォルトでは無効になっています。
- GitLab 16.8で`member_role_id`タイプが[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)。機能フラグ`custom_roles_for_saml_group_links`は削除されました。
- GitLab 18.2で`provider`パラメータが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/548725)。

{{< /history >}}

REST APIを使用して、[SAMLグループリンク](../user/group/saml_sso/group_sync.md#configure-saml-group-links)をリスト、取得、追加、削除します。

### すべてのSAMLグループリンクをリストする {#list-all-saml-group-links}

グループのすべてのSAMLグループリンクをリストします。

```plaintext
GET /groups/:id/saml_group_links
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|:----------|:---------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|:--------------------|:--------|:------------|
| `[].name`           | 文字列  | SAMLグループ名。 |
| `[].access_level`   | 整数 | SAMLグループのメンバーのデフォルトのアクセスレベル。使用可能な値: `0`（アクセス権なし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、`50`（オーナー）。 |
| `[].member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `[].provider`       | 文字列  | このグループリンクを適用するために一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

レスポンス例: 

```json
[
  {
    "name": "saml-group-1",
    "access_level": 10,
    "member_role_id": 12,
    "provider": null
  },
  {
    "name": "saml-group-2",
    "access_level": 40,
    "member_role_id": 99,
    "provider": "saml_provider_1"
  }
]
```

### SAMLグループリンクを取得する {#retrieve-a-saml-group-link}

グループのSAMLグループリンクを取得します。

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

サポートされている属性は以下のとおりです: 

| 属性         | 型           | 必須 | 説明 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列         | はい      | SAMLグループ名。 |
| `provider`        | 文字列         | いいえ       | 同じ名前の複数のリンクが存在する場合に区別するための、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`を持つ複数のリンクが存在する場合に必須。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループ名。 |
| `access_level`   | 整数 | SAMLグループのメンバーのデフォルトのアクセスレベル。使用可能な値: `0`（アクセス権なし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、`50`（オーナー）。 |
| `member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクを適用するために一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

同じ名前で異なるプロバイダーを持つ複数のSAMLグループリンクが存在し、`provider`パラメータが指定されていない場合、`provider`パラメータが区別に必要であることを示すエラーメッセージとともに[`422`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

プロバイダーパラメータを含むリクエストの例:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

レスポンス例: 

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### SAMLグループリンクを追加する {#add-a-saml-group-link}

グループにSAMLグループリンクを追加します。

```plaintext
POST /groups/:id/saml_group_links
```

サポートされている属性は以下のとおりです: 

| 属性         | 型              | 必須 | 説明 |
|:------------------|:------------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列            | はい      | SAMLグループ名。 |
| `access_level`    | 整数           | はい      | SAMLグループのメンバーのデフォルトのアクセスレベル。使用可能な値: `0`（アクセス権なし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、`50`（オーナー）。 |
| `member_role_id`  | 整数           | いいえ       | SAMLグループのメンバーの[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`        | 文字列            | いいえ       | このグループリンクを適用するために一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループ名。 |
| `access_level`   | 整数 | SAMLグループのメンバーのデフォルトのアクセスレベル。使用可能な値: `0`（アクセス権なし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、`50`（オーナー）。 |
| `member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクを適用するために一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{ "saml_group_name": "<your_saml_group_name`>", "access_level": <chosen_access_level>, "member_role_id": <chosen_member_role_id>, "provider": "<your_provider>" }' --url  "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

レスポンス例: 

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### SAMLグループリンクを削除する {#delete-a-saml-group-link}

グループのSAMLグループリンクを削除します。

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

サポートされている属性は以下のとおりです: 

| 属性         | 型           | 必須 | 説明 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列         | はい      | SAMLグループ名。 |
| `provider`        | 文字列         | いいえ       | 同じ名前の複数のリンクが存在する場合に区別するための、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`を持つ複数のリンクが存在する場合に必須。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

プロバイダーパラメータを含むリクエストの例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

成功した場合、レスポンスボディなしで[`204`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

同じ名前で異なるプロバイダーを持つ複数のSAMLグループリンクが存在し、`provider`パラメータが指定されていない場合、`provider`パラメータが区別に必要であることを示すエラーメッセージとともに[`422`](rest/troubleshooting.md#status-codes)を返します。
