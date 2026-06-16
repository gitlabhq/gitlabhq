---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: カスタム属性API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザー、グループ、プロジェクトのカスタム属性を管理するために、このAPIを使用します。

前提条件: 

- インスタンスの管理者である必要があります。

## すべてのカスタム属性を一覧表示 {#list-all-custom-attributes}

指定されたリソースのすべてのカスタム属性を一覧表示します。

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

## カスタム属性を取得する {#retrieve-a-custom-attribute}

指定されたリソースのカスタム属性を取得します。

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

## カスタム属性を更新する {#update-a-custom-attribute}

指定されたリソースのカスタム属性を更新または作成します。属性がすでに存在する場合は更新され、そうでない場合は新規作成されます。

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

## カスタム属性を削除する {#delete-custom-attribute}

指定されたリソースのカスタム属性を削除します。

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
