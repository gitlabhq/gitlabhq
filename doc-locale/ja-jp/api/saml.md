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

- GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)されました。

{{< /history >}}

このAPIを使ってSAML機能を操作します。

## GitLab.comエンドポイント {#gitlabcom-endpoints}

### グループのすべてのSAMLアイデンティティを一覧表示 {#list-all-saml-identities-for-a-group}

```plaintext
GET /groups/:id/saml/identities
```

グループのすべてのSAMLアイデンティティを一覧表示します。

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

### 単一のSAMLアイデンティティを取得する {#retrieve-a-single-saml-identity}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591)されました。

{{< /history >}}

単一のSAMLアイデンティティを取得します。

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

### SAMLアイデンティティの`extern_uid`フィールドを更新 {#update-extern_uid-field-for-a-saml-identity}

SAMLアイデンティティの`extern_uid`フィールドを更新します:

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
| `uid`     | 文字列 | はい      | ユーザーの外部固有識別子。 |

`extern_uid`が更新されると、GitLabは次のようになります:

- SAMLIDを信頼できないものとしてマークします。影響を受けるユーザーは、IDを再リンクするまでSAMLでサインインできません。
- 影響を受けるユーザーにメール通知を送信します。

SAMLIDを再リンクするには、ユーザーはGitLabの認証情報でサインインし、そのグループのSAMLリンクフローを完了する必要があります。

リクエスト例: 

```shell
curl --request PATCH \
  --location \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
  --form "extern_uid=be20d8dcc028677c931e04f387"
```

### 単一のSAMLアイデンティティを削除 {#delete-a-single-saml-identity}

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

## GitLab Self-Managedエンドポイント {#gitlab-self-managed-endpoints}

### 単一のSAMLアイデンティティを取得する {#retrieve-a-single-saml-identity-1}

ユーザーAPIを使用して、[単一のSAMLアイデンティティを取得します](users.md#as-an-administrator)。

### SAMLアイデンティティの`extern_uid`フィールドを更新 {#update-extern_uid-field-for-a-saml-identity-1}

ユーザーAPIを使用して、[ユーザーの`extern_uid`フィールドを更新します](users.md#modify-a-user)。

### 単一のSAMLアイデンティティを削除 {#delete-a-single-saml-identity-1}

ユーザーAPIを使用して、[ユーザーの単一のアイデンティティを削除します](users.md#delete-authentication-identity-from-a-user)。

## SAMLグループリンク {#saml-group-links}

{{< history >}}

- GitLab 15.3.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/290367)。
- GitLab 15.3.3で`access_level`タイプが`string`から`integer`に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607)。
- GitLab 16.7で`member_role_id`タイプが`custom_roles_for_saml_group_links`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)されました。デフォルトでは無効になっています。
- GitLab 16.8で`member_role_id`タイプが[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)。機能フラグ`custom_roles_for_saml_group_links`は削除されました。
- GitLab 18.2で`provider`パラメータが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/548725)。

{{< /history >}}

REST APIを使用して、[SAMLグループリンク](../user/group/saml_sso/group_sync.md#configure-saml-group-links)を一覧表示、取得、追加、削除します。

### すべてのSAMLグループリンクを一覧表示 {#list-all-saml-group-links}

グループのすべてのSAMLグループリンクを一覧表示します。

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
| `[].access_level`   | 整数 | SAMLグループのメンバーに対するデフォルトのアクセスレベル。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。 |
| `[].member_role_id` | 整数 | SAMLグループのメンバーに対する[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `[].provider`       | 文字列  | このグループリンクが適用されるために一致する必要がある、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

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
| `saml_group_name` | 文字列         | はい      | SAMLグループの名前。 |
| `provider`        | 文字列         | いいえ       | 同じ名前のリンクが複数存在する場合に曖昧さを解消するための、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`を持つリンクが複数存在する場合に必要です。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループの名前。 |
| `access_level`   | 整数 | SAMLグループのメンバーに対するデフォルトのアクセスレベル。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。 |
| `member_role_id` | 整数 | SAMLグループのメンバーに対する[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクが適用されるために一致する必要がある、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

同じ名前でプロバイダーが異なる複数のSAMLグループリンクが存在し、`provider`パラメータが指定されていない場合、曖昧さを解消するために`provider`パラメータが必要であることを示すエラーメッセージとともに、[`422`](rest/troubleshooting.md#status-codes)が返されます。

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

### SAMLグループリンクを追加 {#add-a-saml-group-link}

グループのSAMLグループリンクを追加します。

```plaintext
POST /groups/:id/saml_group_links
```

サポートされている属性は以下のとおりです: 

| 属性         | 型              | 必須 | 説明 |
|:------------------|:------------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列            | はい      | SAMLグループの名前。 |
| `access_level`    | 整数           | はい      | SAMLグループのメンバーに対するデフォルトのアクセスレベル。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。 |
| `member_role_id`  | 整数           | いいえ       | SAMLグループのメンバーに対する[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`        | 文字列            | いいえ       | このグループリンクが適用されるために一致する必要がある、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性        | 型    | 説明 |
|:-----------------|:--------|:------------|
| `name`           | 文字列  | SAMLグループの名前。 |
| `access_level`   | 整数 | SAMLグループのメンバーに対するデフォルトのアクセスレベル。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。 |
| `member_role_id` | 整数 | SAMLグループのメンバーに対する[メンバーロールID (`member_role_id`)](member_roles.md)。 |
| `provider`       | 文字列  | このグループリンクが適用されるために一致する必要がある、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。 |

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

### SAMLグループリンクを削除 {#delete-a-saml-group-link}

グループのSAMLグループリンクを削除します。

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

サポートされている属性は以下のとおりです: 

| 属性         | 型           | 必須 | 説明 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `saml_group_name` | 文字列         | はい      | SAMLグループの名前。 |
| `provider`        | 文字列         | いいえ       | 同じ名前のリンクが複数存在する場合に曖昧さを解消するための、一意の[プロバイダー名](../integration/saml.md#configure-saml-support-in-gitlab)。同じ`saml_group_name`を持つリンクが複数存在する場合に必要です。 |

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

成功すると、レスポンスボディなしで[`204`](rest/troubleshooting.md#status-codes)ステータスコードが返されます。

同じ名前でプロバイダーが異なる複数のSAMLグループリンクが存在し、`provider`パラメータが指定されていない場合、曖昧さを解消するために`provider`パラメータが必要であることを示すエラーメッセージとともに、[`422`](rest/troubleshooting.md#status-codes)が返されます。
