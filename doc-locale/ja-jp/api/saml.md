---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)。

{{< /history >}}

このAPIを使用して、SAML機能とやり取りします。

## GitLab.comエンドポイント {#gitlabcom-endpoints}

### グループのSAML固有識別子を取得します {#get-saml-identities-for-a-group}

```plaintext
GET /groups/:id/saml/identities
```

グループのSAML固有識別子をフェッチします。

サポートされている属性は以下のとおりです:

| 属性         | 型    | 必須 | 説明           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性    | 型   | 説明               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | 文字列 | ユーザーの外部固有識別子 |
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

### 単一のSAML固有識別子を取得します {#get-a-single-saml-identity}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591)されました。

{{< /history >}}

```plaintext
GET /groups/:id/saml/:uid
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列         | はい      | ユーザーの外部固有識別子。 |

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

### SAML固有識別子の`extern_uid`フィールドを更新します {#update-extern_uid-field-for-a-saml-identity}

SAML固有識別子の`extern_uid`フィールドを更新します:

| SAML IDプロバイダ属性 | GitLabフィールド |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

サポートされている属性は以下のとおりです:

| 属性 | 型   | 必須 | 説明               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列 | はい      | ユーザーの外部固有識別子。 |

リクエスト例:

```shell
curl --request PATCH \
  --location \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
  --form "extern_uid=be20d8dcc028677c931e04f387"
```

### 単一のSAML固有識別子を削除します {#delete-a-single-saml-identity}

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
| `uid`     | 文字列  | はい      | ユーザーの外部固有識別子。 |

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

## GitLabセルフマネージドエンドポイント {#gitlab-self-managed-endpoints}

### 単一のSAML固有識別子を取得します {#get-a-single-saml-identity-1}

[単一のSAML固有識別子を取得](users.md#as-an-administrator)するには、Users APIを使用します。

### SAML固有識別子の`extern_uid`フィールドを更新します {#update-extern_uid-field-for-a-saml-identity-1}

[ユーザーの`extern_uid`フィールドを更新](users.md#modify-a-user)するには、Users APIを使用します。

### 単一のSAML固有識別子を削除します {#delete-a-single-saml-identity-1}

[ユーザーの単一の固有識別子を削除](users.md#delete-authentication-identity-from-a-user)するには、Users APIを使用します。

## SAMLグループリンク {#saml-group-links}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/290367) GitLab 15.3.0。
- `access_level`の型がGitLab 15.3.3で`string`から[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607)されました。`integer`
- `member_role_id`型は、`custom_roles_for_saml_group_links`という[フラグ](../administration/feature_flags/_index.md)とともに、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)されました。デフォルトでは無効になっています。
- `member_role_id`のタイプは、GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)になりました。機能フラグ`custom_roles_for_saml_group_links`は削除されました。
- `provider`パラメータはGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/548725)されました。

{{< /history >}}

REST APIを使用して、[SAMLグループリンク](../user/group/saml_sso/group_sync.md#configure-saml-group-links)をリスト、取得、追加、削除します。

### SAMLグループリンクをリストします {#list-saml-group-links}

グループのSAMLグループリンクをリストします。

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
| `[].name`           | 文字列  | SAMLグループの名前。 |
| `[].access_level`   | 整数 | SAMLグループのメンバーの[ロール（`access_level`）](members.md#roles)。この属性は、GitLab 15.3.0からGitLab 15.3.3まで文字列型でした。 |
| `[].member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID（`member_role_id`）](member_roles.md)。 |
| `[].provider`       | 文字列  | このグループリンクを適用するには、一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

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

### SAMLグループリンクを取得します {#get-a-saml-group-link}

グループのSAMLグループリンクを取得します。

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

サポートされている属性は以下のとおりです:

| 属性         | 型           | 必須 | 説明 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列         | はい      | SAMLグループの名前。 |
| `provider`        | 文字列         | いいえ       | 同じ名前で複数のリンクが存在する場合に区別するための一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`で複数のリンクが存在する場合に必須です。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループの名前。 |
| `access_level`   | 整数 | SAMLグループのメンバーの[ロール（`access_level`）](members.md#roles)。この属性は、GitLab 15.3.0からGitLab 15.3.3まで文字列型でした。 |
| `member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID（`member_role_id`）](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクを適用するには、一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

同じ名前でプロバイダーが異なるSAMLグループリンクが複数存在し、`provider`パラメータが指定されていない場合、[`422`](rest/troubleshooting.md#status-codes)を返し、`provider`パラメータは区別するために必要であることを示すエラーメッセージが表示されます。

リクエスト例:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

プロバイダーパラメータを使用したリクエスト例:

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

### SAMLグループリンクを追加します {#add-a-saml-group-link}

グループのSAMLグループリンクを追加します。

```plaintext
POST /groups/:id/saml_group_links
```

サポートされている属性は以下のとおりです:

| 属性         | 型              | 必須 | 説明 |
|:------------------|:------------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列            | はい      | SAMLグループの名前。 |
| `access_level`    | 整数           | はい      | SAMLグループのメンバーの[ロール（`access_level`）](members.md#roles)。 |
| `member_role_id`  | 整数           | いいえ       | SAMLグループのメンバーの[メンバーロールID（`member_role_id`）](member_roles.md)。 |
| `provider`        | 文字列            | いいえ       | このグループリンクを適用するには、一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループの名前。 |
| `access_level`   | 整数 | SAMLグループのメンバーの[ロール（`access_level`）](members.md#roles)。この属性は、GitLab 15.3.0からGitLab 15.3.3まで文字列型でした。 |
| `member_role_id` | 整数 | SAMLグループのメンバーの[メンバーロールID（`member_role_id`）](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクを適用するには、一致する必要がある一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

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

### SAMLグループリンクを削除します {#delete-a-saml-group-link}

グループのSAMLグループリンクを削除します。

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

サポートされている属性は以下のとおりです:

| 属性         | 型           | 必須 | 説明 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列         | はい      | SAMLグループの名前。 |
| `provider`        | 文字列         | いいえ       | 同じ名前で複数のリンクが存在する場合に区別するための一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`で複数のリンクが存在する場合に必須です。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

プロバイダーパラメータを使用したリクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

成功した場合、応答本文なしで[`204`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

同じ名前でプロバイダーが異なるSAMLグループリンクが複数存在し、`provider`パラメータが指定されていない場合、[`422`](rest/troubleshooting.md#status-codes)を返し、`provider`パラメータは区別するために必要であることを示すエラーメッセージが表示されます。
