---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: LDAPグループリンク
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIを使用して、LDAPグループリンクを管理します。詳細については、LDAPによる[グループメンバーシップ](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)の管理を参照してください。

## LDAPグループリンクを一覧表示 {#list-ldap-group-links}

LDAPグループリンクを一覧表示します。

```plaintext
GET /groups/:id/ldap_group_links
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

レスポンス例: 

```json
[
  {
    "cn": "group1",
    "group_access": 40,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  },
  {
    "cn": "group2",
    "group_access": 10,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  }
]
```

## CNまたはフィルターを使用してLDAPグループリンクを追加 {#add-an-ldap-group-link-with-cn-or-filter}

CNまたはフィルターを使用してLDAPグループリンクを追加します。

```plaintext
POST /groups/:id/ldap_group_links
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `group_access` | 整数   | はい      | LDAPグループのメンバーに対するデフォルトのアクセスレベル。使用可能な値: `0`（アクセスなし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、`50`（オーナー）。 |
| `provider` | 文字列        | はい      | LDAPグループリンクのLDAPプロバイダーID。 |
| `cn`      | 文字列         | はい/いいえ   | LDAPグループのCN。`cn`または`filter`のいずれかを指定しますが、両方は指定しないでください。 |
| `filter`  | 文字列         | はい/いいえ   | グループのLDAPフィルター。`cn`または`filter`のいずれかを指定しますが、両方は指定しないでください。 |
| `member_role_id` | 整数 | いいえ       | [メンバーロール](member_roles.md)のID。Ultimateのみです。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"group_access": 40, "provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

レスポンス例: 

```json
{
  "cn": "group2",
  "group_access": 40,
  "provider": "main",
  "filter": null,
  "member_role_id": null
}
```

## CNまたはフィルターを使用してLDAPグループリンクを削除 {#delete-an-ldap-group-link-with-cn-or-filter}

CNまたはフィルターを使用してLDAPグループリンクを削除します。

```plaintext
DELETE /groups/:id/ldap_group_links
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `provider` | 文字列        | はい      | LDAPグループリンクのLDAPプロバイダーID。 |
| `cn`      | 文字列         | はい/いいえ   | LDAPグループのCN。`cn`または`filter`のいずれかを指定しますが、両方は指定しないでください。 |
| `filter`  | 文字列         | はい/いいえ   | グループのLDAPフィルター。`cn`または`filter`のいずれかを指定しますが、両方は指定しないでください。 |

リクエスト例: 

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

成功した場合、応答は返されません。

## LDAPグループリンクを削除（非推奨） {#delete-an-ldap-group-link-deprecated}

LDAPグループリンクを削除します。非推奨。将来のリリースで削除される予定です。代わりに[CNまたはフィルターを使用してLDAPグループリンクを削除](#delete-an-ldap-group-link-with-cn-or-filter)を使用してください。

CNを使用してLDAPグループリンクを削除:

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cn`      | 文字列         | はい      | LDAPグループのCN |

特定のLDAPプロバイダーのLDAPグループリンクを削除:

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cn`      | 文字列         | はい      | LDAPグループのCN |
| `provider` | 文字列        | はい      | LDAPグループリンクのLDAPプロバイダー |
