---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SCIM 
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98354)。

{{< /history >}}

このを使用して、グループ内のSCIM IDを管理します。

前提要件: 

- [グループ](../user/group/saml_sso/_index.md)を有効にする必要があります。
- [グループのSCIM](../user/group/saml_sso/scim_setup.md)を有効にする必要があります。
- 正しいスコープを持つ[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)または[グループアクセストークン](../user/group/settings/group_access_tokens.md)で認証する必要があります。

このは、SCIMトークンを必要とする[内部グループSCIM](../development/internal_api/_index.md#group-scim-api)および[内部インスタンスSCIM](../development/internal_api/_index.md#instance-scim-api)とは異なります。

- この:
  - [RFC7644プロトコル](https://www.rfc-editor.org/rfc/rfc7644)を実装していません。
  - グループ内のSCIM IDを取得、チェック、更新、削除します。

- 内部グループおよびインスタンスSCIM :
  - SCIMプロバイダーインテグレーションのシステム用です。
  - [RFC7644プロトコル](https://www.rfc-editor.org/rfc/rfc7644)を実装します。
  - グループまたはインスタンス用にSCIMプロビジョニングされたユーザーのリストを取得します。
  - グループまたはインスタンス用にSCIMプロビジョニングされたユーザーを作成、削除、更新します。

## グループのSCIM IDを取得 {#get-scim-identities-for-a-group}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)。

{{< /history >}}

```plaintext
GET /groups/:id/scim/identities
```

サポートされている属性は以下のとおりです:

| 属性         | 型    | 必須 | 説明           |
|:------------------|:--------|:---------|:----------------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性    | 型    | 説明               |
| ------------ | ------- | ------------------------- |
| `extern_uid` | 文字列  | ユーザーの外部 |
| `user_id`    | 整数 | ユーザーの           |
| `active`     | ブール値 | IDのステータス    |

レスポンス例:

```json
[
    {
        "extern_uid": "be20d8dcc028677c931e04f387",
        "user_id": 48,
        "active": true
    }
]
```

リクエスト例:

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/identities" \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

## 単一のSCIM IDを取得 {#get-a-single-scim-identity}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591)されました。

{{< /history >}}

```plaintext
GET /groups/:id/scim/:uid
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 整数 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列  | はい      | ユーザーの外部。 |

リクエスト例:

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

レスポンス例:

```json
{
    "extern_uid": "be20d8dcc028677c931e04f387",
    "user_id": 48,
    "active": true
}
```

## SCIM IDの`extern_uid`フィールドを更新する {#update-extern_uid-field-for-a-scim-identity}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)。

{{< /history >}}

更新できるフィールドは次のとおりです:

| SCIM/IdPフィールド  | フィールド |
| --------------- | ------------ |
| `id/externalId` | `extern_uid` |

```plaintext
PATCH /groups/:groups_id/scim/:uid
```

パラメータ:

| 属性 | 型   | 必須 | 説明               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `uid`     | 文字列 | はい      | ユーザーの外部。 |

リクエスト例:

```shell
curl --location --request PATCH \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --form "extern_uid=yrnZW46BrtBFqM7xDzE7dddd"
```

## 単一のSCIM IDを削除 {#delete-a-single-scim-identity}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)されました。

{{< /history >}}

```plaintext
DELETE /groups/:id/scim/:uid
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 整数 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `uid`     | 文字列  | はい      | ユーザーの外部。 |

リクエスト例:

```shell
curl --location --request DELETE \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/yrnZW46BrtBFqM7xDzE7dddd" \
  --header "PRIVATE-TOKEN: <your_access_token>"
```

レスポンス例:

```json
{
    "message" : "204 No Content"
}
```
