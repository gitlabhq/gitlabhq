---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIカスタム属性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カスタム属性に対するすべてのAPIコールは、管理者として認証されている必要があります。

カスタム属性は現在、ユーザー、グループ、およびプロジェクトで利用可能であり、このドキュメントでは「リソース」と呼ばれています。

## 属性一覧 {#list-custom-attributes}

リソースのすべてのカスタム属性を取得します。

```plaintext
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | リソースのID |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes"
```

レスポンス例:

```json
[
   {
      "key": "location",
      "value": "Antarctica"
   },
   {
      "key": "role",
      "value": "Developer"
   }
]
```

## 単一のカスタム属性 {#single-custom-attribute}

リソースの単一のカスタム属性を取得します。

```plaintext
GET /users/:id/custom_attributes/:key
GET /groups/:id/custom_attributes/:key
GET /projects/:id/custom_attributes/:key
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | リソースのID |
| `key` | 文字列 | はい | カスタム属性のキー |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

レスポンス例:

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## カスタム属性の設定 {#set-custom-attribute}

リソースにカスタム属性を設定します。属性が既に存在する場合は更新され、それ以外の場合は新しく作成されます。

```plaintext
PUT /users/:id/custom_attributes/:key
PUT /groups/:id/custom_attributes/:key
PUT /projects/:id/custom_attributes/:key
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | リソースのID |
| `key` | 文字列 | はい | カスタム属性のキー |
| `value` | 文字列 | はい | カスタム属性の値 |

```shell
curl --request PUT \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --data "value=Greenland" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

レスポンス例:

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## カスタム属性の削除 {#delete-custom-attribute}

リソースのカスタム属性を削除します。

```plaintext
DELETE /users/:id/custom_attributes/:key
DELETE /groups/:id/custom_attributes/:key
DELETE /projects/:id/custom_attributes/:key
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | リソースのID |
| `key` | 文字列 | はい | カスタム属性のキー |

```shell
curl --request DELETE \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```
